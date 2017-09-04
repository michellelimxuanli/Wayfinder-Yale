//
//  Node.swift
//  GoTo
//
//  Created by Michelle Lim on 9/2/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation

struct Node {
    var id: String!
    var name: String?
    var latitude: String!
    var longitude: String!
}

extension Node {
    init?(object_passed_in: [String: Any?]) {
        if let name = object_passed_in["name"]{
            self.name = name as? String}
        self.id = object_passed_in["id"] as! String
        self.longitude = object_passed_in["longitude"] as! String
        self.latitude = object_passed_in["latitude"] as! String
    }
}
