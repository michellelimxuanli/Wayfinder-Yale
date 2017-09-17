//
//  Strings.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation

let cypherURL = "http://hobby-jhaamkgcjildgbkembihibpl.dbs.graphenedb.com:24789/db/data/cypher"

let center_of_map: [String: Double] = ["latitude": 41.31574, "longitude": -72.92562]

let mapBoxDictionary = [
    "Art Rooms": [ "configURL":"mapbox://ml2445.dtmpr3x3", "sourceLayer":"Art_Rooms_V3-97bs8y"]]

let backgroundHallway = [
    ["identifier": "Background", "configURL":"mapbox://ml2445.58o91ooh", "sourceLayer":"Background_V2-42tpfv"],
    ["identifier": "Hallways", "configURL":"mapbox://ml2445.du2mf0zl", "sourceLayer":"Hallways_V2-3xvh03"]
    ]

let styleLayerArray = mapBoxDictionary.keys
