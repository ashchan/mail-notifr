//
//  MessageFetcher.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/23.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Gmail // SWIFT_PACKAGE=1 required, see https://github.com/google/google-api-objectivec-client-for-rest/issues/400

extension Notification.Name {
    static let unreadCountUpdated = Notification.Name("unreadCountUpdated")
    static let messagesFetched = Notification.Name("messagesFetched")
}

final class MessageFetcher: NSObject {
    var account: Account
    private var authorization: GTMAppAuthFetcherAuthorization? {
        didSet {
            authorization?.authState.stateChangeDelegate = self
        }
    }
    private var timer: Timer?
    private(set) var hasAuthError = false

    private(set) var lastCheckedAt = Date()
    private var newestMessageDate = Date().addingTimeInterval(-24 * 60 * 60)
    private(set) var hasNewMessages = false

    private(set) var unreadMessagesCount = 0 {
        didSet {
            NotificationCenter.default.post(name: .unreadCountUpdated, object: account.email)
        }
    }
    private let maximumMessagesStored = 10
    private let defaultLabel = "INBOX"

    private(set) var messages = [Message]() {
        didSet {
            if let newestMessage = messages.first {
                hasNewMessages = newestMessage.serverDate > newestMessageDate
                newestMessageDate = newestMessage.serverDate
            } else {
                hasNewMessages = false
            }
            NotificationCenter.default.post(name: .messagesFetched, object: account.email)
        }
    }

    init(account: Account) {
        self.account = account
    }

    // Fetch and store at most `maximumMessagesStored` messages.
    @objc func fetch() {
        reschedule()

        authorization = account.authorization
        if authorization != nil {
            hasAuthError = false
            fetchUnreadCount()
            fetchMessages()
            lastCheckedAt = Date()
        } else {
            hasAuthError = true
            unreadMessagesCount = 0
            messages = []
        }
    }

    func reschedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: account.checkInterval * 60,
            target: self,
            selector: #selector(fetch),
            userInfo: nil,
            repeats: false
        )
    }

    func cleanUp() {
        timer?.invalidate()
        authorization?.authState.stateChangeDelegate = nil
    }
}

extension MessageFetcher: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        account.authorization = GTMAppAuthFetcherAuthorization(authState: state)
        authorization = account.authorization
    }
}

private extension MessageFetcher {
    func fetchUnreadCount() {
        guard let authorization = authorization, !hasAuthError else {
            return
        }
        let query = GTLRGmailQuery_UsersLabelsGet.query(withUserId: authorization.userEmail ?? "me", identifier: defaultLabel)
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(query) { [weak self] ticket, result, error in
            if let label = result as? GTLRGmail_Label, error == nil {
                self?.unreadMessagesCount = label.messagesUnread?.intValue ?? 0
            } else {
                self?.hasAuthError = true
            }
        }
    }

    func fetchMessages() {
        guard let authorization = authorization, !hasAuthError else {
            return
        }
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: authorization.userEmail ?? "me")
        query.q = "is:unread"
        query.labelIds = [defaultLabel]
        query.maxResults = UInt(maximumMessagesStored)
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(query) { [weak self] ticket, result, error in
            if let list = result as? GTLRGmail_ListMessagesResponse, error == nil {
                if let messages = list.messages {
                    self?.fetchMessages(for: messages.compactMap { $0.identifier })
                } else {
                    // list.resultSizeEstimate == 0
                    self?.storeMessages([])
                }
            } else {
                self?.hasAuthError = true
            }
        }
    }

    func fetchMessages(for ids: [String]) {
        guard let authorization = authorization, !hasAuthError else {
            return
        }
        let batchQuery = GTLRBatchQuery()
        for id in ids {
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: authorization.userEmail ?? "me", identifier: id)
            query.fields = "id, snippet, payload(headers), internalDate"
            batchQuery.addQuery(query)

        }
        let service = GTLRGmailService()
        service.authorizer = authorization
        service.executeQuery(batchQuery) { [weak self] ticket, result, error in
            if let batchResult = result as? GTLRBatchResult,
               let messages = batchResult.successes as? [String: GTLRGmail_Message] {
                self?.storeMessages(messages.values.map({ $0 }))
            } else {
                self?.hasAuthError = true
            }
        }
    }

    func storeMessages(_ gmailMessages: [GTLRGmail_Message]) {
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
                snippet: msg.snippet ?? "",
                internalDate: msg.internalDate?.doubleValue ?? 0
            )
        }
        .sorted(by: { $0.internalDate > $1.internalDate })
    }
}
