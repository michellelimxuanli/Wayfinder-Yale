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

protocol HandleMapSearch {
    func dropPinZoomIn(selectedRoom:MGLFeature)
}

// View controller for Apple Maps Example
class AppleMapsViewController: UIViewController, MGLMapViewDelegate, DialogDelegate, UIGestureRecognizerDelegate, IALocationManagerDelegate {
    
    // Basic Map Data
    var mapView: MGLMapView!
    var initial_center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: center_of_map["latitude"]!, longitude: center_of_map["longitude"]!)
    
    // ------Navigation System-------
    // Info Screen
    var cardView: CustomView!
    var navigationView: NavigationView!
    // Route
    var selectedId: String?
    var polylineSource: MGLShapeSource?
    var annotation : MyCustomPointAnnotation?
    var userCoordinates: CLLocationCoordinate2D?
    
    // ------Blue dot positioning--------
    var currentAnnotation: MGLPointAnnotation?
    // Manager for IALocationManager
    var manager = IALocationManager.sharedInstance()
  
    
    // Search Bar
    var resultSearchController:UISearchController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
    }
    
    // When the view will appear, set up the mapView and its delegate and start requesting location
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        mapView.delegate = self
        // Enable touch gesture for selection of polygon
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        mapView.addGestureRecognizer(gesture)
        
        UIApplication.shared.isStatusBarHidden = true
        
        requestLocation()
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        // Setting up Card View
        // we'd probably want to set up constraints here in a real app
        cardView = CustomView(frame: CGRect(
            origin: CGPoint(x: 10, y: UIScreen.main.bounds.height - 80 - 10),
            size: CGSize(width: UIScreen.main.bounds.width - 20, height: 80)
        ))
        cardView.delegate = self
        view.addSubview(cardView)
        cardView.isHidden = true
        
        // Setting up Navigation View
        // also should set up constraints here in a real app
        navigationView = NavigationView(frame: CGRect(
            origin: CGPoint(x: 10, y: UIScreen.main.bounds.height - 80 - 10),
            size: CGSize(width: UIScreen.main.bounds.width - 20, height: 80)
        ))
        //navigationView.delegate = self
        view.addSubview(navigationView)
        navigationView.isHidden = true
        
    }
    
    // This function is called whenever new location is received from IALocationManager
    func indoorLocationManager(_ manager: IALocationManager, didUpdateLocations locations: [Any]) {
        
        // Conversion to IALocation
        let l = locations.last as! IALocation
        // Check if there is newLocation and that it is not a nil
        if let newLocation = l.location?.coordinate {
            SVProgressHUD.dismiss()
            // Remove all previous overlays from the map and add new
            if let currentAnnotation = currentAnnotation{
                mapView.removeAnnotation(currentAnnotation)
            }
            userCoordinates = newLocation
            addCurrentLocation(center: userCoordinates!)
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
    // When the view will disappear, stop updating location, remove map from the view and dismiss the HUD
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.manager.stopUpdatingLocation()
        
        manager.delegate = nil
        mapView.delegate = nil
        mapView.removeFromSuperview()
        
        UIApplication.shared.isStatusBarHidden = false
        
        SVProgressHUD.dismiss()
    }

    
    // ----------Add Layers and features -------
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addLayer(to: style)
        Rooms.addRooms(to: style)
    }
    // Draggable Point
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation is MyCustomPointAnnotation {
            // For better performance, always try to reuse existing annotations. To use multiple different annotation views, change the reuse identifier for each.
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") {
                return annotationView
            } else {
                return DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 30)
            }
        }
        else {
            return nil
        }
    }
    // Current Location
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "circle")
        if annotationImage == nil {
            var image = UIImage(named: "circle")!
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
            image = ImageHelper.ResizeImage(image: image, targetSize: CGSize(width: 20, height: 20.0))
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "circle")
        }
        return annotationImage
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func addCurrentLocation(center: CLLocationCoordinate2D) {
        currentAnnotation = MGLPointAnnotation()
        currentAnnotation?.coordinate = center
        mapView.addAnnotation(currentAnnotation!)
        
    }
    // adding the draggable point on the current user location
    func addMarkerAnnotation(center: CLLocationCoordinate2D) {
        annotation = MyCustomPointAnnotation()
        annotation?.coordinate = center
        mapView.addAnnotation(annotation!)
        
    }
    // MGLPointAnnotation subclass, really, this is just to identify that the
    class MyCustomPointAnnotation: MGLPointAnnotation {
        var willUseImage: Bool = false
    }

    
    //----------GETTING PATHS-------
    func addLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = returnLine.line(source: source);
        style.addLayer(layer)
    }
    func didPressButton(button:UIButton) {
        navigationView.isHidden = false
        addMarkerAnnotation(center: userCoordinates!)
        getPath(start: "1", end: selectedId!)
    }
    func getPath(start: String, end: String){
        // Find shortest path via a list of Nodes
        let shortestPath: Parameters = [
            "query" : "MATCH path=shortestPath((a:Point {id:{id1}})-[*]-(b:Point {id:{id4}})) RETURN path",
            "params" : [
                "id1": start,
                "id4": end
            ]
        ]
        Alamofire.request(cypherURL, method: .post, parameters: shortestPath, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any?]]]
            for result in arrayOfDicts {
                for item in result{
                    let nodes = item["nodes"] as! Array<String>
                    self.drawLine(nodes: nodes)
                }
            }
        }
    }
    func drawLine(nodes: Array<String>){
        let size = nodes.count
        var coordinatesArray = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: size)
        var noOfElements = 0
        for (index, URLtoNode) in nodes.enumerated() {
            let propertiesURL = "\(URLtoNode)/properties"
            Alamofire.request(propertiesURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                let propertiesOfNode = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:String]
                let node: Node = Node(object_passed_in: propertiesOfNode)!
                coordinatesArray[index] = CLLocationCoordinate2D(latitude: Double(node.latitude)!, longitude: Double(node.longitude)!)
                noOfElements+=1
                if (noOfElements == size){
                    let polyline = MGLPolylineFeature(coordinates: coordinatesArray, count: UInt(size))
                    self.polylineSource?.shape = polyline
                }
            }
        }
    }
    
    func closestNode(coordinates: CLLocationCoordinate2D) {
        // Test code here: to fetch the nearest node
        // TODO: Use the SELECTED NODE for drawing path
        let nearestNodes: Parameters = [
            "query" : "MATCH (n) WHERE abs(toFloat(n.latitude) - {latitude}) < 0.00004694 AND abs(toFloat(n.longitude) + {longitude}) < 0.00012660499 RETURN n",
            "params" : [
                "latitude": coordinates.latitude,
                "longitude": coordinates.longitude
            ]
        ]
        Alamofire.request(cypherURL, method: .post, parameters: nearestNodes, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
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
                        sumOfSquares = pow(Double(node.latitude)! - coordinates.latitude, 2) + pow(Double(node.longitude)! - coordinates.longitude, 2)
                    } else {
                        let currentSumOfSquares = pow(Double(node.latitude)! - coordinates.latitude, 2) + pow(Double(node.longitude)! - coordinates.longitude, 2)
                        if currentSumOfSquares < sumOfSquares {
                            closestNode = node
                            sumOfSquares = currentSumOfSquares
                        }
                    }
                }
            }
            print("Closest Node is here \(closestNode)")
        }
        
        //then run the closestNode thing in the red and print out error if we can't find the closest node
    }

    // ----Tap and select----
    // source: https://www.mapbox.com/ios-sdk/examples/select-layer/
    func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(styleLayerArray))
        
        // Check if feature in a layer was selected.
        if let feature = features.first, let _ = feature.attribute(forKey: "category") as? String{
            whenSelected(selectedRoom: feature)
        } else {
            cardView.isHidden = true
            for eachLayerName in styleLayerArray {
                if let eachLayer = mapView.style?.layer(withIdentifier: eachLayerName) as! MGLFillStyleLayer? {
                    eachLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
                }
            }
        }
    }
    func whenSelected(selectedRoom: MGLFeature){
        // Highlight
        changeOpacity(name: (selectedRoom.attribute(forKey: "id") as? String)!, layername: (selectedRoom.attribute(forKey: "category") as? String)!)
        // Update Info
        cardView.title = selectedRoom.attribute(forKey: "name") as? String
        cardView.isHidden = false
        selectedId = selectedRoom.attribute(forKey: "id") as? String
        // Zooming
        let centerOfSelected = Rooms.returnFeatureCoordinates(feature: selectedRoom)
        mapView.setCenter(centerOfSelected!, zoomLevel: 18, animated: true)
    }
    func changeOpacity(name: String, layername: String) {
        let layer = mapView.style?.layer(withIdentifier: layername) as! MGLFillStyleLayer
            for eachLayerName in styleLayerArray {
                if (eachLayerName == layername) {
                    layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "id", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0.5)])
                } else {
                    if let eachLayer = mapView.style?.layer(withIdentifier: eachLayerName) as! MGLFillStyleLayer? {
                        eachLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
                    }
                }
            }
    }
    
}
extension AppleMapsViewController: HandleMapSearch {
    func dropPinZoomIn(selectedRoom:MGLFeature){
        whenSelected(selectedRoom: selectedRoom)
    }
}






