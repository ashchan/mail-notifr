//
//  AccountView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct AccountView: View {
    @AppStorage(Accounts.storageKey) var accounts = Accounts()
    @State var account: Account

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 10) {
                Text(account.email)
                    .font(.largeTitle)

                Toggle(isOn: $account.enabled) {
                    Text("Enable this account")
                }

                Toggle(isOn: $account.notificationEnabled) {
                    Text("Use Notification")
                }

                HStack {
                    Text("Check for new mail every")
                    TextField("Check interval", value: $account.checkInterval, formatter: NumberFormatter())
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                    Text("minutes")
                }

                HStack {
                    Text("Play sound:")
                        .frame(minWidth: 0.4 * geometry.size.width, alignment: .trailing)
                    Picker("Play sound:", selection: $account.notificationSound) {
                       Text(verbatim: "None")
                            .tag("")
                        Divider()
                        ForEach(Sound.allCases) { sound in
                            Text(sound.name)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: account.notificationSound) { newValue in
                        if let sound = Sound(rawValue: newValue) {
                            sound.nsSound?.play()
                        }
                    }
                }

                HStack {
                    Text("Open in browser:")
                        .frame(minWidth: 0.4 * geometry.size.width, alignment: .trailing)
                    Picker("Open in browser:", selection: $account.openInBrowser) {
                        ForEach(Browser.allCases) { browser in
                            Text(browser.name)
                        }
                    }
                    .labelsHidden()
                }

                Spacer()

                HStack {
                    Spacer()
                    Button("Save") {
                        // TODO
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color.white)
        .toolbar {
            Button(action: delete) {
                Image(systemName: "trash")
            }
        }
    }
}

private extension AccountView {
    func delete() {
        // TODO
        //   * confirmation alert
        //   * stop checker
        accounts.delete(account: account)
   }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: Account(email: "ashchan@gmail.com"))
    }
}
