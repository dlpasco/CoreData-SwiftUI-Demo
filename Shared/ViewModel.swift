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

final class ViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private var counterController: NSFetchedResultsController<Counter>
    
    var initialized = false
    var container:NSPersistentContainer? = nil
    var cancellables = [AnyCancellable]()
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
        
        // IMPORTANT: We need to set this to true so that our viewContext picks up changes saved to the container on background threads
        self.context.automaticallyMergesChangesFromParent = true
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
        container!.performBackgroundTask { (moc) in
            do {
                // This should be safe on any thread if we don't access the object attributes
                let lastCount = self.counters.count
                let counter = Counter(context: moc)
                
                counter.name = "Counter #\(lastCount + 1)"
                counter.count = 0
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
        
        container!.performBackgroundTask { (moc) in
            do {
                let fetchRequest = NSFetchRequest<Counter>(entityName: "Counter")
                var counterList: [Counter] = []
                counterList = try self.context.fetch(fetchRequest)
                print("found \(counterList.count) counters")
                for counter in counterList {
                    counter.count += 1
                }
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
                self.container!.viewContext.saveIfNeeded()
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
