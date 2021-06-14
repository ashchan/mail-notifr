//
//  GNPreferences.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/11.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import LaunchAtLogin

extension GNPreferences {
    @objc var launchAtLogin: Bool {
        set {
            LaunchAtLogin.isEnabled = newValue
        }
        get {
            LaunchAtLogin.isEnabled
        }
    }
}
