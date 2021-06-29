//
//  Browser.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/19.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import AppKit

struct Browser: Identifiable {
    static let safariIdentifier = "com.apple.Safari"

    let identifier: String
    let name: String

    var id: String {
        identifier
    }

    init(identifier: String) {
        self.identifier = identifier
        name = Self.installed[identifier] ?? ""
    }
}

extension Browser {
    var isDefault: Bool {
        return identifier == Self.safariIdentifier
    }

    static var all: [Browser] {
        identifiers.map { Browser(identifier: $0) }
    }

    static var urlsForInstalled: [URL] = {
        LSCopyApplicationURLsForURL(URL(string: "https:")! as CFURL, .viewer)?.takeRetainedValue() as? [URL] ?? []
    }()

    // [identifier: name]
    static var installed: [String: String] = {
        urlsForInstalled.reduce(into: [String: String]()) { result, url in
            if let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier {
                let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? bundle.object(forInfoDictionaryKey: "CFBundleName")
                result[identifier] = name as? String ?? ""
            }
        }
    }()

    // Safari appears first
    static var identifiers: [String] {
        var results = installed.keys.map { $0 }
        results.removeAll { $0 == safariIdentifier }
        return [safariIdentifier] + results
    }
}
