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

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context)!
        self.init(entity: entity, insertInto: context)
    }
    
    static func resultsController(context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchedResultsController<Counter> {
        let request:NSFetchRequest<Counter> = fetchRequest()
        request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
}
