//
//  File.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/7/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//
import CoreLocation
import CoreData

extension Pin {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
    static func getPhotoFromPin(photoUrl: String) -> Photo? {
        //let predicate = NSPredicate(format: "pin == %@ AND photoPath == %@", argumentArray: [self, photoPath])
        let predicate = NSPredicate(format: "photoUrl == %@", photoUrl)
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        let context = DatabaseController.persistentContainer.viewContext
        do {
            let photos = try context.fetch(fetchRequest)
            if photos.count > 0 {
                return photos[0]
            } else { return nil }
        } catch { return nil }
    }
    
    func getAllPhotos() -> [Photo]? {

        let predicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        
        // Try to fetch the photos and return them if there are photos
        do {
            let photos = try DatabaseController.persistentContainer.viewContext.fetch(fetchRequest)
            if photos.count > 0 {
                return photos
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
}
