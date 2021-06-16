//
//  Account.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation

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

typealias Accounts = [Account]

extension Accounts: RawRepresentable {
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
