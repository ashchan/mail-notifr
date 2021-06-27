//
//  MessageFetcher.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/23.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail // SWIFT_PACKAGE=1 required, see https://github.com/google/google-api-objectivec-client-for-rest/issues/400

struct MessageFetcher {
    var account: Account

    func fetch() {
        // TODO
    }

    func cleanUp() {
        // TODO
    }

    var lastCheckedAt: Date {
        return Date() // TODO
    }

    private(set) var unreadMessagesCount = 5
    private let maximumMessagesStored = 10

    var messages: [Message] {
        // TODO
        [
            Message(id: "123", email: account.email, subject: "Test message dummy #1", body: "Test message body"),
            Message(id: "223", email: account.email, subject: "Test message dummy #2", body: "Test message body"),
            Message(id: "223", email: account.email, subject: "Test message dummy #3", body: "Test message body"),
        ]
    }
}
