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
    @State private var showingOAuthPrompt = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(account.email)
                .font(.largeTitle)

            Form {
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
                   Text(verbatim: "Default Browser")
                        .tag("")
                    Divider()
                    ForEach(Browser.all) { browser in
                        Text(browser.name)
                    }
                }

                Toggle(isOn: $account.enabled) {
                    Text("Enable this account")
                }
                .toggleStyle(.switch)

                if #available(macOS 12.0, *) {
                    HStack {
                        TextField(LocalizedStringKey("Check for new mail every"), value: $account.checkInterval, formatter: NumberFormatter())
                            .multilineTextAlignment(.center)
                            .fixedSize()
                        Text("minutes")
                    }
                } else {
                    HStack {
                        Text("Check for new mail every")
                        TextField("", value: $account.checkInterval, formatter: NumberFormatter())
                            .multilineTextAlignment(.center)
                            .fixedSize()
                        Text("minutes")
                    }
                }
            }
            .onChange(of: account) { newValue in
               update(account: account)
            }

            Spacer()

            HStack {
                Spacer()

                Button {
                    reauthorize()
                } label: {
                    Text("Reauthorize")
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
                    reauthorize()
                } label: {
                    Image(systemName: "key.icloud")
                }
            }
        }
        .sheet(isPresented: $showingOAuthPrompt) {
            OAuthPrompt()
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

    func reauthorize() {
        showingOAuthPrompt = true
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: Account(email: "ashchan@gmail.com"))
    }
}
