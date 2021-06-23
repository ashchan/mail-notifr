//
//  MessageFetcher.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/23.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation

struct MessageFetcher {
    var account: Account

    func fetch() {
        // TODO
    }

    var lastCheckedAt: Date {
        return Date() // TODO
    }

    var messages: [Message] {
        // TODO
        [
            Message(id: "123", email: account.email, subject: "Test message dummy #1", body: "Test message body"),
            Message(id: "223", email: account.email, subject: "Test message dummy #2", body: "Test message body"),
            Message(id: "223", email: account.email, subject: "Test message dummy #3", body: "Test message body"),
        ]
    }

    var messagesCount: Int {
        messages.count
    }
}
