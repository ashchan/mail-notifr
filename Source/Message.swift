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
    let subject: String
    let body: String

    var summary: String {
        body // TODO: do not return whole body
    }
}
