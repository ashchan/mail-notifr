//
//  Sidebar.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @Binding var accounts: Accounts
    @Binding var selection: String?

    var body: some View {
        VStack {
            List {
                Text("Accounts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(accounts, id: \.self) { account in
                    NavigationLink(
                        destination: AccountView(account: account),
                        tag: account.email,
                        selection: $selection
                    ) {
                        AvatarView(image: "person", backgroundColor: .green)
                        Text(verbatim: account.email)
                    }
                    .padding(2)
                }

                Text("Preferences")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                NavigationLink(
                    destination: SettingsView(),
                    tag: "preferences",
                    selection: $selection
                ) {
                    AvatarView(image: "gearshape", backgroundColor: .blue)
                    Text("General")
                }
                .padding(2)

                NavigationLink(
                    destination: ShortcutsView(),
                    tag: "shortcuts",
                    selection: $selection
                ) {
                    AvatarView(image: "keyboard", backgroundColor: .orange)
                    Text("Shortcuts")
                }
                .padding(2)
            }
            .listStyle(.sidebar)

            Spacer()

            HStack {
                Button(action: {
                    selection = "welcome"
                }) {
                    Label("Add Account", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                .padding(8)

                Spacer()
            }
        }
    }
}

struct AvatarView: View {
    var image: String
    var backgroundColor: Color

    var body: some View {
        Circle()
            .frame(width: 24, height: 24)
            .foregroundColor(backgroundColor)
            .overlay(
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white)
            )
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(
            accounts: .constant([Account(email: "ashchan@gmail.com", enabled: true, notificationEnabled: true)]),
            selection: .constant("general")
        )
    }
}
