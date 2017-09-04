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
    
    // Remember the current selected Node or searched Node 
    var selectedNode: Node = Node()
    
    // Remember the current location coordinates 
    var userCoordinates: CLLocationCoordinate2D?
    
    // Remember the current location's annotation
    var currentAnnotation: MGLPointAnnotation?
    
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
        
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
        
        selectedNode.id = "4"
        // Testing a function here: 
        // Takes in Current Location id and Selected Location id and Sets arrayOfCoordinates
        getPath(start: "1", end: selectedNode.id)
        
    }
    
    func getPath(start: String, end: String){
        
        // TODO: Use the SELECTED NODE for drawing path
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
    
    func addCurrentLocation(center: CLLocationCoordinate2D) {
        currentAnnotation = MGLPointAnnotation()
        currentAnnotation?.title = "currentLocation"
        currentAnnotation?.coordinate = center
        mapView.addAnnotation(currentAnnotation!)
        
    }
    func addMarkerAnnotation(center: CLLocationCoordinate2D) {
        let annotation = MyCustomPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
        
    }
    
    func onClick(sender:UIButton!) {
        print("Button Clicked")
        // trigger a method that places a marker on the current location for that very point in time
        addMarkerAnnotation(center: userCoordinates!)
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
    
    // When the view will appear, set up the mapView and its delegate and start requesting location
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        
        // Test Button for the Marker Placement
        addMarkerButton()
        
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
    
//     func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        
//        // Thisis for the Current Location Cirlce
//        guard annotation is MGLPointAnnotation else {
//            return nil
//        }
//        
//        // For better performance, always try to reuse existing annotations.
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "circle")
//        
//        // If there’s no reusable annotation view available, initialize a new one.
//        if annotationView == nil {
//            annotationView = CustomAnnotationView(reuseIdentifier: "circle")
//            annotationView!.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//            
//            // Set the annotation view’s background color to a value determined by its longitude.
//            annotationView!.backgroundColor = UIColor.blue
//        }
//        
//        return annotationView
//    }
    
    // MARK: - MGLMapViewDelegate methods
    
    // This delegate method is where you tell the map to load a view for a specific annotation. To load a static MGLAnnotationImage, you would use `-mapView:imageForAnnotation:`.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        if annotation is MyCustomPointAnnotation {
            // For better performance, always try to reuse existing annotations. To use multiple different annotation views, change the reuse identifier for each.
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") {
                return annotationView
            } else {
                return DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 50)
            }
        }
        else {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "circle") {
                return annotationView
            } else {
                let annotationView = CustomAnnotationView(reuseIdentifier: "circle")
                annotationView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                annotationView.backgroundColor = UIColor.blue
                return annotationView
            }

        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }


// MGLAnnotationView subclass
class DraggableAnnotationView: MGLAnnotationView {
    init(reuseIdentifier: String, size: CGFloat) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        // `isDraggable` is a property of MGLAnnotationView, disabled by default.
        isDraggable = true
        
        // This property prevents the annotation from changing size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Begin setting up the view.
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        backgroundColor = .darkGray
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = size / 2
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
    }
    
    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)
        
        switch dragState {
        case .starting:
            print("Starting", terminator: "")
            startDragging()
        case .dragging:
            print(".", terminator: "")
        case .ending, .canceling:
            print("Ending")
            endDragging()
        case .none:
            return
        }
    }
    
    // When the user interacts with an annotation, animate opacity and scale changes.
    func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)
    }
}
    
    
    // Wait until the map is loaded before adding to the map.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addLayer(to: style)
        addRoomLayer(to: style, vectorSource: "Art Rooms", configURL: "mapbox://ml2445.3us1mnug", sourceLayer: "Art_Rooms-a2rv20")
        addRoomLayer(to: style, vectorSource: "Elevators", configURL: "mapbox://ml2445.96tmc7k0", sourceLayer: "Elevators-7x4njs ")
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
    }
    func addRoomLayer(to style: MGLStyle, vectorSource: String, configURL: String, sourceLayer: String) {
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
    func addMarkerButton() {
        
        let button = UIButton(type: UIButtonType.custom) as UIButton
        
        button.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        button.setTitle("Testing marker placement", for: .normal)
        button.isSelected = true
        button.sizeToFit()
        button.center.x = self.view.center.x
        button.frame = CGRect(origin: CGPoint(x: button.frame.origin.x, y: self.view.frame.size.height - button.frame.size.height - 5), size: button.frame.size)
        button.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    // source: https://www.mapbox.com/ios-sdk/examples/select-layer/

    // TODO: generalize handletap and changeopacity for all layers
    func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["Art Rooms", "Elevators"]))
        
        // TO CHANGE KEY TO ID
        // Get the name of the selected state.
        if let feature = features.first, let state = feature.attribute(forKey: "Art Rooms") as? String{
            changeOpacity(name: state)
        } else {
            changeOpacity(name: "")
        }
    }
    
    //this should apply to all layers
    func changeOpacity(name: String) {
        let layer = mapView.style?.layer(withIdentifier: "Art Rooms") as! MGLFillStyleLayer
        
        // TO CHANGE KEY TO ID
        // Check if a state was selected, then change the opacity of the states that were not selected.
        if name.characters.count > 0 {
            layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "Art Rooms", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
        } else {
            // Reset the opacity for all states if the user did not tap on a state.
            layer.fillOpacity = MGLStyleValue(rawValue: 1)
        }
    }
    
    
}

// MGLAnnotationView subclass
class CustomAnnotationView: MGLAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Animate the border width in/out, creating an iris effect.
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.duration = 0.1
        layer.borderWidth = selected ? frame.width / 4 : 2
        layer.add(animation, forKey: "borderWidth")
    }
}
// MGLPointAnnotation subclass, really, this is just to identify that the
class MyCustomPointAnnotation: MGLPointAnnotation {
    var willUseImage: Bool = false
}
