//
//  OAuthPKCEAuthorizeResponse.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation

public struct OAuthPKCEAuthorizeResponse {
    
    public let code: String
    public let codeVerifier: String
}
