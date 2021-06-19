//
//  OAuthClient.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/17.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppAuth
import GTMAppAuth

struct OAuthClient {
    private init() {}
    static let shared = OAuthClient()

    static let clientID = "270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k.apps.googleusercontent.com"
    static let clientSecret = OAuthSecret.secret
    static let redirectURL = "com.googleusercontent.apps.270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k:/oauthredirect"

    static var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func resumeAuthFlow(url: URL) {
        if let currentFlow = Self.currentAuthorizationFlow, currentFlow.resumeExternalUserAgentFlow(with: url) {
            Self.currentAuthorizationFlow = nil
        }
    }

    func authorize(_ authorized: @escaping (Result<OIDAuthState, Error>) -> Void) {
        let request = OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: Self.clientID,
            clientSecret: Self.clientSecret,
            scopes: [OIDScopeEmail, "https://www.googleapis.com/auth/gmail.readonly"],
            redirectURL: URL(string: Self.redirectURL)!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        Self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request) { state, error in
           if let state = state {
               authorized(.success(state))
           } else {
               authorized(.failure(error ?? AuthError(message: "Auth with Google failed.")))
           }
        }
    }

    struct AuthError: LocalizedError {
        var message: String
    }
}
