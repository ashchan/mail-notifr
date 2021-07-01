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
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(account.email)
                .font(.largeTitle)

            Form {
                HStack {
                    TextField(LocalizedStringKey("Check for new mail every"), value: $account.checkInterval, formatter: NumberFormatter())
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    Text("minutes")
                }

                Toggle(isOn: $account.notificationEnabled) {
                    Text("Use Notification")
                }
                .toggleStyle(.switch)

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
                    ForEach(Browser.all) { browser in
                        Text(browser.name)
                    }
                }

                Toggle(isOn: $account.enabled) {
                    Text("Enable this account")
                }
                .toggleStyle(.switch)
            }
            .onChange(of: account) { newValue in
               update(account: account)
            }

            Spacer()

            HStack {
                Spacer()

                Button {
                    reAuthenticate()
                } label: {
                    Text("Re-authorize")
                }

            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountUpdated)) {
            notification in
            if let updatedAccount = notification.object as? Account {
                if account.id == updatedAccount.id {
                    self.account = updatedAccount
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color("Background"))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete this account from Mail Notifr?"),
                        message: Text("You can add your account again at any time."),
                        primaryButton: .default(Text("Delete")) {
                            self.delete()
                        },
                        secondaryButton: .cancel()
                    )
                }
                Button {
                    reAuthenticate()
                } label: {
                    Image(systemName: "key.icloud")
                }
            }
        }
    }
}

private extension AccountView {
    func update(account: Account) {
        accounts.update(account: account)
    }

    func delete() {
        accounts.delete(account: account)
    }

    func reAuthenticate() {
        Accounts.authorize()
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: Account(email: "ashchan@gmail.com"))
    }
}
