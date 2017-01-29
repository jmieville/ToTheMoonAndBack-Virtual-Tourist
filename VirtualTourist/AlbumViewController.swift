//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/3/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let reuseIdentifier = "photoCell"
var numberOfImages: Int = 0

class AlbumViewController: VirtualTouristViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    //Outlets
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var miniMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    @IBOutlet weak var newCollectionToolbar: UIToolbar!
    //Action
    @IBAction func doBack(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    @IBAction func doNewCollection(_ sender: Any) {
        if newCollection.title == "Load New Collection" {
            DispatchQueue.main.async {
                    AlbumViewController.imageInfoDicts.removeAll()
            }
            //getRandomPhoto()
            immediateDownloadRandomPhoto()
        }
        if newCollection.title == "Delete Selected Images" {
            guard selectedIndexPaths.count > 0 else {
                return
            }
            guard let selectedItemsToBeDeleted: [IndexPath] = self.collectionView.indexPathsForSelectedItems else {
                return
            }
            afterDeletion = true
            var removingPhotos = [Photo]()
            //numberOfImages -= selectedItemsToBeDeleted.count
            //self.collectionView.deleteItems(at: selectedItemsToBeDeleted)
            //deletedIndexPaths.append(contentsOf: selectedItemsToBeDeleted)
            
            for indexPath in selectedItemsToBeDeleted {
                
                removingPhotos.append(self.fetchedResultsController.object(at: indexPath))
            }
            self.collectionView.performBatchUpdates({ 
                for photo in removingPhotos {
                    let dispatchWorkItem = DispatchWorkItem(block: { 
                        self.context.delete(photo)
                        do {
                            try self.context.save()
                            try self.context.updatedObjects
                            //self.collectionView.reloadSections()
                        } catch {
                        }
                        print("saved after deletion")
                        self.deleteSelectedCells(canDelete: false)
                        removingPhotos.removeAll()
                    })
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 200), execute: dispatchWorkItem)
                }
            }, completion: nil)
        }
    }
    
    //Variables/Constants

    static var imageInfoDicts = [String:URL]()
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    class func sharedImageInfoDict() -> [String:URL] {
        return imageInfoDicts
    }
    static var numberOfPages = Int()
    class func sharedNumberOfPages() -> Int {
        return numberOfPages
    }
    static var lastPage = 1
    
    var afterDeletion = false
    var fetchRequest: NSFetchRequest<Photo>!
    var pins: [Pin] = []
    var pin : Pin!
    let context = DatabaseController.getContext()
    
    // set pin annotation & coordinate
    var annotation: MKAnnotation? {
        didSet {
            if let annotation = annotation {
                let contextShared = DatabaseController.shared
                // get pin.latitude & pin.longitude
                pin = contextShared.getPin(forLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude)
            }
        }
    }
    
    // Check & Change New Collection images when images are selected 
    var selectedIndexPaths = [IndexPath]() {
        didSet {
            if selectedIndexPaths.count > 0 {
                deleteSelectedCells(canDelete: true)
            } else {
                deleteSelectedCells(canDelete: false)
            }
        }
    }
    
    func deleteSelectedCells(canDelete: Bool) {
        if canDelete {
            newCollection.title = "Delete Selected Images"
            newCollection.tintColor = UIColor.red
            
        } else {
            newCollection.title = "Load New Collection"
            newCollection.tintColor = UIColor.blue
            afterDeletion = false
        }
    }
    
    override func viewDidLoad() {
        afterDeletion = false
        super.viewDidLoad()
        //fetchedResultsController.delegate = self
        setUpCollectionView()
        guard miniMap != nil else {
            return
        }
        initializeFetchedResultsController()
        setUpMiniMap()
    }
    // CollectionView dataSource & delegate
    func setUpCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
    }
    // Set up miniMap
    func setUpMiniMap() {
        miniMap.isUserInteractionEnabled = false
        miniMap.delegate = self
        miniMap.addAnnotation(annotation!)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        miniMap.setRegion(region, animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            AlbumViewController.imageInfoDicts.removeAll()
        }
        getPhoto()
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
    
    //Private methods
    static var valueList:[URL] {
        get{
            return [URL](AlbumViewController.imageInfoDicts.values)
        }
    }
    static var keyList:[String] {
        get {
            return [String](AlbumViewController.imageInfoDicts.keys)
        }
    }

    // MARK: - UICollectionViewDataSource protocol
    // tell the collection view how many cells to make    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        
        return 0
    }
    
    // make a cell for each cell index path
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }
        //cell.imageCell = nil
        //cell.imageCell.image = nil
        cell.activityIcn.startAnimating()
        

        let fetchedPhotos = fetchedResultsController.object(at: indexPath)
        cell.imageCell.image = UIImage(data: fetchedPhotos.photoData as! Data)

        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    // MARK: - UICollectionViewDelegate protocol
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        selectedIndexPaths.append(indexPath)
        }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let deSelectedCell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        if let index = selectedIndexPaths.index(of: indexPath){
            selectedIndexPaths.remove(at: index)
        }
    }
    
    // Implementation of 4 Controllers to detect changes and update accordingly to the Album CollectionViews
    //
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        collectionView.performBatchUpdates({
            switch type {
            case .insert:
                self.collectionView.insertSections(IndexSet(integer: sectionIndex))
            case .delete:
                self.collectionView.deleteSections(IndexSet(integer: sectionIndex))
            case .move:
                break
            case .update:
                break
            }
        }, completion: nil)
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertedIndexPaths.append(newIndexPath)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                deletedIndexPaths.append(indexPath)
            }
            break
        case .update:
            if let indexPath = indexPath {
                updatedIndexPaths.append(indexPath)
            }
            break
        case .move:
            break
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
}


