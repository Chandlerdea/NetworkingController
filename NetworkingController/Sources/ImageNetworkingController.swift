//
//  ImageNetworkingController.swift
//  SpinlisterKit
//
//  Created by Chandler De Angelis on 7/15/16.
//  Copyright © 2016 Spinlister LLC. All rights reserved.
//

import Foundation

public final class ImageNetworkingController: NetworkingController, APIURLResponseImageType {
    
    public convenience override init() {
        self.init(sessionConfiguration: .default)
    }
    
    public override init(sessionConfiguration: URLSessionConfiguration) {
        super.init(sessionConfiguration: sessionConfiguration)
    }
}
