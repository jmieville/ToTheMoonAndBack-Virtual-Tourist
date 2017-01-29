//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Jean-Marc Kampol Mieville on 1/6/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
