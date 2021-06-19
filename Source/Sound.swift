//
//  Sound.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/19.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import Foundation
import AppKit

enum Sound: String, Identifiable, CaseIterable {
    case basso
    case blow
    case bottle
    case frog
    case funk
    case glass
    case hero
    case morse
    case ping
    case pop
    case purr
    case sosumi
    case submarine
    case tink

    var id: String {
        rawValue
    }
}

extension Sound {
    var name: String {
        rawValue.capitalized
    }

    var soundName: NSSound.Name {
        NSSound.Name(name)
    }

    var nsSound: NSSound? {
        NSSound(named: soundName)
    }
}
