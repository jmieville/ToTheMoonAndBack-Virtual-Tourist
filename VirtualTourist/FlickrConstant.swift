//
//  FlickrConstant.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/14/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import CoreData

// Constants
extension FlickrAPI {
    struct BaseURL {
        //URLs Base url to restAPI
        static let BASE_URL = "https://api.flickr.com/services/rest/"
    }
    // Constants
    struct Constants {
        //URLs Param
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "e6e4b56238c5c36fa2ab022c185333f3"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PER_PAGE = 21
        static let PAGE = 1
        // to be added
        static let BBOX = "BBOX"
    }
    //SearchRange
    struct searchRange {
        static let SearchBoundingBoxHalfWidth = 1.0
        static let SearchBoundingBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    static let session = URLSession.shared
    static let photos: [Photo] = []
    static var documentsDirectory: String?
    
    struct JSONResponseKey {
        static let photos = "photos"
        static let photoArray = "photo"
        static let pages = "pages"
        static let imageMediumUrl = "url_m"
        static let id = "id"
    }
    
}
