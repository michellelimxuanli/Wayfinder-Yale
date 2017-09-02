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
import Theo
import PackStream

// View controller for Apple Maps Example
class AppleMapsViewController: UIViewController, MGLMapViewDelegate, IALocationManagerDelegate {
    
    var mapView: MGLMapView!
    var label = UILabel()
    var initial_center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.31569, longitude: -72.92562)
    var polylineSource: MGLShapeSource?
    
    // Theo Client and Configuration
    private var theo: BoltClient?
    var connectionConfig: ConnectionConfig? = ConnectionConfig(host: "http://127.0.0.1/", port: 7687, username: "neo4j", password: "password")
    
    // Manager for IALocationManager
    var manager = IALocationManager.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Set the map’s center coordinate and zoom level.
        mapView.setCenter(initial_center, zoomLevel: 19, animated: false)
        view.addSubview(mapView)
        
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
        
        addAnnotation(center: initial_center)
        
        connectToTheo()
    }
    
    func connectToTheo() {
        if let config = connectionConfig {
            do {
                theo = try  BoltClient(hostname: config.host, port: config.port, username: config.username, password: config.password, encrypted: true)
            } catch {
                DispatchQueue.main.async {
                    print("Failed during connection configuration")
                }
                return
            }
        } else {
            print("Missing connection configuration")
        }

    }
    
    // Hide status bar
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func addAnnotation(center: CLLocationCoordinate2D) {
        let annotation = MGLPointAnnotation()
        annotation.coordinate = center
        
        mapView.addAnnotation(annotation)
        
    }
    
    // This function is called whenever new location is received from IALocationManager
    func indoorLocationManager(_ manager: IALocationManager, didUpdateLocations locations: [Any]) {
        
        // Conversion to IALocation
        let l = locations.last as! IALocation
        
        // Check if there is newLocation and that it is not a nil
        if let newLocation = l.location?.coordinate {
            
            SVProgressHUD.dismiss()
            
            // Remove all previous overlays from the map and add new
            mapView.removeAnnotations(mapView.annotations!)
            addAnnotation(center: newLocation)
            
//            // Ask Map Kit for a camera that looks at the location from an altitude of 300 meters above the eye coordinates.
//            camera = MKMapCamera(lookingAtCenter: (l.location?.coordinate)!, fromEyeCoordinate: (l.location?.coordinate)!, eyeAltitude: 300)
//            
//            // Assign the camera to your map view.
//            map.camera = camera;
        }
    }
    
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
        
        mapView.frame = view.bounds
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView)
        mapView.delegate = self
        
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
        mapView.delegate = nil
        mapView.removeFromSuperview()
        label.removeFromSuperview()
        
        UIApplication.shared.isStatusBarHidden = false
        
        
        SVProgressHUD.dismiss()
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "circle")
        
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
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "circle")
        }
        
        return annotationImage
    }
    
    // Wait until the map is loaded before adding to the map.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addLayer(to: style)
    }
    
    func addLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        layer.lineColor = MGLStyleValue(rawValue: UIColor.red)
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 5),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 20)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        style.addLayer(layer)
        
        
        let polyline = MGLPolylineFeature(coordinates: [CLLocationCoordinate2D(latitude: 41.31586349, longitude: -72.92659499),
                                                        CLLocationCoordinate2D(latitude: 41.31589628, longitude: -72.92650042)], count: 2)
        polylineSource?.shape = polyline
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
