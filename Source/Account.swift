//
//  Account.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import GTMAppAuth

struct Account: Codable {
    var email: String
    var enabled: Bool
    var notificationEnabled: Bool
    var notificationSound: String?
    var openInBrowser: String?
}

extension Account: Identifiable, Hashable {
    var id: String {
        email
    }
}

extension Account {
    var authorization: GTMAppAuthFetcherAuthorization? {
        get {
            GTMAppAuthFetcherAuthorization(fromKeychainForName: id)
        }
        set {
            guard let newValue = newValue, newValue.canAuthorize() else {
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: id)
                return
            }
            GTMAppAuthFetcherAuthorization.save(newValue, toKeychainForName: id)
        }
    }
}

// MARK: - Allow persisting accounts to @AppStorage

typealias Accounts = [Account]

extension Accounts: RawRepresentable {
    static let storageKey = "accounts"

    static var hasAccounts: Bool {
        if let value = UserDefaults.standard.string(forKey: storageKey) {
            guard let data = value.data(using: .utf8),
                  let accounts = try? JSONDecoder().decode(Accounts.self, from: data)
            else {
                return false
            }
            return !accounts.isEmpty
        }
        return false
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Accounts.self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
