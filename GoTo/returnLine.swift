//
//  returnLine.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import Mapbox

class returnLine{
    public static func line(source: MGLShapeSource) -> MGLLineStyleLayer {
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        layer.lineColor = MGLStyleValue(rawValue: UIColor.blue)
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 2),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 6)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.0)])
        return layer
    }
}

