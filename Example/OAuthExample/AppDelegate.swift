//
//  AppDelegate.swift
//  OAuthExample
//
//  Created by Levi Eggert on 12/15/22.
//

import UIKit
import OAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var configuration: OAuthWebSessionConfiguration = {
        OAuthWebSessionConfiguration(
            clientId: "jN7nBLI9_H_yIZhcN4yk6hnSjc8i0adFnmy6SR38dps",
            oauthAuthorizeUrl: "https://api.stage.mpdx.org/oauth/authorize",
            oauthTokenRequestUrl: "https://api.stage.mpdx.org/oauth/token",
            prefersEphemeralWebBrowserSession: false,
            redirectUri: "org.mpdx.mobile:/auth"
        )
    }()
    
    private lazy var oauthWebSession: OAuthWebSession = {
       
        OAuthWebSession(configuration: configuration)
    }()
    
    private let navigationController: UINavigationController = UINavigationController()
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // window
        let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
                
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        guard let window = self.window else {
            return
        }
        
        oauthWebSession.authenticate(fromWindow: window) { (result: Result<OAuthTokenDecodable, Error>) in
            
            print(result)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    
    }
}

