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
        VStack(alignment: .leading) {
            Text(account.email)
                .font(.largeTitle)

            Form {
                HStack {
                    TextField("Check for new mail every", value: $account.checkInterval, formatter: NumberFormatter())
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    Text("minutes")
                }

                Toggle(isOn: $account.notificationEnabled) {
                    Text("Use Notification")
                }

                Picker("Play sound:", selection: $account.notificationSound) {
                   Text(verbatim: "None")
                        .tag("")
                    Divider()
                    ForEach(Sound.allCases) { sound in
                        Text(sound.name)
                    }
                }
                .onChange(of: account.notificationSound) { newValue in
                    if let sound = Sound(rawValue: newValue) {
                        sound.nsSound?.play()
                    }
                }

                Picker("Open in browser:", selection: $account.openInBrowser) {
                    ForEach(Browser.allCases) { browser in
                        Text(browser.name)
                    }
                }

                Toggle(isOn: $account.enabled) {
                    Text("Enable this account")
                }
            }
            .onChange(of: account) { newValue in
                accounts.update(account: newValue)
            }

            Spacer()
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
