//
//  ViewModel.swift
//  Core Data Super Ultra Fun Fest
//
//  Created by Daniel Pasco on 7/7/20.
//

import Foundation
import Combine
import CoreData
import SwiftUI

enum PersistanceOption {
    case method1, method2, method3
}
final class ViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private var counterController: NSFetchedResultsController<Counter>
    
    var initialized = false
    var container:NSPersistentContainer? = nil
    var cancellables = [AnyCancellable]()
    let persistanceOption:PersistanceOption = .method3
    public var context: NSManagedObjectContext
    
    // MARK: - Initializer
    override init() {
        container = NSPersistentContainer(name: "Model")
        if container != nil  {
            container!.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            
            // This allows us to do upserts on our final, main thread save.
            container!.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }

        let sortDescriptors = [NSSortDescriptor(keyPath: \Counter.name, ascending: true)]
        counterController = Counter.resultsController(context: container!.viewContext, sortDescriptors: sortDescriptors)
        
        self.context = container!.viewContext
        super.init()

        observeChangeNotification()
        counterController.delegate = self
        try? counterController.performFetch()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
    
    var counters: [Counter] {
        return counterController.fetchedObjects ?? []
    }
    
    public func addCounter() {
        if(container == nil) {
            print("nil container, can't create object")
            return
        }
        
        switch self.persistanceOption {
            case .method1:
                persistUsingMethod1()
            case .method2:
                persistUsingMethod2()
            case .method3:
                persistUsingMethod3()
        }
    }
    
    func addACounter(_ moc:NSManagedObjectContext) {
        // This should be safe on any thread if we don't access the object attributes
        let lastCount = self.counters.count
        let counter = Counter(context: moc)
        
        counter.name = "Counter #\(lastCount + 1)"
        counter.count = 0
    }
    
    func persistUsingMethod1() {
        
        container!.performBackgroundTask { (moc) in
            do {
                self.addACounter(moc)
                try moc.save()
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }
    
    func persistUsingMethod2() {
        container!.performBackgroundTask { (moc) in
            do {
                self.addACounter(moc)
                try moc.save()
                self.container!.viewContext.performAndWait {
                     do {
                        try self.container!.viewContext.save()
                     } catch {
                         print("Could not synchonize data. \(error), \(error.localizedDescription)")
                     }
                 }
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }

    func persistUsingMethod3() {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = container!.viewContext
        moc.perform {
            do {
                self.addACounter(moc)
                try moc.save()
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }

    public func incrementCounts() {
        if(container == nil) {
            print("nil container, can't create object")
            return
        }
        
        switch self.persistanceOption {
            case .method1:
                incrementUsingMethod1()
            case .method2:
                incrementUsingMethod2()
            case .method3:
                incrementUsingMethod3()
        }

    }

    func incrementThemCounters() {
        do {
            let fetchRequest = NSFetchRequest<Counter>(entityName: "Counter")
            var counterList: [Counter] = []
            counterList = try self.context.fetch(fetchRequest)
            print("found \(counterList.count) counters")
            for counter in counterList {
                counter.count += 1
            }
        }
        catch {
            print("Error fetching counter list. \(error), \(error.localizedDescription)")
        }
    }
    
    func incrementUsingMethod1() {
        container!.performBackgroundTask { (moc) in
            do {
                self.incrementThemCounters()
                try moc.save()
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }

    
    func incrementUsingMethod2() {
        container!.performBackgroundTask { (moc) in
            do {
                self.incrementThemCounters()
                try moc.save()
                self.container!.viewContext.performAndWait {
                     do {
                        try self.container!.viewContext.save()
                     } catch {
                         print("Could not synchonize data. \(error), \(error.localizedDescription)")
                     }
                 }
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }

    
    func incrementUsingMethod3() {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = container!.viewContext
        moc.perform {
            self.incrementThemCounters()
            do {
                try moc.save()
            }
            catch {
                print("Error creating new counter. \(error), \(error.localizedDescription)")
            }
        }
    }

    // Observing Change Notifications
    private func observeChangeNotification() {
        let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: container!.viewContext)
            .compactMap({ ManagedObjectContextChanges<Counter>(notification: $0) }).sink { (changes) in
        }
        cancellables.append(cancellable)
    }
}

struct ManagedObjectContextChanges<T: NSManagedObject> {
    let inserted: Set<T>
    let deleted: Set<T>
    let updated: Set<T>
    
    init?(notification: Notification) {
        let unpack: (String) -> Set<T> = { key in
            let managedObjects = (notification.userInfo?[key] as? Set<NSManagedObject>) ?? []
            return Set(managedObjects.compactMap({ $0 as? T }))
        }
        deleted = unpack(NSDeletedObjectsKey)
        inserted = unpack(NSInsertedObjectsKey)
        updated = unpack(NSUpdatedObjectsKey).union(unpack(NSRefreshedObjectsKey))
        if deleted.isEmpty, inserted.isEmpty, updated.isEmpty {
            return nil
        }
    }
}

extension NSManagedObjectContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        }
        catch let nsError as NSError {
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
