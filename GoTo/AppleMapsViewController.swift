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
    
    var cardView: CustomView!
    
    var selectedId: String?
    
    // Remember the current location coordinates 
    var userCoordinates: CLLocationCoordinate2D?
    
    var styleLayerArray: [String] = ["Art Rooms", "Elevators"]
    
    
    // Remember the current location's annotation
    var currentAnnotation: MGLPointAnnotation?
    var annotation : MyCustomPointAnnotation?
    
    var resultSearchController:UISearchController? = nil
    
    var mapView: MGLMapView!
    var label = UILabel()
    var initial_center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 41.31574, longitude: -72.92562)

    var polylineSource: MGLShapeSource?
        
    // Manager for IALocationManager
    var manager = IALocationManager.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        
        // Show spinner while waiting for location information from IALocationManager
        SVProgressHUD.show(withStatus: NSLocalizedString("Waiting for location data", comment: ""))
        
    }
    
    func getPath(start: String, end: String){
        
        let loginData = String(format: "gotouser:b.9FyMRNWzPQda.jHQXK7LZo5IF4ahI").data(using: String.Encoding.utf8)!
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

        
        Alamofire.request("http://hobby-jhaamkgcjildgbkembihibpl.dbs.graphenedb.com:24789/db/data/cypher", method: .post, parameters: shortestPath, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any?]]]
            for result in arrayOfDicts {
                for item in result{
                    let nodes = item["nodes"] as! Array<String>
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
                            if (noOfElements == nodes.count){
                                let polyline = MGLPolylineFeature(coordinates: coordinatesArray, count: UInt(size))
                                self.polylineSource?.shape = polyline
                            }
                        }
                    }
                }
            }
        }
    }
    
    func closestNode(coordinates: CLLocationCoordinate2D) {
        // Test code here: to fetch the nearest node
        // TODO: Use the SELECTED NODE for drawing path
        let loginData = String(format: "gotouser:b.9FyMRNWzPQda.jHQXK7LZo5IF4ahI").data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        let headers: HTTPHeaders = [
            "Authorization": "Basic \(base64LoginData)",
            "Accept": "application/json"
        ]
        let nearestNodes: Parameters = [
            "query" : "MATCH (n) WHERE abs(toFloat(n.latitude) - {latitude}) < 0.00004694 AND abs(toFloat(n.longitude) + {longitude}) < 0.00012660499 RETURN n",
            "params" : [
                "latitude": coordinates.latitude,
                "longitude": coordinates.longitude
            ]
        ]
        Alamofire.request("http://hobby-jhaamkgcjildgbkembihibpl.dbs.graphenedb.com:24789/db/data/cypher", method: .post, parameters: nearestNodes, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
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
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "circle")
        
        if annotationImage == nil {
            var image = UIImage(named: "circle")!
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
            image = ResizeImage(image: image, targetSize: CGSize(width: 20, height: 20.0))
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "circle")
        }
        
        return annotationImage
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
    // adding the draggable point on the current user location
    func addMarkerAnnotation(center: CLLocationCoordinate2D) {
        annotation = MyCustomPointAnnotation()
        annotation?.coordinate = center
        mapView.addAnnotation(annotation!)
        
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
        
        // we'd probably want to set up constraints here in a real app
        cardView = CustomView(frame: CGRect(
            origin: CGPoint(x: 10, y: UIScreen.main.bounds.height - 80 - 10),
            size: CGSize(width: UIScreen.main.bounds.width - 20, height: 80)
        ))
        cardView.delegate = self
        view.addSubview(cardView)
        cardView.isHidden = true

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
    
    func didPressButton(button:UIButton) {
        addMarkerAnnotation(center: userCoordinates!)
        getPath(start: "1", end: selectedId!)
    }
    
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
            return nil
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
            startDragging()
        case .dragging:
            print(".")
        case .ending, .canceling:
            endDragging()
        //closestNode(annotation?.coordinate)
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
        addRoomLayer(to: style, vectorSource: "Art Rooms", configURL: "mapbox://ml2445.dtmpr3x3", sourceLayer: "Art_Rooms_V3-97bs8y")
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
    
    func zoomToFeature(feature: MGLFeature){
        if let dictionary = feature.geoJSONDictionary() as? [String: Any] {
            let geometry = dictionary["geometry"] as? [String: Any]
            let coordinates = geometry?["coordinates"] as? [[[Any]]]
            let arrayOfArray = coordinates?[0][0] as? [Double]
            let centerOfSelected = CLLocationCoordinate2D(latitude: arrayOfArray![1], longitude: arrayOfArray![0])
            //Zoom into the coordinates here
            mapView.setCenter(centerOfSelected, zoomLevel: 18, animated: true)
        }
    }
    
    // source: https://www.mapbox.com/ios-sdk/examples/select-layer/

    // TODO: generalize handletap and changeopacity for all layers
    func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(styleLayerArray))
        
        // Get the name of the selected state.
        if let feature = features.first, let state = feature.attribute(forKey: "id") as? String , let layername = feature.attribute(forKey: "category") as? String{
            cardView.isHidden  = false
            cardView.title = feature.attribute(forKey: "name") as? String
            selectedId = feature.attribute(forKey: "id") as? String
            changeOpacity(name: state, layername:layername)
            zoomToFeature(feature: feature)
        } else {
            changeOpacity(name: "", layername: "")
        }
    }
    
    //this should apply to all layers
    func changeOpacity(name: String, layername: String) {
        // layer is present
        if let layer = mapView.style?.layer(withIdentifier: layername) as! MGLFillStyleLayer? {
            // Check if a state was selected, then change the opacity of the states that were not selected.
            if name.characters.count > 0 {
                for eachLayerName in styleLayerArray {
                    if (eachLayerName == layername) {
                        layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "id", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0.5)])
                    } else {
                        if let eachLayer = mapView.style?.layer(withIdentifier: eachLayerName) as! MGLFillStyleLayer? {
                            eachLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
                        }
                    }
                }
            
            } else {
                // Reset the opacity for all states if the user did not tap on a state.
                cardView.isHidden = true
                layer.fillOpacity = MGLStyleValue(rawValue: 0.5)
            }
        } else {
            cardView.isHidden = true
            for eachLayerName in styleLayerArray {
                if let eachLayer = mapView.style?.layer(withIdentifier: eachLayerName) as! MGLFillStyleLayer? {
                    eachLayer.fillOpacity = MGLStyleValue(rawValue: 0.5)
                }
            }
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

//from https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage{
    UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
    image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: targetSize.width, height: targetSize.height)))
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
}

extension AppleMapsViewController: HandleMapSearch {
    func dropPinZoomIn(selectedRoom:MGLFeature){
        changeOpacity(name: (selectedRoom.attribute(forKey: "id") as? String)!, layername: (selectedRoom.attribute(forKey: "category") as? String)!)
        cardView.title = selectedRoom.attribute(forKey: "name") as? String
        cardView.isHidden = false
        zoomToFeature(feature: selectedRoom)
    }
}


