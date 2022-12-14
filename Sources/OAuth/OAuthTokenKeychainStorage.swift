//
//  OAuthTokenKeychainStorage.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import Foundation
import KeychainPasswordStore

class OAuthTokenKeychainStorage {
    
    private static let keychainService: String = "OAuthTokenKeychainStorage.keychainService.token"
    private static let accessTokenAccount: String = "OAuthTokenKeychainStorage.keychainService.account.accessToken"
    private static let refreshTokenAccount: String = "OAuthTokenKeychainStorage.keychainService.account.refreshToken"
    
    private let keychainPasswordStore: KeychainPasswordStore = KeychainPasswordStore(service: OAuthTokenKeychainStorage.keychainService)
    
    init() {
        
    }
    
    func getAccessToken() -> String? {
        
        return keychainPasswordStore.getPassword(account: OAuthTokenKeychainStorage.accessTokenAccount)
    }
    
    func getRefreshToken() -> String? {
        
        return keychainPasswordStore.getPassword(account: OAuthTokenKeychainStorage.refreshTokenAccount)
    }
    
    func storeToken(token: OAuthTokenDecodable) {
        
        _ = keychainPasswordStore.storePassword(
            account: OAuthTokenKeychainStorage.accessTokenAccount,
            password: token.accessToken,
            overwriteExisting: true
        )
        
        _ = keychainPasswordStore.storePassword(
            account: OAuthTokenKeychainStorage.refreshTokenAccount,
            password: token.refreshToken,
            overwriteExisting: true
        )
    }
    
    func deleteToken() {
        
        _ = keychainPasswordStore.deletePassword(account: OAuthTokenKeychainStorage.accessTokenAccount)
        _ = keychainPasswordStore.deletePassword(account: OAuthTokenKeychainStorage.refreshTokenAccount)
    }
}
