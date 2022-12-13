//
//  OAuthPKCETokenDecodable.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation

public struct OAuthPKCETokenDecodable: Decodable {
    
    public let accessToken: String
    public let expiresIn: Int
    public let refreshToken: String
    public let scope: String?
    public let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope = "scope"
        case tokenType = "token_type"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
        self.scope = try container.decodeIfPresent(String.self, forKey: .scope)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
    }
}
