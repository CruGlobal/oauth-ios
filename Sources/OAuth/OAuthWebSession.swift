//
//  OAuthWebSession.swift
//  OAuth
//
//  Created by Levi Eggert on 12/13/22.
//  Copyright © 2022 Cru Global, Inc. All rights reserved.
//

import UIKit
import AuthenticationServices
import Combine

public class OAuthWebSession: NSObject {
            
    private let getOAuthTokenApi: GetOAuthTokenApi
    private let refreshOAuthAccessTokenApi: RefreshOAuthAccessTokenApi
    private let tokenStorage: OAuthTokenKeychainStorage = OAuthTokenKeychainStorage()
    private let codeChallengeMethod: OAuthCodeChallengeMethod = .s256
    
    private var authorizeWebAuthenticationSession: ASWebAuthenticationSession?
    private var cancellables: Set<AnyCancellable> = Set()
    
    private weak var webSessionPresentingWindow: UIWindow?
        
    let configuration: OAuthWebSessionConfiguration
    
    public init(configuration: OAuthWebSessionConfiguration) {
        
        self.configuration = configuration
        self.getOAuthTokenApi = GetOAuthTokenApi(configuration: configuration)
        self.refreshOAuthAccessTokenApi = RefreshOAuthAccessTokenApi(configuration: configuration)
        
        super.init()
    }
    
    public func getCachedAccessToken() -> String? {
        return tokenStorage.getAccessToken()
    }
    
    public func getCachedRefreshToken() -> String? {
        return tokenStorage.getRefreshToken()
    }
}

// MARK: - Revoke

extension OAuthWebSession {
    
    public func revoke() {
        
        tokenStorage.deleteToken()
        
        // TODO: There should be an api endpoint to revoke as well. ~Levi
    }
}

// MARK: - Authenticate

extension OAuthWebSession {
    
    public func renewAccessTokenElseAuthenticate(fromWindow: UIWindow, completion: @escaping ((_ result: Result<OAuthTokenDecodable, Error>) -> Void)) {
        
        if let refreshToken = getCachedRefreshToken() {
            
            renewAccessToken(refreshToken: refreshToken, completion: completion)
        }
        else {
            
            authenticate(fromWindow: fromWindow, completion: completion)
        }
    }
    
    public func renewAccessToken(refreshToken: String, completion: @escaping ((_ result: Result<OAuthTokenDecodable, Error>) -> Void)) {
        
        renewAccessTokenPublisher(refreshToken: refreshToken)
            .sink { completed in
                
                switch completed {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { (token: OAuthTokenDecodable) in
                completion(.success(token))
            }
            .store(in: &cancellables)
    }
    
    public func renewAccessTokenPublisher(refreshToken: String) -> AnyPublisher<OAuthTokenDecodable, Error> {
        
        return refreshOAuthAccessTokenApi.refreshOAuthAccessTokenPublisher(refreshToken: refreshToken)
            .flatMap({ (token: OAuthTokenDecodable) -> AnyPublisher<OAuthTokenDecodable, Error> in
                
                self.tokenStorage.storeToken(token: token)
                
                return Just(token).setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    public func authenticate(fromWindow: UIWindow, completion: @escaping ((_ result: Result<OAuthTokenDecodable, Error>) -> Void)) {
        
        authenticatePublisher(fromWindow: fromWindow)
            .sink { (subscriberCompletion: Subscribers.Completion<Error>) in
                
                switch subscriberCompletion {
                
                case .finished:
                    break
                
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { (token: OAuthTokenDecodable) in
                completion(.success(token))
            }
            .store(in: &cancellables)
    }
    
    public func authenticatePublisher(fromWindow: UIWindow) -> AnyPublisher<OAuthTokenDecodable, Error> {
        
        webSessionPresentingWindow = fromWindow
        
        return authorizePublisher()
            .flatMap({ (response: OAuthAuthorizeResponse) -> AnyPublisher<OAuthTokenDecodable, Error> in
                
                return self.getOAuthTokenApi.getOAuthTokenPublisher(code: response.code, codeVerifier: response.codeVerifier)
                    .eraseToAnyPublisher()
            })
            .flatMap({ (token: OAuthTokenDecodable) -> AnyPublisher<OAuthTokenDecodable, Error> in
                
                self.tokenStorage.storeToken(token: token)
                
                return Just(token).setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Authorize With ASWebAuthenticationSession

extension OAuthWebSession {
    
    private func authorize(completion: @escaping ((_ result: Result<OAuthAuthorizeResponse, Error>) -> Void)) {
        
        if let authorizeWebAuthenticationSession = self.authorizeWebAuthenticationSession {
            authorizeWebAuthenticationSession.cancel()
            self.authorizeWebAuthenticationSession = nil
        }
        
        guard let codeVerifier = OAuthCodeVerifier.newCodeVerifier() else {
            let error: Error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate codeVerifier"])
            completion(.failure(error))
            return
        }
        
        guard let codeChallengeS256 = OAuthCodeChallenge.newCodeChallengeS256(codeVerifier: codeVerifier) else {
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
            
            let authorizeResponse = OAuthAuthorizeResponse(
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
    
    private func authorizePublisher() -> AnyPublisher<OAuthAuthorizeResponse, Error> {
        
        return Future() { promise in
            
            self.authorize { (result: Result<OAuthAuthorizeResponse, Error>) in
                
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
    
    private func getAuthorizeUrl(configuration: OAuthWebSessionConfiguration, codeChallenge: String, codeChallengeMethod: OAuthCodeChallengeMethod) -> URL? {
        
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

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthWebSession: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        
        if webSessionPresentingWindow == nil {
            assertionFailure("Found nil presenting window.  A window is required to present the WebAuthenticationSession.")
        }
        
        return webSessionPresentingWindow ?? UIWindow(frame: UIScreen.main.bounds)
    }
}
