//
//  OAuthPKCETokenKeychainStorage.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import KeychainPasswordStore

class OAuthPKCETokenKeychainStorage {
    
    private static let keychainService: String = "OAuthPKCETokenKeychainStorage.keychainService.token"
    private static let accessTokenAccount: String = "OAuthPKCETokenKeychainStorage.keychainService.account.accessToken"
    private static let refreshTokenAccount: String = "OAuthPKCETokenKeychainStorage.keychainService.account.refreshToken"
    
    private let keychainPasswordStore: KeychainPasswordStore = KeychainPasswordStore(service: OAuthPKCETokenKeychainStorage.keychainService)
    
    init() {
        
    }
    
    func getAccessToken() -> String? {
        
        return keychainPasswordStore.getPassword(account: OAuthPKCETokenKeychainStorage.accessTokenAccount)
    }
    
    func getRefreshToken() -> String? {
        
        return keychainPasswordStore.getPassword(account: OAuthPKCETokenKeychainStorage.refreshTokenAccount)
    }
    
    func storeToken(token: OAuthPKCETokenDecodable) {
        
        _ = keychainPasswordStore.storePassword(
            account: OAuthPKCETokenKeychainStorage.accessTokenAccount,
            password: token.accessToken,
            overwriteExisting: true
        )
        
        _ = keychainPasswordStore.storePassword(
            account: OAuthPKCETokenKeychainStorage.refreshTokenAccount,
            password: token.refreshToken,
            overwriteExisting: true
        )
    }
    
    func deleteToken() {
        
        _ = keychainPasswordStore.deletePassword(account: OAuthPKCETokenKeychainStorage.accessTokenAccount)
        _ = keychainPasswordStore.deletePassword(account: OAuthPKCETokenKeychainStorage.refreshTokenAccount)
    }
}
