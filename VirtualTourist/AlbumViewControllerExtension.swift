//
//  AlbumViewControllerExtension.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/23/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension AlbumViewController {
    func getPhoto() {
        guard self.pin != nil, let pin = self.pin else {
            print("Nil here!")
            return
        }
        let lastPage = AlbumViewController.lastPage
        // Get ImageInformation
        FlickrAPI.sharedInstance().downloadInfoPhotoAtPin(pin, pin.latitude, pin.longitude, 2, lastPage,completionHandler: { (imageInformations, numPages, error) in
            guard error == nil else {
                print("error on Error")
                return
            }
            guard numPages != nil else {
                print("error on Numpages")
                return
            }
            guard self.pin != nil else {
                print("error is here!!!")
                return
            }
            guard imageInformations != nil else {
                return
            }
            guard let imageInformations = imageInformations else {
                return
            }
            print(imageInformations)
            DispatchQueue.main.async {
                //self.collectionView.reloadData()
                self.newCollectionBtnUsability()
            }
        })
    }
    
    func immediateDownloadRandomPhoto() {
        guard let pin = self.pin else {
            print("Nil here!")
            return
        }
        // Fetch Photo from Photo.pins relationship predicate from keyPath and execute batchDeleteRequest
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Photo.pins), pin)
        
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        var removingPhotos = [Photo]()
        do {
            try removingPhotos.append(contentsOf: DatabaseController.persistentContainer.viewContext.fetch(fetchRequest))
            for photo in removingPhotos {
                DatabaseController.persistentContainer.viewContext.delete(photo)
                do {
                    try DatabaseController.persistentContainer.viewContext.save()
                    try DatabaseController.persistentContainer.viewContext.updatedObjects
                } catch {
                    print("error while trying to batch delete Photos")
                }
            }
        } catch {
            
        }
        //let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        var randomPage = FlickrAPI.shared.randomPageNumber(totalPageCount: AlbumViewController.numberOfPages)
        var numberOfPagesRandom: Int {
            get {
                if randomPage == 0 {
                    return 1
                }
                return randomPage
            }
        }
        let randomPageNumber = numberOfPagesRandom
        AlbumViewController.lastPage = randomPageNumber
        print(randomPageNumber)
        let lastPage = AlbumViewController.lastPage
        // Get ImageInformation
        FlickrAPI.sharedInstance().downloadInfoPhotoAtPin(pin, pin.latitude, pin.longitude, 2, randomPageNumber,completionHandler: { (imageInformations, numPages, error) in
            guard error == nil else {
                print("error on Error")
                return
            }
            guard numPages != nil else {
                print("error on Numpages")
                return
            }
            guard pin != nil else {
                print("error is here!!!")
                return
            }
            guard imageInformations != nil else {
                return
            }
            guard let imageInformations = imageInformations else {
                return
            }
            
            for (_, value) in imageInformations{
                let request: NSURLRequest = NSURLRequest(url: value)
                let session = URLSession.shared
                let task = session.dataTask(with: request as URLRequest) {
                    (data,response,error) -> Void in
                    if ( error == nil && data != nil ) {
                        guard response != nil else {
                            return
                        }
                        guard data != nil else {
                            return
                        }
                        let photo = Photo(context: self.context)
                        DatabaseController.persistentContainer.viewContext.performAndWait {
                            
                            guard value != nil else {
                                return
                            }
                            photo.photoData = data as NSData?
                            photo.photoUrl = String(describing: value)
                            photo.pins = pin
                            do {
                                try self.context.save()
                            } catch {
                                print("failed to save")
                            }
                        }
                    }
                }
                task.resume()
            }
        })
    }
    
    func newCollectionBtnUsability() {
        if AlbumViewController.imageInfoDicts.count == 0 {
            // New Collection btn is not interactive
            self.noImagesLabel.isHidden = false
            self.newCollectionToolbar.isUserInteractionEnabled = false
            self.newCollectionToolbar.tintColor = UIColor.lightGray
            return
        }
        // New Collection btn is interactive
        self.noImagesLabel.isHidden = true
        self.newCollectionToolbar.isUserInteractionEnabled = true
        self.newCollectionToolbar.tintColor = UIColor.blue
    }
}

extension AlbumViewController{
    func initializeFetchedResultsController() {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(Photo.pins), pin)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Photo.photoUrl), ascending: true)]
        //Fetch Pin & assign predicates
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest as! NSFetchRequest<Photo>, managedObjectContext: DatabaseController.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController!.delegate = self
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            print("Error initializing FetchedResultController")
        }
    }
}

