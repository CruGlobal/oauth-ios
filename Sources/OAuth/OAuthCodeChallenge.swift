//
//  OAuthCodeChallenge.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import OktaOidc

public class OAuthCodeChallenge {
    
    public static func newCodeChallengeS256(codeVerifier: String) -> String? {
        
        return OKTAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
    }
}
