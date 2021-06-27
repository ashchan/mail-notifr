//
//  MessageFetcher.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/23.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail // SWIFT_PACKAGE=1 required, see https://github.com/google/google-api-objectivec-client-for-rest/issues/400

extension Notification.Name {
    static let unreadCountUpdated = Notification.Name("unreadCountUpdated")
}

final class MessageFetcher {
    private var account: Account

    init(account: Account) {
        self.account = account
    }

    // Fetch and store at most `maximumMessagesStored` messages.
    func fetch() {
        fetchUnreadCount()
        // TODO
    }

    func cleanUp() {
        // TODO
    }

    var lastCheckedAt: Date {
        return Date() // TODO
    }

    private(set) var unreadMessagesCount = 5 {
        didSet {
            NotificationCenter.default.post(name: .unreadCountUpdated, object: account.email)
        }
    }
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

private extension MessageFetcher {
    func fetchUnreadCount() {
        guard let authorization = account.authorization else {
            return
        }
        let query = GTLRGmailQuery_UsersLabelsGet.query(withUserId: authorization.userEmail ?? "me", identifier: "INBOX")
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(query) { [weak self] ticket, result, error in
            if let label = result as? GTLRGmail_Label, error == nil {
                self?.unreadMessagesCount = label.messagesUnread?.intValue ?? 0
            }
        }
    }
}
