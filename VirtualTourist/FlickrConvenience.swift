//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/6/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import MapKit

typealias completionHandlerPin = (_ success: Bool, _ errorString: String?) -> Void
typealias completionHandlerForImageUrl = (_ imageInformations: [String:URL]?, _ numberOfPages: Int?, _ errorMessage: String?) -> Void
typealias requestCompletionHandler = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void

extension FlickrAPI {

    // get Photo Info at Pin within radius from Json
    func downloadInfoPhotoAtPin(_ pin: Pin, _ latitude: Double, _ longitude: Double, _ radius: Double = 1,_ page: Int, completionHandler: @escaping completionHandlerForImageUrl) {
        //let bbox = self.boundingBoxString(bboxInfo)
        
        let randomSortKey = randomSortKeyString()
        let methodArguments: [String: Any] = [
            "method": FlickrAPI.Constants.METHOD_NAME,
            "api_key": FlickrAPI.Constants.API_KEY,
            "lat": latitude,
            "lon": longitude,
            "radius": radius,
            "safe_search": FlickrAPI.Constants.SAFE_SEARCH,
            "extras": FlickrAPI.Constants.EXTRAS,
            "format": FlickrAPI.Constants.DATA_FORMAT,
            "nojsoncallback": FlickrAPI.Constants.NO_JSON_CALLBACK,
            "per_page": FlickrAPI.Constants.PER_PAGE,
            "page": page
        ]
        
        // Get the FLickr URL
        let urlString = BaseURL.BASE_URL + escapedParameters(methodArguments as [String : AnyObject])
        guard let url = URL(string: urlString) else {
            print("Cannot get FlickrURL")
            return
        }
        let context = DatabaseController.getContext()
        //Create the Request
        let request = URLRequest(url: url as URL)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
            }
            guard error == nil else {
                print("There was an error\(error)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode < 300 else {
                print("Status code error")
                return
            }
            guard let data = data else {
                print("error \(error)")
                return
            }
            // Deserialize
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            guard let photos = parsedResult[FlickrAPI.JSONResponseKey.photos] as? [String:Any] else {
                    completionHandler(nil, nil, "Error when parsing JSON")
                    print("Cannot get photo here 1!!!!")
                    return
            }
            guard let numPages = photos[FlickrAPI.JSONResponseKey.pages] as? Int else {
                    completionHandler(nil, nil, "Error when parsing JSON")
                    print("Cannot get photo here 2!!!!")
                    return
            }
            guard let photoArray = photos[FlickrAPI.JSONResponseKey.photoArray] as? [[String:Any]] else {
                    completionHandler(nil, nil, "Error when parsing JSON")
                    print("Cannot get photo here 3!!!!")
                    return
            }
            var imageInfoDicts = [String:URL]()
            AlbumViewController.imageInfoDicts.removeAll()

            for photo in photoArray {
                guard let parsedImageUrlString = photo[FlickrAPI.JSONResponseKey.imageMediumUrl] as? String else {
                    print("Cannot get parsedResult into information 1")
                    return
                }
                guard let parsedImageUrl = URL(string: parsedImageUrlString) else {
                    print("Cannot get parsedResult into information 2")
                    return
                }
                guard let parsedImageID = photo[FlickrAPI.JSONResponseKey.id] as? String else {
                    print("Cannot get parsedResult into information 3")
                    return
                }
                imageInfoDicts[parsedImageID] = parsedImageUrl
                AlbumViewController.imageInfoDicts = imageInfoDicts
                AlbumViewController.numberOfPages = numPages
            }

            completionHandler(imageInfoDicts, numPages, nil)
        }
        task.resume()
    }

    // Todo: download 21 images from random pages at Pinlocation

    //Random page number
    func randomPageNumber(totalPageCount: Int) -> Int {
        var pageNumber = 1
        var numPagesInt = totalPageCount as Int
        if numPagesInt > numberOfPageLimit {
            numPagesInt = numberOfPageLimit
        }
        pageNumber = Int((arc4random_uniform(UInt32(numPagesInt)))) + 1
        return pageNumber
    }
    
    //Random sort key
    func randomSortKeyString() -> String {
        let possibleSorts = ["date-posted-desc", "date-posted-asc", "date-taken-desc", "date-taken-asc", "interstingness-desc", "interestingness-asc"]
        return possibleSorts[Int((arc4random_uniform(UInt32(possibleSorts.count))))]
    }
}
