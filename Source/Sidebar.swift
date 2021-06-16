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
        List {
            HStack {
                Text("Accounts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if selection != nil && selection != "welcome" {
                    Button(action: {
                        selection = "welcome"
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
           }

            ForEach(accounts, id: \.self) { account in
                NavigationLink(
                    destination: AccountView(account: account),
                    tag: account.email,
                    selection: $selection
                ) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.green)

                    Text(verbatim: account.email)
                }
            }

            Text("Preferences")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            NavigationLink(
                destination: Text("General"),
                tag: "preferences",
                selection: $selection
            ) {
                Label("General", systemImage: "gearshape")
            }
            NavigationLink(
                destination: Text("Shortcuts"),
                tag: "shortcuts",
                selection: $selection
            ) {
                Label("Shortcuts", systemImage: "command.square")
           }
        }
        .listStyle(.sidebar)
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
