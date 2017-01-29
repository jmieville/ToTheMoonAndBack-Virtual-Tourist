//
//  UIImageViewExtension.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/23/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import UIKit
import CoreData

// Download image & cache downloaded image for reuse
let imageCache = NSCache<NSString, UIImage>()
var urlImageString: String?
let context = DatabaseController.getContext()


extension UIImageView {
    func downloadImage(urlString: String, pin: Pin) {
        urlImageString = urlString
        // taking the URL , then request image data, then assigne UIImage(data: responseData)
        image = nil
        // check if url already has image in coredata, if yes, take it
        let predicate = NSPredicate(format: "photoUrl == %@", urlString)
        
        //Fetch Pin & assign predicates
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        do {
            let results = try DatabaseController.persistentContainer.viewContext.fetch(fetchRequest)
            if results.count > 0 {
                self.image = UIImage(data: results.first?.photoData as! Data)
                print("fetched success")
                return
            }
        } catch {
            print("error fetching Photo from URL")
        }
        guard let imgURL: NSURL = NSURL(string: urlString) else {
            return
        }
        let request: NSURLRequest = NSURLRequest(url: imgURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (data,response,error) -> Void in
            if ( error == nil && data != nil ) {
                guard data != nil else {
                    return
                }
                let contextDL = DatabaseController.getContext()
                let photo = Photo(context: contextDL)
                
                func display_image() {
                    // get image from coredata here
                    photo.photoData = data as NSData?
                    photo.photoUrl = String(describing: imgURL)
                    photo.pins = pin
                    do {
                        try contextDL.save()
                    } catch {
                        print("failed to save")
                    }
                    self.image = UIImage(data: photo.photoData as! Data)
                }
                DispatchQueue.main.sync {
                    display_image()
                    print("Displaying new image from Coredata")
                }
            }
        }
        task.resume()
        // end of loading img
    }
}

