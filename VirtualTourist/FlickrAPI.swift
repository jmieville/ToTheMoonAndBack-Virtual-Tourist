//
//  FlickerAPI.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/2/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

typealias RequestCompletionHandler = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void
// Capped at 190
let numberOfPageLimit = 190
var photos: [Photo] = []

class FlickrAPI {
    let context = DatabaseController.getContext()
    static let shared = FlickrAPI()

    //escaped parameters
    func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            for (key, value) in parameters {
                // make sure that it is a string value
                let stringValue = "\(value)"
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    //singleton
    class func sharedInstance() -> FlickrAPI {
        struct Singleton {
            static var sharedInstance = FlickrAPI()
        }
        return Singleton.sharedInstance
    }
}
