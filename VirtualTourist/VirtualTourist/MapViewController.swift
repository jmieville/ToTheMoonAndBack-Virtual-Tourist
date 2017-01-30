//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/2/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var isDeletingLabel: UILabel!
    
    //Actions
    @IBAction func doEdit(_ sender: Any) {
        isDeleting = !isDeleting
        switch isDeleting {
        case true:
            editButton.title = "Done"
        case false:
            editButton.title = "Edit"
        }
        print(isDeleting)
        isDeletingLabel.isHidden = !isDeleting
    }
    
    //Variables/Constants
    var annotation: MKPointAnnotation = MKPointAnnotation()
    let context = DatabaseController.getContext()
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    var pins: [Pin] = []
    let reuseId = "pin"
    var isDeleting = false
    
    //Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addLongPressGestureRecognizer()
        // Fetch pin annotation data to show to the map
        getData()
    }
    
    //Private methods
    //Add long press capability
    func addLongPressGestureRecognizer() {
        let uiLongPressGR = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(sender:)))
        uiLongPressGR.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(uiLongPressGR)
    }
    
    //Let drop pin on map
    func dropPin(sender: UILongPressGestureRecognizer) {
        if isDeleting {
            return
        }
        print("Longpress worked!")
        switch sender.state {
        case .began:
            // Coordinate to touched location
            annotation = MKPointAnnotation()
            setCoordinate(forPointAnnotation: annotation, fromLongPressGestureRecognizer: sender)
            mapView.addAnnotation(annotation)
        case .changed:
            mapView.removeAnnotation(annotation)
            annotation = MKPointAnnotation()
            setCoordinate(forPointAnnotation: annotation, fromLongPressGestureRecognizer: sender)
            mapView.addAnnotation(annotation)
        case .ended:
            let pin = Pin(context: context)
            // Save pin location into coredata
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            // Save data to coredata:
            do {
                try DatabaseController.saveContext()
                print("Pin Saved!")
            } catch {
                print(error.localizedDescription)
            }
            // immediately download images
            immediateDownload(pin: pin)
        default:
            break
        }
    }
    // Set coordinate of touched location
    func setCoordinate(forPointAnnotation annotation: MKPointAnnotation, fromLongPressGestureRecognizer longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: mapView)
        let tappedCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        annotation.coordinate = tappedCoordinate
    }
    //Show pin on map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    // Fetch pin annotation data to show to the map
    func getData() {
        do {
            let pins = try context.fetch(fetchRequest)
            for pin in pins{
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
            }
            print(mapView.annotations.count)
        } catch {
            print(error.localizedDescription)
        }
    }
    //Click on pin to show AlbumScene
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        if isDeleting {
            mapView.removeAnnotation(annotation)
            do {
                DatabaseController.shared.deletePin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            } catch {
                print("couldn't delete and save")
            }
        } else {
            let showMap = storyboard?.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
            showMap.annotation = annotation
            mapView.deselectAnnotation(annotation, animated: true)
            navigationController?.present(showMap, animated: true, completion: nil)
        }
        
    }
    //Retrieve from core data
    func getPin(callback: @escaping (Result) -> Void) {
        let context = DatabaseController.getContext()
            do {
                try self.pins.append(contentsOf: context.fetch(Pin.fetchRequest()))
                callback(.OK)
            } catch {
                print("There was an error fetching data \(error)")
                callback(.FAILED)
            }
    }
}
struct MapRegion {
    static let archive = "mapRegionArchive"
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let latitudeDelta = "latitudeDelta"
        static let longitudeDelta = "longitudeDelta"
    }
}

extension MapViewController {
    func immediateDownload(pin: Pin) {
        guard pin != nil else {
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
}
