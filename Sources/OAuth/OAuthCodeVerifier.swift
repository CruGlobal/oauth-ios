//
//  OAuthCodeVerifier.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import OktaOidc

public class OAuthCodeVerifier {
    
    public static func newCodeVerifier() -> String? {
        
        return OKTAuthorizationRequest.generateCodeVerifier()
    }
}
