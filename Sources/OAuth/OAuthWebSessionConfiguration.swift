//
//  OAuthWebSessionConfiguration.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation

public class OAuthWebSessionConfiguration {
    
    public let callbackUrlScheme: String
    public let clientId: String
    public let oauthAuthorizeUrl: String
    public let oauthTokenRequestUrl: String
    public let prefersEphemeralWebBrowserSession: Bool
    public let redirectUri: String
    
    public init(callbackUrlScheme: String, clientId: String, oauthAuthorizeUrl: String, oauthTokenRequestUrl: String, prefersEphemeralWebBrowserSession: Bool = false, redirectUri: String) {
        
        self.callbackUrlScheme = callbackUrlScheme
        self.clientId = clientId
        self.oauthAuthorizeUrl = oauthAuthorizeUrl
        self.oauthTokenRequestUrl = oauthTokenRequestUrl
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.redirectUri = redirectUri
    }
}
