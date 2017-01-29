//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/3/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    //Outlets
    @IBOutlet weak var imageCell: UIImageView!
    
    @IBOutlet weak var activityIcn: UIActivityIndicatorView!
    var photoUrlString: String? = nil
    static let reuseIdentifier: String = "photoCell"
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.clear.cgColor
        }
    }
}
