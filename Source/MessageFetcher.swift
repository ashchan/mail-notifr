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
    static let messagesFetched = Notification.Name("messagesFetched")
}

final class MessageFetcher {
    private var account: Account

    init(account: Account) {
        self.account = account
    }

    // Fetch and store at most `maximumMessagesStored` messages.
    func fetch() {
        fetchUnreadCount()
        fetchMessages()
        lastCheckedAt = Date()
    }

    func cleanUp() {
        // TODO: anything to clean up?
    }

    private(set) var lastCheckedAt = Date()

    private(set) var unreadMessagesCount = 0 {
        didSet {
            NotificationCenter.default.post(name: .unreadCountUpdated, object: account.email)
        }
    }
    private let maximumMessagesStored = 10
    private let defaultLabel = "INBOX"

    private(set) var messages = [Message]() {
        didSet {
            NotificationCenter.default.post(name: .messagesFetched, object: account.email)
        }
    }
}

private extension MessageFetcher {
    func fetchUnreadCount() {
        guard let authorization = account.authorization else {
            return
        }
        let query = GTLRGmailQuery_UsersLabelsGet.query(withUserId: authorization.userEmail ?? "me", identifier: defaultLabel)
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(query) { [weak self] ticket, result, error in
            if let label = result as? GTLRGmail_Label, error == nil {
                self?.unreadMessagesCount = label.messagesUnread?.intValue ?? 0
            }
        }
    }

    func fetchMessages() {
        guard let authorization = account.authorization else {
            return
        }
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: authorization.userEmail ?? "me")
        query.q = "is:unread"
        query.labelIds = [defaultLabel]
        query.maxResults = UInt(maximumMessagesStored)
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(query) { [weak self] ticket, result, error in
            if let list = result as? GTLRGmail_ListMessagesResponse,
               let messages = list.messages {
                self?.fetchMessages(for: messages.compactMap { $0.identifier })
            }
        }
    }

    func fetchMessages(for ids: [String]) {
        guard let authorization = account.authorization else {
            return
        }
        let batchQuery = GTLRBatchQuery()
        for id in ids {
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: authorization.userEmail ?? "me", identifier: id)
            query.fields = "id, snippet, payload(headers)"
            batchQuery.addQuery(query)

        }
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(batchQuery) { [weak self] ticket, result, error in
            if let batchResult = result as? GTLRBatchResult,
               let messages = batchResult.successes as? [String: GTLRGmail_Message] {
                self?.storeMessages(messages.values.map({ $0 }))
            }
        }
    }

    func storeMessages(_ gmailMessages: [GTLRGmail_Message]) {
        // TODO: sort messages
        messages = gmailMessages.map { msg in
            let headers = msg.payload?.headers ?? [GTLRGmail_MessagePartHeader]()
            func findValue(by name: String) -> String {
                headers.first(where: { $0.name == name })?.value ?? ""
            }

            return Message(
                id: msg.identifier ?? "",
                email: account.email,
                from: findValue(by: "From"),
                date: findValue(by: "Date"),
                subject: findValue(by: "Subject"),
                snippet: msg.snippet ?? ""
            )
        }
    }
}
