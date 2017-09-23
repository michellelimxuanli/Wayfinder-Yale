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
        actualLayer.fillOutlineColor = MGLStyleValue(rawValue:UIColor(red:0.43, green:0.42, blue:0.42, alpha:1.0)); //black
        
        switch vectorSource {
            case "Art Rooms":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.96, green:0.65, blue:0.49, alpha:1.0)) //orange
            case "Theater":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.96, green:0.65, blue:0.49, alpha:1.0)) //orange
            case "Student Meeting Rooms":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.70, green:0.83, blue:0.93, alpha:1.0)) //blue
            case "Stairs":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.66, green:0.54, blue:0.53, alpha:1.0)) //brown
            case "Seminar":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.70, green:0.83, blue:0.93, alpha:1.0)) //blue
            case "Restrooms":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.87, green:0.75, blue:0.93, alpha:1.0)) //purple
            case "Recreation":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:1.00, green:0.95, blue:0.71, alpha:1.0)) //yellow
            case "Music Rooms":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.96, green:0.65, blue:0.49, alpha:1.0)) //orange
            case "itilities":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.95, green:0.96, blue:0.86, alpha:1.0)) //random green
            case "Kitchen":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.74, green:0.92, blue:0.87, alpha:1.0)) //green
            case "Computers":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.70, green:0.83, blue:0.93, alpha:1.0)) //blue
            case "Elevator":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.79, green:0.83, blue:0.87, alpha:1.0)) //bluish grey
            case "Buttery":
            actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.74, green:0.92, blue:0.87, alpha:1.0)) //green
            default:
            actualLayer.fillColor = MGLStyleValue(rawValue: UIColor(red:0.99, green:0.96, blue:0.55, alpha:1.0))
        }
        
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
