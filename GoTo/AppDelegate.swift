//
//  AppDelegate.swift
//  GoTo
//
//  Created by Michelle Lim on 8/29/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import UIKit
import IndoorAtlas
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        guard kAPIKey.characters.count > 0 || kAPISecret.characters.count > 0 else { print("Configure API key and API secret inside ApiKeys.swift"); return false}
        
        authenticateIALocationManager()
        FirebaseApp.configure()
        
        return true
    }
    
    func authenticateIALocationManager() {
        
        // Get IALocationManager shared instance
        let manager = IALocationManager.sharedInstance()
        
        // Set IndoorAtlas API key and secret
        manager.setApiKey(kAPIKey, andSecret: kAPISecret)
    }


}



