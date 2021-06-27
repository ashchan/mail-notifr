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
    var enabled = true
    var checkInterval = 30
    var notificationEnabled = true
    var notificationSound = ""
    var openInBrowser = Browser.default.rawValue
}

extension Account: Identifiable, Hashable {
    var id: String {
        email
    }

    var baseUrl: String {
        "https://mail.google.com/mail/b/\(email)"
    }

    var browser: Browser {
        Browser(rawValue: openInBrowser) ?? .default
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

extension Notification.Name {
    static let accountsChanged = Notification.Name("accountsChanged")
    static let accountAdded = Notification.Name("accountAdded")
}

extension Accounts: RawRepresentable {
    static let storageKey = "accounts"

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

    static var `default`: Accounts {
        get {
            Accounts(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "[]") ?? []
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
            NotificationCenter.default.post(name: .accountsChanged, object: nil)
        }
    }

    static var hasAccounts: Bool {
        !Self.default.isEmpty
    }
}

extension Accounts {
    var enabled: Accounts {
        filter { $0.enabled }
    }

    func find(email: String) -> Account? {
        first { $0.email == email }
    }

    mutating func save() {
        Self.default = self
    }

    mutating func add(account: Account) {
        if firstIndex(where: { $0.id == account.id }) != nil {
            return
        }
        append(account)
        save()
        NotificationCenter.default.post(name: .accountAdded, object: account)
    }

    mutating func delete(account: Account) {
        guard let index = firstIndex(where: { $0.id == account.id }) else {
            return
        }
        self[index].authorization = nil
        remove(at: index)
        save()
    }

    mutating func update(account: Account) {
        guard let index = firstIndex(where: { $0.id == account.id }) else {
            return
        }
        self[index] = account
        save()
    }

    static func authorize() {
        OAuthClient.shared.authorize() { state in
            switch state {
            case .success(let state):
                let authorization = GTMAppAuthFetcherAuthorization(authState: state)
                var account = Account(email: authorization.userEmail!)
                account.authorization = authorization
                var accounts = Self.default
                accounts.add(account: account)
            case .failure(let error):
                print(error)
            }
        }
    }
}
