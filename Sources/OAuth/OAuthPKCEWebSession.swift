//
//  OAuthPKCEWebSession.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import UIKit
import AuthenticationServices
import Combine

public class OAuthPKCEWebSession: NSObject {
            
    private let getOAuthPKCETokenApi: GetOAuthPKCETokenApi
    private let tokenStorage: OAuthPKCETokenKeychainStorage = OAuthPKCETokenKeychainStorage()
    private let codeChallengeMethod: OAuthPKCECodeChallengeMethod = .s256
    
    private var authorizeWebAuthenticationSession: ASWebAuthenticationSession?
    private var cancellables: Set<AnyCancellable> = Set()
    
    private weak var webSessionPresentingWindow: UIWindow?
        
    let configuration: OAuthPKCEWebSessionConfiguration
    
    public init(configuration: OAuthPKCEWebSessionConfiguration) {
        
        self.configuration = configuration
        self.getOAuthPKCETokenApi = GetOAuthPKCETokenApi(configuration: configuration)
        
        super.init()
    }
    
    public func getCachedAccessToken() -> String? {
        return tokenStorage.getAccessToken()
    }
    
    public func getCachedRefreshToken() -> String? {
        return tokenStorage.getRefreshToken()
    }
    
    public func deleteTokens() {
        
        tokenStorage.deleteToken()
    }
    
    public func authenticate(fromWindow: UIWindow, completion: @escaping ((_ result: Result<OAuthPKCETokenDecodable, Error>) -> Void)) {
        
        authenticatePublisher(fromWindow: fromWindow)
            .sink { (subscriberCompletion: Subscribers.Completion<Error>) in
                
                switch subscriberCompletion {
                
                case .finished:
                    break
                
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { (token: OAuthPKCETokenDecodable) in
                completion(.success(token))
            }
            .store(in: &cancellables)
    }
    
    public func authenticatePublisher(fromWindow: UIWindow) -> AnyPublisher<OAuthPKCETokenDecodable, Error> {
        
        webSessionPresentingWindow = fromWindow
        
        return authorizePublisher()
            .flatMap({ (response: OAuthPKCEAuthorizeResponse) -> AnyPublisher<OAuthPKCETokenDecodable, Error> in
                
                return self.getOAuthPKCETokenApi.getOAuthTokenPublisher(code: response.code, codeVerifier: response.codeVerifier)
                    .eraseToAnyPublisher()
            })
            .flatMap({ (token: OAuthPKCETokenDecodable) -> AnyPublisher<OAuthPKCETokenDecodable, Error> in
                
                self.tokenStorage.storeToken(token: token)
                
                return Just(token).setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    private func authorize(completion: @escaping ((_ result: Result<OAuthPKCEAuthorizeResponse, Error>) -> Void)) {
        
        if let authorizeWebAuthenticationSession = self.authorizeWebAuthenticationSession {
            authorizeWebAuthenticationSession.cancel()
            self.authorizeWebAuthenticationSession = nil
        }
        
        guard let codeVerifier = OAuthPKCECodeVerifier.newCodeVerifier() else {
            let error: Error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate codeVerifier"])
            completion(.failure(error))
            return
        }
        
        guard let codeChallengeS256 = OAuthPKCECodeChallenge.newCodeChallengeS256(codeVerifier: codeVerifier) else {
            let error: Error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate codeChallenge"])
            completion(.failure(error))
            return
        }
        
        guard let url = getAuthorizeUrl(configuration: configuration, codeChallenge: codeChallengeS256, codeChallengeMethod: .s256) else {
            let error: Error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to build authorize url.  Found authorize url with value: \(configuration.oauthAuthorizeUrl)"])
            completion(.failure(error))
            return
        }
                       
        let authorizeWebAuthenticationSession = ASWebAuthenticationSession(url: url, callbackURLScheme: configuration.redirectUri, completionHandler: { [weak self] (url: URL?, error: Error?) in
            
            if let error = error {
                
                completion(.failure(error))
                return
            }
            
            guard let url = url, let code = self?.getCodeFromAuthorizeRedirectUrl(url: url) else {
                
                let error: Error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get code from authorize url: \(url?.absoluteString ?? "empty redirect url")"])
                completion(.failure(error))
                return
            }
            
            let authorizeResponse = OAuthPKCEAuthorizeResponse(
                code: code,
                codeVerifier: codeVerifier
            )
            
            completion(.success(authorizeResponse))
        })
        
        authorizeWebAuthenticationSession.prefersEphemeralWebBrowserSession = configuration.prefersEphemeralWebBrowserSession
       
        authorizeWebAuthenticationSession.presentationContextProvider = self
        
        authorizeWebAuthenticationSession.start()
        
        self.authorizeWebAuthenticationSession = authorizeWebAuthenticationSession
    }
    
    private func authorizePublisher() -> AnyPublisher<OAuthPKCEAuthorizeResponse, Error> {
        
        return Future() { promise in
            
            self.authorize { (result: Result<OAuthPKCEAuthorizeResponse, Error>) in
                
                switch result {
                
                case .success(let authorizeResponse):
                    promise(.success(authorizeResponse))
               
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getCodeFromAuthorizeRedirectUrl(url: URL) -> String? {
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else {
            
            return nil
        }
                
        for queryItem in queryItems {
            
            if queryItem.name == "code" {
                return queryItem.value
            }
        }
        
        return nil
    }
    
    private func getAuthorizeUrl(configuration: OAuthPKCEWebSessionConfiguration, codeChallenge: String, codeChallengeMethod: OAuthPKCECodeChallengeMethod) -> URL? {
        
        let codeChallengeMethodValue: String
        
        switch codeChallengeMethod {
        case .s256:
            codeChallengeMethodValue = "S256"
        }
        
        let url: URL?
        
        if var urlComponents = URLComponents(string: configuration.oauthAuthorizeUrl) {
            
            urlComponents.queryItems = [
                URLQueryItem(name: "client_id", value: configuration.clientId),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: codeChallengeMethodValue),
                URLQueryItem(name: "redirect_uri", value: configuration.redirectUri),
                URLQueryItem(name: "response_type", value: "code")
            ]
            
            url = urlComponents.url
        }
        else {
            
            url = nil
        }
        
        return url
    }
}

extension OAuthPKCEWebSession: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        
        if webSessionPresentingWindow == nil {
            assertionFailure("Found nil presenting window.  A window is required to present the WebAuthenticationSession.")
        }
        
        return webSessionPresentingWindow ?? UIWindow(frame: UIScreen.main.bounds)
    }
}
