//
//  Message.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/23.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation

struct Message {
    let id: String
    let email: String
    let from: String
    let date: String
    let subject: String
    let snippet: String
    let internalDate: TimeInterval

    var sender: String {
        let result = from.split(separator: "<").first ?? Substring(from)
        return result
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: ["\"", "\\"])
    }

    var serverDate: Date {
        Date(timeIntervalSince1970: internalDate / 1000)
    }

    var url: URL {
        Self.url(email: email, id: id)
    }

    static func url(email: String, id: String) -> URL {
        URL(string: "https://mail.google.com/mail/u/\(email)?account_id=\(email)&message_id=\(id)&view=conv&extsrc=atom")!
    }
}
