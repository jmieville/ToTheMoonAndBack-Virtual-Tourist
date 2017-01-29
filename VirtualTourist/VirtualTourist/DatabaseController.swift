//
//  DatabaseController.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/7/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import CoreData

class DatabaseController {
    // MARK: - Core Data stack
    static let shared = DatabaseController()
    private init() {
        // cant be called directly
    }
    
    class func getContext() -> NSManagedObjectContext {
        return DatabaseController.persistentContainer.viewContext
    }
    
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "VirtualTourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    class func saveContext () {
        let context = DatabaseController.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func getPin(forLatitude latitude: Double, andLongitude longitude: Double) -> Pin? {
        //Predicates
        let predicates = [
            NSPredicate(format: "latitude == %@", argumentArray: [latitude]),
            NSPredicate(format: "longitude == %@", argumentArray: [longitude])
        ]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        //Fetch Pin & assign predicates
        
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.predicate = compoundPredicate
        
        //Fetch pin
        let context = DatabaseController.persistentContainer.viewContext
        let pin: Pin?
        do {
            // Make a fetch request and get the pin at index 0 if there is at least one pin at the specified coordinate
            let pins = try context.fetch(fetchRequest)
            if pins.count > 0 {
                pin = pins[0]
            } else {
                pin = nil
            }
        } catch {
            pin = nil
        }
        return pin
    }
    
    func deletePin(latitude: Double, longitude: Double) {
        let predicates = [
            NSPredicate(format: "latitude == %@", argumentArray: [latitude]),
            NSPredicate(format: "longitude == %@", argumentArray: [longitude])
        ]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.predicate = compoundPredicate
        let context = DatabaseController.persistentContainer.viewContext
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(batchDeleteRequest)
        } catch {
            print("couldn't delete Pin")
        }
    }
}
