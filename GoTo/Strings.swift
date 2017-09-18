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
    "Art Rooms": [ "configURL":"mapbox://ml2445.dtmpr3x3", "sourceLayer":"Art_Rooms_V3-97bs8y"],
    "Theater": [ "configURL":"mapbox://ml2445.4tlo56py", "sourceLayer":"Theater_V2-70kaj1"],
    "Meeting Rooms": [ "configURL":"mapbox://ml2445.6qh2lgl8", "sourceLayer":"Student_Meeting_Rooms_V2-62y8np"],
    "Stairs": [ "configURL":"mapbox://ml2445.4jgvvy1d", "sourceLayer":"Stairs_V2-7zwowp"],
    "Seminar Rooms": [ "configURL":"mapbox://89td5fll", "sourceLayer":"Seminar_V2-0xg3h4"],
    "Rest Rooms": [ "configURL":"mapbox://ml2445.b1xw8kys", "sourceLayer":"Restrooms_V2-1cfxau"],
    "Recreation": [ "configURL":"mapbox://ml2445.63xtcbgy", "sourceLayer":"Recreation_V2-8bgxew"],
    "Music Rooms": [ "configURL":"mapbox://ml2445.b524o63e", "sourceLayer":"Music_Rooms_V2-dtuk1b"],
    "itilities": [ "configURL":"mapbox://ml2445.9yheo59r", "sourceLayer":"itilities_V2-2sbul0"],
    "Kitchen": [ "configURL":"mapbox://ml2445.af69lli3", "sourceLayer":"Kitchen_V2-ch4368"],
    "Computer Rooms": [ "configURL":"mapbox://ml2445.b4k4ofpr", "sourceLayer":"Computers_V2-4v9ylg"],
    "Elevators": [ "configURL":"mapbox://ml2445.btifad83", "sourceLayer":"Elevators_V2-9yu6yi"],
    "Buttery": [ "configURL":"mapbox://ml2445.8zb5662e", "sourceLayer":"Buttery_V2-6bn9k3"]
]

let backgroundHallway = [
    ["identifier": "Background", "configURL":"mapbox://ml2445.58o91ooh", "sourceLayer":"Background_V2-42tpfv"],
    ["identifier": "Other Rooms", "configURL":"mapbox://ml2445.1i3y3w08", "sourceLayer":"Other_Rooms_V2-awbrod"],
    ["identifier": "Spaces", "configURL":"mapbox://ml2445.d4g75h8g", "sourceLayer":"Spaces_V2-3m4vpl"]
    ]

let styleLayerArray = mapBoxDictionary.keys
