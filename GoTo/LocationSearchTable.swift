//
//  LocationSearchTable.swift
//  GoTo
//
//  Created by Michelle Lim on 9/2/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import UIKit

class LocationSearchTable : UITableViewController {
    
}

extension LocationSearchTable : UISearchResultsUpdating {
    // Called when the search bar's text or scope has changed or when the search bar becomes first responder.
    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController){

        // The following code is relevant for when the map items come back 
//        guard let mapView = mapView,
//            let searchBarText = searchController.searchBar.text else { return }
//        let request = MKLocalSearchRequest()
//        request.naturalLanguageQuery = searchBarText
//        request.region = mapView.region
//        let search = MKLocalSearch(request: request)
//        search.startWithCompletionHandler { response, _ in
//            guard let response = response else {
//                return
//            }
//            self.matchingItems = response.mapItems
//            self.tableView.reloadData()
//        }
    }
}

extension LocationSearchTable {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = ""
        return cell
    }
}
