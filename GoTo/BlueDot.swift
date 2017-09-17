//
//  BlueDot.swift
//  GoTo
//
//  Created by Michelle Lim on 9/17/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//


import Foundation
import UIKit
import Mapbox

// from https://github.com/ziyang0621/GoogleMapsCurrentLocationRotation-Swift/blob/master/GoogleMapSwift/ViewController.swift
// and https://stackoverflow.com/questions/7173925/how-to-rotate-a-direction-arrow-to-particular-location

class BlueDot{
 
    public static func DegreesToRadians(degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }
    
    public static func RadiansToDegrees(radians: Double) -> Double {
        return radians * 190.0/Double.pi
    }
    
    public static func imageRotatedByDegrees(degrees: Double, image: UIImage) -> UIImage{
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: CGFloat(degrees * Double.pi / 180))
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (CGFloat(degrees * Double.pi / 180)))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(image.cgImage!, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    public static func findDegrees(oldLocation: CLLocationCoordinate2D, newLocation: CLLocationCoordinate2D) -> Double {
        let lat1 = DegreesToRadians(degrees: oldLocation.latitude)
        let lon1 = DegreesToRadians(degrees: oldLocation.longitude)
        
        let lat2 = DegreesToRadians(degrees: newLocation.latitude);
        let lon2 = DegreesToRadians(degrees: newLocation.latitude);
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        var radiansBearing = atan2(y, x);
        if(radiansBearing < 0.0)
        {
            radiansBearing += 2*Double.pi;
        }
        
        return RadiansToDegrees(radians: radiansBearing);
    }
}
