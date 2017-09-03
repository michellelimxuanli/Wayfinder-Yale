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
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}


class LocationSearchTable : UITableViewController {
    var matchingItems:[Node] = []
}

extension LocationSearchTable : UISearchResultsUpdating {
    // Called when the search bar's text or scope has changed or when the search bar becomes first responder.

    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController){
        var arrayOfResults:[Node] = []
        let searchBarText = searchController.searchBar.text
        
        let loginData = String(format: "neo4j:password").data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        
        let headers: HTTPHeaders = [
            "Authorization": "Basic \(base64LoginData)",
            "Accept": "application/json"
        ]
        
        if searchBarText!.isEmpty {
            print ("search is empty")
        } else {
        // Find Similar Items
        let parameters: Parameters = [
            "query" : "MATCH (n) WHERE LOWER(n.name) CONTAINS LOWER({searchstring}) RETURN n",
            "params" : [
                "searchstring": searchBarText
            ]
        ]
        
        Alamofire.request("http://127.0.0.1:7474/db/data/cypher", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in

            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any]]]
            for result in arrayOfDicts {
                for item in result{
                    var propertiesOfNode = item["data"] as! [String:Any?]
                    var node: Node = Node(object_passed_in: propertiesOfNode)!
                    arrayOfResults.append(node)
                }
            }
            self.matchingItems = arrayOfResults
            self.tableView.reloadData()

        }
        }
        
        // Get a list of Noces
        let shortestPath: Parameters = [
            "query" : "MATCH path=shortestPath((a:Point {id:{id1}})-[*]-(b:Point {id:{id4}})) RETURN path",
            "params" : [
                        "id1": "1",
                        "id4": "4"
                    ]
        ]
        Alamofire.request("http://127.0.0.1:7474/db/data/cypher", method: .post, parameters: shortestPath, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            

            let dictionary = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:Any]
            let arrayOfDicts = dictionary["data"] as! [[[String:Any?]]]
            for result in arrayOfDicts {
                for item in result{
                    var nodes = item["nodes"] as! Array<String>
                    for URLtoNode in nodes {
                        let propertiesURL = "\(URLtoNode)/properties"
                        Alamofire.request(propertiesURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            let propertiesOfNode = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [String:String]
                            var node: Node = Node(object_passed_in: propertiesOfNode)!
                        }
                    }
            }

            
            }}
        
        
    }
        
        
        // Write code that extracts the right points from the path

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

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    @available(iOS 2.0, *)
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = ""
        return cell
    }
}
