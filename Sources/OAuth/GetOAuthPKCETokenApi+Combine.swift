//
//  GetOAuthPKCETokenApi+Combine.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import Combine

extension GetOAuthPKCETokenApi {
    
    public func getOAuthTokenPublisher(code: String, codeVerifier: String) -> AnyPublisher<OAuthPKCETokenDecodable, Error> {
        
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
            .decode(type: OAuthPKCETokenDecodable.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
