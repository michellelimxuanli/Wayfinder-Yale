//
//  AppleMapsViewController.swift
//  GoTo
//
//  Created by Michelle Lim on 8/29/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import UIKit
import IndoorAtlas
import SVProgressHUD
import Mapbox

// View controller for Apple Maps Example
class AppleMapsViewController: UIViewController, MGLMapViewDelegate, IALocationManagerDelegate {
    
    var mapView: MGLMapView!
    var label = UILabel()
    
    // Manager for IALocationManager
    var manager = IALocationManager.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Set the map’s center coordinate and zoom level.
        mapView.setCenter(CLLocationCoordinate2D(latitude: 41.31569, longitude: -72.92562), zoomLevel: 19, animated: false)
        view.addSubview(mapView)
                mapView.delegate = self
        
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
        
        addAnnotation()
    }
    
    // Hide status bar
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func addAnnotation() {
        let annotation = MGLPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 41.31569, longitude: -72.92562)
        annotation.title = "Kinkaku-ji"
        annotation.subtitle = "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)"
        
        mapView.addAnnotation(annotation)
        
        // Center the map on the annotation.
        mapView.setCenter(annotation.coordinate, zoomLevel: 19, animated: false)
        
    }
    
    // This function is called whenever new location is received from IALocationManager
    func indoorLocationManager(_ manager: IALocationManager, didUpdateLocations locations: [Any]) {
        
        // Conversion to IALocation
        let l = locations.last as! IALocation
        
        // Check if there is newLocation and that it is not a nil
        if let newLocation = l.location?.coordinate {
            
            SVProgressHUD.dismiss()
            
            // Remove all previous overlays from the map and add new
//            map.removeOverlays(map.overlays)
//            circle = MKCircle(center: newLocation, radius: 2)
//            map.add(circle)
//            
//            // Ask Map Kit for a camera that looks at the location from an altitude of 300 meters above the eye coordinates.
//            camera = MKMapCamera(lookingAtCenter: (l.location?.coordinate)!, fromEyeCoordinate: (l.location?.coordinate)!, eyeAltitude: 300)
//            
//            // Assign the camera to your map view.
//            map.camera = camera;
        }
    }
    
    
    
    // This function is used for rendering the overlay components
    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        
//        var circleRenderer = MKCircleRenderer()
//        
//        // Try conversion to MKCircle for the overlay
//        if let overlay = overlay as? MKCircle {
//            
//            // Set up circleRenderer for rending the circle
//            circleRenderer = MKCircleRenderer(circle: overlay)
//            circleRenderer.fillColor = UIColor(colorLiteralRed: 0, green: 0.647, blue: 0.961, alpha: 1.0)
//        }
//        
//        return circleRenderer
//    }
    
    // Authenticate to IndoorAtlas services and request location updates
    func requestLocation() {
        
        // Point delegate to receiver
        manager.delegate = self
        
        // Optionally initial location
        if !kFloorplanId.isEmpty {
            let location = IALocation(floorPlanId: kFloorplanId)
            manager.location = location
        }
        
        // Request location updates
        manager.startUpdatingLocation()
    }
    
    // When the view will appear, set up the mapView and its delegate and start requesting location
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        map.frame = view.bounds
//        view.addSubview(map)
//        view.sendSubview(toBack: map)
//        map.delegate = self
        
        var frame = view.bounds
        frame.origin.y = 64
        frame.size.height = 42
        label.frame = frame
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        view.addSubview(label)
        
        UIApplication.shared.isStatusBarHidden = true
        
        requestLocation()
    }
    
    // When the view will disappear, stop updating location, remove map from the view and dismiss the HUD
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.manager.stopUpdatingLocation()
        
        manager.delegate = nil
//        map.delegate = nil
//        map.removeFromSuperview()
        label.removeFromSuperview()
        
        UIApplication.shared.isStatusBarHidden = false
        
        
        SVProgressHUD.dismiss()
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "pisa")
        
        if annotationImage == nil {
            var image = UIImage(named: "circle")!
            
            // The anchor point of an annotation is currently always the center. To
            // shift the anchor point to the bottom of the annotation, the image
            // asset includes transparent bottom padding equal to the original image
            // height.
            //
            // To make this padding non-interactive, we create another image object
            // with a custom alignment rect that excludes the padding.
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
            image = ResizeImage(image: image, targetSize: CGSize(width: 20, height: 20.0))
            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "pisa")
        }
        
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    //from https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: targetSize.width, height: targetSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
