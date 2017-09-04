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
import Alamofire

// View controller for Apple Maps Example
class AppleMapsViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate, IALocationManagerDelegate {
    
    var resultSearchController:UISearchController? = nil
    
    var mapView: MGLMapView!
    var label = UILabel()
    var initial_center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.31574, longitude: -72.92562)

    var polylineSource: MGLShapeSource?

    
    // Manager for IALocationManager
    var manager = IALocationManager.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up Search Bar
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        // Setting up Map View
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(initial_center, zoomLevel: 18, animated: false)
        view.addSubview(mapView)
        
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
        
        addAnnotation(center: initial_center)

        // Testing a function here: 
        // Takes in Current Location id and Selected Location id and Sets arrayOfCoordinates
        getPath(start: "1", end: "4")
        
        
        
        // Enable touch gesture for selection of polygon
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        mapView.addGestureRecognizer(gesture)
    }
    
    func getPath(start: String, end: String){
        let loginData = String(format: "neo4j:password").data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        
        let headers: HTTPHeaders = [
            "Authorization": "Basic \(base64LoginData)",
            "Accept": "application/json"
        ]
        
        // Find shortest path via a list of Nodes
        let shortestPath: Parameters = [
            "query" : "MATCH path=shortestPath((a:Point {id:{id1}})-[*]-(b:Point {id:{id4}})) RETURN path",
            "params" : [
                "id1": start,
                "id4": end
            ]
        ]
        
        var newListOfCoordinates: [CLLocationCoordinate2D] = []
        
        Alamofire.request("http://127.0.0.1:7474/db/data/cypher", method: .post, parameters: shortestPath, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any?]]]
            for result in arrayOfDicts {
                for item in result{
                    let nodes = item["nodes"] as! Array<String>
                    for URLtoNode in nodes {
                        let propertiesURL = "\(URLtoNode)/properties"
                        Alamofire.request(propertiesURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            let propertiesOfNode = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:String]
                            let node: Node = Node(object_passed_in: propertiesOfNode)!
                            newListOfCoordinates.append(CLLocationCoordinate2D(latitude: Double(node.latitude)!, longitude: Double(node.longitude)!))
                            let polyline = MGLPolylineFeature(coordinates: newListOfCoordinates, count: 4)
                            self.polylineSource?.shape = polyline
                        }
                    }

                }
            }

        }
        
        // Test code here: to fetch the nearest node
        // Find shortest path via a list of Nodes
        let nearestNodes: Parameters = [
            "query" : "MATCH (n) WHERE abs(toFloat(n.latitude) - {latitude}) < 0.00004694 AND abs(toFloat(n.longitude) + {longitude}) < 0.00012660499 RETURN n",
            "params" : [
                "latitude": 41.31582353,
                "longitude": 72.92588508
            ]
        ]
        Alamofire.request("http://127.0.0.1:7474/db/data/cypher", method: .post, parameters: nearestNodes, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            var sumOfSquares: Double = 0
            var closestNode: Node = Node()
            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any]]]
            for result in arrayOfDicts {
                for item in result{
                    let propertiesOfNode = item["data"] as! [String:Any?]
                    let node: Node = Node(object_passed_in: propertiesOfNode)!
                    if sumOfSquares == 0 {
                        closestNode = node
                        sumOfSquares = pow(Double(node.latitude)! - 41.31582353, 2) + pow(Double(node.longitude)! + 72.92588508, 2)
                    } else {
                        let currentSumOfSquares = pow(Double(node.latitude)! - 41.31582353, 2) + pow(Double(node.longitude)! + 72.92588508, 2)
                        if currentSumOfSquares < sumOfSquares {
                            closestNode = node
                            sumOfSquares = currentSumOfSquares
                        }
                    }
                }
            }
         print("Closest Node is here \(closestNode)")
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
            image = Helper.ResizeImage(image: image, targetSize: CGSize(width: 20, height: 20.0))
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
        layer.lineColor = MGLStyleValue(rawValue: UIColor.blue)
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 2),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 6)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.0)])
        style.addLayer(layer)
        
        // Test code for adding the Map Layer, Test whether the selected polygon method works
        let layerSource = MGLVectorSource(identifier: "Art Rooms", configurationURL: URL(string: "mapbox://ml2445.3us1mnug")!)
        style.addSource(layerSource)
        // Create a style layer using the vector source.
        let actualLayer = MGLFillStyleLayer(identifier: "Art Rooms", source: layerSource)
        
        actualLayer.sourceLayerIdentifier = "Art_Rooms-a2rv20"
        
        // Set the fill pattern and opacity for the style layer.
        actualLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
        
        style.addLayer(actualLayer)
        
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    // source: https://www.mapbox.com/ios-sdk/examples/select-layer/
    
    func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["Art Rooms"]))
        
        //just to see what's inside the attributes: I added the third parameter
        
        // Get the name of the selected state.
        if let feature = features.first, let state = feature.attribute(forKey: "Art Rooms") as? String{
            changeOpacity(name: state)
        } else {
            changeOpacity(name: "")
        }
    }
    
    func changeOpacity(name: String) {
        let layer = mapView.style?.layer(withIdentifier: "Art Rooms") as! MGLFillStyleLayer
        
        // Check if a state was selected, then change the opacity of the states that were not selected.
        if name.characters.count > 0 {
            layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "Art Rooms", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
        } else {
            // Reset the opacity for all states if the user did not tap on a state.
            layer.fillOpacity = MGLStyleValue(rawValue: 1)
        }
    }
    
    
}
