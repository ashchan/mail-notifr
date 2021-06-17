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
    static let clientID = "270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k.apps.googleusercontent.com"
    #warning("Protect client secret!")
    static let clientSecret = ""
    static let redirectURL = "com.googleusercontent.apps.270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k:/oauthredirect"

    static var currentAuthorizationFlow: OIDExternalUserAgentSession?

    static func resumeAuthFlow(url: URL) {
        if let currentFlow = currentAuthorizationFlow, currentFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
        }
    }

    static func authorize(_ authorized: @escaping (Result<OIDAuthState, Error>) -> Void) {
        let request = OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [OIDScopeEmail, "https://www.googleapis.com/auth/gmail.readonly"],
            redirectURL: URL(string: redirectURL)!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request) { state, error in
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
