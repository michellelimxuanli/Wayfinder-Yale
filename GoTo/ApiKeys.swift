//
//  ApiKeys.swift
//  GoTo
//
//  Created by Michelle Lim on 8/29/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import Alamofire

// API keys can be generated at <http://developer.indooratlas.com/applications>
let kAPIKey = "2747db9b-b0db-40cd-9997-87933631fba3"
let kAPISecret = "PkCynHSwy5TNERC8NpN7/g/g3MiZSwy1kBDGeYq4NY5ni8xRHu8gkOI0RyIHAlJGCB0Obp08tdnJYGfobQyAoR5XRyHbnt/nzAn/+5IpGuMyHFblmc0YyIkF12C2SA=="

// Floor plan id is same as "FloorplanId" at the <http://developer.indooratlas.com/venues>
let kFloorplanId = "0bcb0d12-654e-48ae-aa1c-429baafcb0b0"

// Info for Graphene API
let loginData = String(format: "gotouser:b.9FyMRNWzPQda.jHQXK7LZo5IF4ahI").data(using: String.Encoding.utf8)!
let base64LoginData = loginData.base64EncodedString()
let headers: HTTPHeaders = [
    "Authorization": "Basic \(base64LoginData)",
    "Accept": "application/json"
]
