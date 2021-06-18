//
//  SettingsView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/18.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @AppStorage(AppSettings.showUnreadCount) var showUnreadCount = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle(isOn: $launchAtLogin.isEnabled) {
                    Text("Launch at login")
                }
                Spacer()
            }
            HStack {
                Toggle(isOn: $showUnreadCount) {
                    Text("Show unread count in menu bar")
                }
                Spacer()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("General")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
