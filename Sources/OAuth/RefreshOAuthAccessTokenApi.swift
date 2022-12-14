//
//  RefreshOAuthAccessTokenApi.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import RequestOperation
import Combine

public class RefreshOAuthAccessTokenApi {
    
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
    
    private func getRefreshOAuthAccessTokenRequest(refreshToken: String) -> URLRequest {
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri),
            URLQueryItem(name: "refresh_token", value: refreshToken)
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
    
    public func refreshOAuthAccessTokenPublisher(refreshToken: String) -> AnyPublisher<OAuthTokenDecodable, Error> {
        
        let urlRequest: URLRequest = getRefreshOAuthAccessTokenRequest(refreshToken: refreshToken)
        
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
