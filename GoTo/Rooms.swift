//
//  Rooms.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import Mapbox

class Rooms {
    static func addRoomLayer(to style: MGLStyle, vectorSource: String, configURL: String, sourceLayer: String) {
        // Test code for adding the Map Layer
        let layerSource = MGLVectorSource(identifier: vectorSource, configurationURL: URL(string: configURL)!)
        style.addSource(layerSource)
        // Create a style layer using the vector source.
        let actualLayer = MGLFillStyleLayer(identifier: vectorSource, source: layerSource)
        
        actualLayer.sourceLayerIdentifier = sourceLayer
        
        // Set the fill pattern and opacity for the style layer.
        actualLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
        
        style.addLayer(actualLayer)
        
    }
    
    public static func returnFeatureCoordinates(feature:MGLFeature) -> CLLocationCoordinate2D? {
        let dictionary = feature.geoJSONDictionary() as [String: Any]
        let geometry = dictionary["geometry"] as? [String: Any]
        let coordinates = geometry?["coordinates"] as? [[[Any]]]
        let arrayOfArray = coordinates?[0][0] as? [Double]
        return CLLocationCoordinate2D(latitude: arrayOfArray![1], longitude: arrayOfArray![0])
    }

    public static func addRooms(to style: MGLStyle) {
        for eachKey in mapBoxDictionary.keys {
            addRoomLayer(to: style, vectorSource: eachKey, configURL: (mapBoxDictionary[eachKey]?["configURL"])!, sourceLayer: (mapBoxDictionary[eachKey]?["sourceLayer"])!)
        }
    }
}
