//
//  GetOAuthPKCETokenApi.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import RequestOperation

public class GetOAuthPKCETokenApi {
    
    private let configuration: OAuthPKCEWebSessionConfiguration
    
    lazy var session: URLSession = {
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        configuration.urlCache = nil
        
        configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        
        configuration.timeoutIntervalForRequest = 60
        
        return URLSession(configuration: configuration)
    }()
    
    public init(configuration: OAuthPKCEWebSessionConfiguration) {
                
        self.configuration = configuration
    }
    
    func getOAuthTokenRequest(code: String, codeVerifier: String) -> URLRequest {
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri)
        ]
        
        return RequestBuilder().build(
            session: session,
            urlString: configuration.oauthTokenRequestUrl,
            method: RequestMethod.post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            httpBody: nil,
            queryItems: queryItems
        )
    }
}
