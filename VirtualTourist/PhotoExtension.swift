//
//  PhotoExtension.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/15/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Photo {
    convenience init(photoData: Data?, photoUrl: String, intoContext context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) else {
            fatalError("Couldn't find entity with name Photo")
        }
        self.init(entity: entity, insertInto: context)
        if let photoData = photoData {
            self.photoData = photoData as NSData
        } else {
            self.photoData = nil
        }
        self.photoUrl = photoUrl
        //self.pins = atPins
    }
    
    
    var image: UIImage? {
        if photoData != nil {
            return UIImage(data: self.photoData as! Data)
        }
        return nil
    }
}
