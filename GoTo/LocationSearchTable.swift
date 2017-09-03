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
import UIKit

extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}


class LocationSearchTable : UITableViewController {
    
}

extension LocationSearchTable : UISearchResultsUpdating {
    // Called when the search bar's text or scope has changed or when the search bar becomes first responder.
    
    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController){
        let searchBarText = searchController.searchBar.text
        
        let loginData = String(format: "neo4j:password").data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        
        let headers: HTTPHeaders = [
            "Authorization": "Basic \(base64LoginData)",
            "Accept": "application/json"
        ]
        
//        let parameters: Parameters = [
//            "query" : "MATCH path=shortestPath((a:Point {id:{id1}})-[*]-(b:Point {id:{id4}})) RETURN path",
//            "params" : [
//                "id1": "1",
//                "id4": "4"
//            ]
//        ]
 
        // Find Similar Items
        let parameters: Parameters = [
            "query" : "MATCH (n) WHERE n.name CONTAINS {searchstring} RETURN n",
            "params" : [
                "searchstring": searchBarText
            ]
        ]
        
        Alamofire.request("http://127.0.0.1:7474/db/data/cypher", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in

//            if let json = response.result.value {
//                print("JSON: \(json)") // serialized json response
//            }
            
            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any]]]
            for result in arrayOfDicts {
                for item in result{
                    let node = item
                    print(node)
                }
            }

        }

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

//extension LocationSearchTable {
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return matchingItems.count
//    }
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
//        let selectedItem = matchingItems[indexPath.row].placemark
//        cell.textLabel?.text = selectedItem.name
//        cell.detailTextLabel?.text = ""
//        return cell
//    }
//}
