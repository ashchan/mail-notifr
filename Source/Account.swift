//
//  Account.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import GTMAppAuth
import KeychainAccess

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

    var sound: Sound? {
        Sound(rawValue: notificationSound)
    }
}

extension Account {
    var keychain: Keychain {
        Keychain(service: "com.ashchan.GmailNotifr")
    }

    var authorization: GTMAppAuthFetcherAuthorization? {
        get {
            if let data = keychain[data: id] {
                return try? NSKeyedUnarchiver.unarchivedObject(ofClass: GTMAppAuthFetcherAuthorization.self, from: data)
            }
            return nil
        }
        set {
            guard let newValue = newValue, newValue.canAuthorize() else {
                keychain[id] = nil
                return
            }
            let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
            keychain[data: id] = data
        }
    }
}

// MARK: - Allow persisting accounts to @AppStorage

typealias Accounts = [Account]

extension Notification.Name {
    static let accountAdded = Notification.Name("accountAdded")
    static let accountDeleted = Notification.Name("accountDeleted")
    static let accountUpdated = Notification.Name("accountUpdated")
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

    static func needsImmediateFetching(oldValue: Account, newValue: Account) -> Bool {
        newValue.enabled && !oldValue.enabled
    }

    static func needsReschduling(oldValue: Account, newValue: Account) -> Bool {
        newValue.checkInterval != oldValue.checkInterval
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
        NotificationCenter.default.post(name: .accountDeleted, object: account)
    }

    mutating func update(account: Account) {
        guard let index = firstIndex(where: { $0.id == account.id }) else {
            return
        }
        let needsRescheduling = Self.needsReschduling(oldValue: self[index], newValue: account)
        let needsImmediateFetching = Self.needsImmediateFetching(oldValue: self[index], newValue: account)
        self[index] = account
        save()
        NotificationCenter.default.post(
            name: .accountUpdated,
            object: account,
            userInfo: ["needsRescheduling": needsRescheduling, "needsImmediateFetching": needsImmediateFetching]
        )
    }

    static func authorize() {
        OAuthClient.shared.authorize() { state in
            switch state {
            case .success(let state):
                let authorization = GTMAppAuthFetcherAuthorization(authState: state)
                if var account = Self.default.find(email: authorization.userEmail!) {
                    account.authorization = authorization
                    var accounts = Self.default
                    accounts.update(account: account)
                } else {
                    var account = Account(email: authorization.userEmail!)
                    account.authorization = authorization
                    var accounts = Self.default
                    accounts.add(account: account)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
