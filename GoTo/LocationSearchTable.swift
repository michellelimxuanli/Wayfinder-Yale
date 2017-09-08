//
//  LocationSearchTable.swift
//  GoTo
//
//  Created by Michelle Lim on 9/2/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Mapbox

extension String {
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}


class LocationSearchTable : UITableViewController {
    var matchingItems:[MGLFeature] = []
    var handleMapSearchDelegate:HandleMapSearch? = nil
    var styleLayerArray: [String] = ["Art Rooms", "Elevators"]
    var mapView: MGLMapView!
}

extension LocationSearchTable : UISearchResultsUpdating {
    // Called when the search bar's text or scope has changed or when the search bar becomes first responder.

    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController){
        var arrayOfResults:[MGLFeature] = []
        let searchBarText = searchController.searchBar.text
        
        if searchBarText!.isEmpty {
        } else {
            let boundedRect:CGRect = mapView.convert(MGLCoordinateBoundsMake(CLLocationCoordinate2D(latitude:41.31521, longitude: -72.92666), CLLocationCoordinate2D(latitude:41.31621, longitude:-72.92475)), toRectTo: mapView)
            let allVisibleFeatures: [MGLFeature] = mapView.visibleFeatures(in: boundedRect, styleLayerIdentifiers: Set(styleLayerArray))
            for feature in allVisibleFeatures {
                if let state = feature.attribute(forKey: "name") as? String{
                    if state.contains(searchBarText!){
                        arrayOfResults.append(feature)
                    }
                }
            }

            self.matchingItems = arrayOfResults
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    @available(iOS 2.0, *)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.attribute(forKey: "name") as? String
        cell.detailTextLabel?.text = ""
        return cell
    }
}

extension LocationSearchTable {
    @available(iOS 2.0, *)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row]
        handleMapSearchDelegate?.dropPinZoomIn(selectedRoom: selectedItem)
        dismiss(animated: true, completion: nil)
    }
}
