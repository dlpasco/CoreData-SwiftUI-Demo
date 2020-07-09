
This project demostrates three different ways of updating data in a background thread in a swiftUI project.

Thanks to Tim Ritchey for some suggesting the addition of 

    self.context.automaticallyMergesChangesFromParent = true

to the ViewModel init() function. This is required to get changes to the background moc to show up on the viewContext.

Thanks to Toomas Vahter (@laevandus) for his [CoreDataCombineSwiftUI](http://github.com/laevandus/CoreDataCombineSwiftUI) demo, which was instrumental in putting this together 
