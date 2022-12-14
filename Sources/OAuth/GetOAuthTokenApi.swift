//
//  GetOAuthTokenApi.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import RequestOperation
import Combine

public class GetOAuthTokenApi {
    
    private let configuration: OAuthWebSessionConfiguration
    
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
    
    public init(configuration: OAuthWebSessionConfiguration) {
                
        self.configuration = configuration
    }
    
    private func getOAuthTokenRequest(code: String, codeVerifier: String) -> URLRequest {
        
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
    
    public func getOAuthTokenPublisher(code: String, codeVerifier: String) -> AnyPublisher<OAuthTokenDecodable, Error> {
        
        let urlRequest: URLRequest = getOAuthTokenRequest(code: code, codeVerifier: codeVerifier)
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap {
                
                let httpStatusCode: Int? = ($0.response as? HTTPURLResponse)?.statusCode
                
                guard let httpStatusCode = httpStatusCode else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get http status code"])
                }
                
                let isSuccessHttpStatusCode: Bool = httpStatusCode >= 200 && httpStatusCode < 400
                                                
                guard isSuccessHttpStatusCode else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed with http status code: \(httpStatusCode)"])
                }
                
                return $0.data
            }
            .decode(type: OAuthTokenDecodable.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
