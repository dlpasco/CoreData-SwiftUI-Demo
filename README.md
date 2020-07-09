
This project demostrates three different ways of updating data in a background thread in a swiftUI project.

You can change the method used by setting line 22 of ViewModel.swift:

let persistanceOption:PersistanceOption = .method3

## Method 1
Method 1 uses:

    container.performBackgroundTask { (moc)
        // Do stuff
        moc.save()
    }

## Method 2
Method 2 uses the same API, but also tries to force a save of the viewContext on the main thread afterwards.

    container.performBackgroundTask { (moc)
        // Do stuff
        moc.save()
        container.viewContext.performAndWait {
             do {
                try container.viewContext.save()
             } catch {
             }
         }
    }

## Method 3
Method 3 uses:

    let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    moc.parent = container!.viewContext
    moc.perform {
        // Do stuff
        moc.save
    }

# Results
Only method 3 will actually save and display a new managed object 
All three versions will display changes in objects that have already been created and saved.

