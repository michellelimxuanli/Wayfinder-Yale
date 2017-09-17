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
class AppleMapsViewController: UIViewController, MGLMapViewDelegate, DialogDelegate, NavigateDialogDelegate, UIGestureRecognizerDelegate, IALocationManagerDelegate {
    
    // Basic Map Data
    var mapView: MGLMapView!
    var initial_center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: center_of_map["latitude"]!, longitude: center_of_map["longitude"]!)
    
    // ------Navigation System-------
    // Info Screen
    var cardView: CustomView!
    var navigationView: NavigationView!
    var imageView: UIImageView!
    // Route
    var selectedId: String?
    var polylineSource: MGLShapeSource?
    var userCoordinates: CLLocationCoordinate2D?
    var oldLocation: CLLocationCoordinate2D?
    var linelayer: MGLLineStyleLayer!
    var gesture: UIGestureRecognizer!
    var destination:String!
    
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
        mapView = MGLMapView(frame: view.bounds, styleURL: URL(string: "mapbox://styles/mapbox/light-v9"))
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(initial_center, zoomLevel: 18, animated: false)
        view.addSubview(mapView)
        mapView.delegate = self
        // Enable touch gesture for selection of polygon
        gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
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
        navigationView.delegate = self
        view.addSubview(navigationView)
        navigationView.isHidden = true
        
        // the middle pin
        imageView = UIImageView(frame: CGRect(x: (self.view.frame.size.width / 2), y: (self.view.frame.size.height / 2) - 30, width: 40, height: 40));
        let image = UIImage(named: "icons8-Marker.png");
        imageView.image = image;
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView);
        imageView.isHidden = true
        
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
            oldLocation = userCoordinates
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
        addBackgroundHallway(to: style)
        Rooms.addRooms(to: style)
        addPathLayer(to: style)
    }
    // This delegate method is where you tell the map to load a view for a specific annotation. To load a static MGLAnnotationImage, you would use `-mapView:imageForAnnotation:`.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            // Set the annotation view’s background color.
            annotationView!.backgroundColor = UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    func addCurrentLocation(center: CLLocationCoordinate2D) {
        currentAnnotation = MGLPointAnnotation()
        currentAnnotation?.coordinate = center
        mapView.addAnnotation(currentAnnotation!)
    }

    func addBackgroundHallway(to style: MGLStyle) {
        for backlayer in backgroundHallway {
            let layerSource = MGLVectorSource(identifier: backlayer["identifier"]!, configurationURL: URL(string: backlayer["configURL"]!)!)
            style.addSource(layerSource)
            // Create a style layer using the vector source.
            let actualLayer = MGLFillStyleLayer(identifier: backlayer["identifier"]!, source: layerSource)
        
            actualLayer.sourceLayerIdentifier = backlayer["sourceLayer"]!
        
            // Set the fill pattern and opacity for the style layer.
            if backlayer["identifier"]! == "Background" {
                actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.99, green:0.99, blue:0.85, alpha:1.0))
            } else if backlayer["identifier"]! == "Hallways"{
                actualLayer.fillColor = MGLStyleValue(rawValue:UIColor(red:0.93, green:0.94, blue:0.96, alpha:1.0))
                
            }
        
            style.addLayer(actualLayer)
        }

    }
    
    //----------GETTING PATHS-------
    func addPathLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        linelayer = returnLine.line(source: source);
        style.addLayer(linelayer)
        linelayer.isVisible = true
    }
    
    
    func didPressButton(button:UIButton) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationView.instruction.text = "Adjust map to select location"
        navigationView.isHidden = false
        mapView.setCenter(userCoordinates!, zoomLevel: 18, animated: true)
        navigationView.confirmLocation.setTitle("Confirm starting location", for: [])
        imageView.isHidden = false
        gesture.isEnabled = false
        
    }
    func didPressCancel(button:UIButton) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        navigationView.isHidden = true
        imageView.isHidden = true
        linelayer.isVisible = false
        gesture.isEnabled = true
    }
    func didPressStarting(button: UIButton) {
        // if all goes well and you get Id
        navigationView.start()
        let newCoordinate = mapView.convert(CGPoint(x: (self.view.frame.size.width / 2), y: (self.view.frame.size.height / 2)-10), toCoordinateFrom: mapView)
        closestNode(coordinates: newCoordinate)
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
            switch response.result {
            case .failure( _):
                self.navigationView.instruction.text = "Error connecting to internet"
                self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                self.navigationView.stop()
                self.linelayer.isVisible = false
            case .success:
                let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
                if let arrayOfDicts = dictionary["data"] as! [[[String:Any]]]?{
                    if arrayOfDicts.isEmpty{
                        self.navigationView.instruction.text = "Your marker is not on a hallway"
                        self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                        self.navigationView.stop()
                        self.linelayer.isVisible = false
                    
                    } else {
                        for result in arrayOfDicts {
                            for item in result{
                                let nodes = item["nodes"] as! Array<String>
                                self.drawLine(nodes: nodes)
                            }
                        }
                    }
                } else {
                    //error
                    self.navigationView.instruction.text = "Error fetching from server"
                    self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                    self.navigationView.stop()
                    self.linelayer.isVisible = false
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
                switch response.result {
                case .failure( _):
                    self.navigationView.instruction.text = "Error connecting to server"
                    self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                    self.navigationView.stop()
                    self.linelayer.isVisible = false
                case .success:
                    let propertiesOfNode = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:String]
                    let node: Node = Node(object_passed_in: propertiesOfNode)!
                    coordinatesArray[index] = CLLocationCoordinate2D(latitude: Double(node.latitude)!, longitude: Double(node.longitude)!)
                    noOfElements+=1
                    if (noOfElements == size){
                        let polyline = MGLPolylineFeature(coordinates: coordinatesArray, count: UInt(size))
                        self.polylineSource?.shape = polyline
                        self.linelayer.isVisible = true
                        self.navigationView.confirmLocation.setTitle("Readjust location", for: [])
                        self.navigationView.stop()
                        self.navigationView.instruction.text = "Route to \(self.destination!)"
                    }
                }
            }
        }
    }
    
    func closestNode(coordinates: CLLocationCoordinate2D) {
        // Test code here: to fetch the nearest node
        // TODO: Use the SELECTED NODE for drawing path
        let nearestNodes: Parameters = [
            "query" : "MATCH (n) WHERE abs(toFloat(n.latitude) - {latitude}) < 0.00004694 AND abs(toFloat(n.longitude) + {longitude}) > 0.00012660499 RETURN n",
            "params" : [
                "latitude": coordinates.latitude,
                "longitude": coordinates.longitude
            ]
        ]
        Alamofire.request(cypherURL, method: .post, parameters: nearestNodes, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .failure(_):
                self.navigationView.instruction.text = "Error connecting to internet"
                self.navigationView.confirmLocation.setTitle("Check connection & Re-confirm starting location", for: [])
                self.navigationView.stop()
                self.linelayer.isVisible = false
            case .success:
                var sumOfSquares: Double = 0
                var closestNode: Node = Node()
                let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
                if let arrayOfDicts = dictionary["data"] as! [[[String:Any]]]?{
                    if arrayOfDicts.isEmpty{
                        self.navigationView.instruction.text = "Your marker is not on a hallway"
                        self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                        self.navigationView.stop()
                        self.linelayer.isVisible = false
                    } else {
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
                //get Id
                        self.getPath(start: closestNode.id, end: self.selectedId!)
                    }
                } else {
                    // an error 
                    self.navigationView.instruction.text = "Error fetching from server"
                    self.navigationView.confirmLocation.setTitle("Re-confirm starting location", for: [])
                    self.navigationView.stop()
                    self.linelayer.isVisible = false
                }
            }}
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
        destination = selectedRoom.attribute(forKey: "name") as? String
        cardView.title = destination
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


