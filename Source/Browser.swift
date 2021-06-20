//
//  Browser.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/19.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation

enum Browser: String, Identifiable, CaseIterable {
    case `default` = ""
    case safari
    case chrome
    case firefox
    case edge

    var id: String {
        rawValue
    }

    var identifier: String {
        switch self {
        case .safari:
            return "com.apple.Safari"
        case .chrome:
            return "com.google.Chrome"
        case .firefox:
            return "org.mozilla.firefox"
        case .edge:
            return "com.microsoft.edgemac"
        default:
            return ""
        }
    }

    var name: String {
        switch self {
        case .safari:
            return "Safari"
        case .chrome:
            return "Google Chrome"
        case .firefox:
            return "Firefox"
        case .edge:
            return "Microsoft Edge"
        default:
            return "Default"
        }
    }
}

extension Browser {
    var isDefault: Bool {
        self == .default
    }
}
