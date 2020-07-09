//
//  Counter.swift
//  Core Data Super Ultra Fun Fest
//
//  Created by Daniel Pasco on 7/7/20.
//

import Foundation
import CoreData

extension Counter {
    static let entityName = "Counter"

    @nonobjc public class func makeRequest() -> NSFetchRequest<Counter> {
        let fetchRequest = NSFetchRequest<Counter>(entityName: entityName)
        // Predicate example
        // let predicate = NSPredicate(format: "type=2")
        // fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context)!
        self.init(entity: entity, insertInto: context)
    }
    
    static func resultsController(context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchedResultsController<Counter> {
        let request = makeRequest()
        request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
}
