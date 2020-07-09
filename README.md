
This project demostrates three different ways of updating data in a background thread in a swiftUI project.

Thanks to Tim Ritchey for some suggesting the addition of 

    self.context.automaticallyMergesChangesFromParent = true

to the ViewModel init() function. This is required to get changes to the background moc to show up on the viewContext.

I drew on at least a few sample projects building up to this and will try to credit them as I dig them back up again. 
