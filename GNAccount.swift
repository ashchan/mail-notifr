//
//  GNAccount.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/11.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import KeychainAccess

extension GNAccount {
    @objc func fetchPassword() {
        password = Self.getPassword(account: self)
    }

    @objc static func getPassword(account: GNAccount) -> String {
        let keychain = Keychain(service: GNAccountKeychainServiceName)
        return keychain[string: account.username] ?? ""
    }

    @objc static func setPassword(account: GNAccount, password: String?) {
        let keychain = Keychain(service: GNAccountKeychainServiceName)
        keychain[account.username] = password
    }

}
