//
//  Strings.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import Firebase

let cypherURL = "http://hobby-jhaamkgcjildgbkembihibpl.dbs.graphenedb.com:24789/db/data/cypher"

let center_of_map: [String: Double] = ["latitude": 41.31574, "longitude": -72.92562]

var ne: [String: Double]!
var sw: [String: Double]!

let mapBoxDictionary = [
    "Art Rooms": [ "configURL":"mapbox://ml2445.dtmpr3x3", "sourceLayer":"Art_Rooms_V3-97bs8y"],
    "Theater": [ "configURL":"mapbox://ml2445.08wbs2xm", "sourceLayer":"Theater_V3-a5oqmu"],
    "Student Meeting Rooms": [ "configURL":"mapbox://ml2445.1kxi0jtv", "sourceLayer":"Student_Meeting_Rooms_V3-3mfgvf"],
    "Stairs": [ "configURL":"mapbox://ml2445.0bsaz5v5", "sourceLayer":"Stairs_V3-1q3qda"],
    "Seminar": [ "configURL":"mapbox://ml2445.3rjb8cmw", "sourceLayer":"Seminar_V3-64u1ww"],
    "Restrooms": [ "configURL":"mapbox://ml2445.8lsu6h7m", "sourceLayer":"Restrooms_V3-bj2hb6"],
    "Recreation": [ "configURL":"mapbox://ml2445.8dinovwj", "sourceLayer":"Recreation_V3-7oiovi"],
    "Music Rooms": [ "configURL":"mapbox://ml2445.7g90kkvu", "sourceLayer":"Music_Rooms_V3-c9b12e"],
    "utilities": [ "configURL":"mapbox://ml2445.da2ih5k9", "sourceLayer":"Itilities_V3-363vle"],
    "Kitchen": [ "configURL":"mapbox://ml2445.b5524gxl", "sourceLayer":"Kitchen_V3-64klf9"],
    "Computers": [ "configURL":"mapbox://ml2445.0xwevdk3", "sourceLayer":"Computers_V3-2xyw91"],
    "Elevator": [ "configURL":"mapbox://ml2445.abs7u0ta", "sourceLayer":"Elevators_V3-4adpg4"],
    "Buttery": [ "configURL":"mapbox://ml2445.8smnky41", "sourceLayer":"Buttery_Polygon_V3-2yfzo3"]
]

let backgroundHallway = [
    ["identifier": "Background", "configURL":"mapbox://ml2445.58o91ooh", "sourceLayer":"Background_V2-42tpfv"],
    ["identifier": "Other Rooms", "configURL":"mapbox://ml2445.1i3y3w08", "sourceLayer":"Other_Rooms_V2-awbrod"],
    ["identifier": "Spaces", "configURL":"mapbox://ml2445.d4g75h8g", "sourceLayer":"Spaces_V2-3m4vpl"]
    ]

let styleLayerArray = mapBoxDictionary.keys


class Strings {
    public static func retrieve() {
        var ref: DatabaseReference!
        ref = Database.database().reference()
        ref.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String : AnyObject]
            ne = ["latitude": (postDict!["ne"]?["latitude"]?! as? Double)!, "longitude": (postDict!["ne"]?["longitude"]?! as? Double)!]
            sw = ["latitude": (postDict!["sw"]?["latitude"]?! as? Double)!, "longitude": (postDict!["sw"]?["longitude"]?! as? Double)!]
            print(postDict!["center_of_map"])
            print(postDict!["rooms"])
            print(postDict!["sw"])
        })
    }
}

