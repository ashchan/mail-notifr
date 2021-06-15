//
//  Sidebar.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selection: String?

    var body: some View {
        List {
            Text("Accounts")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            NavigationLink(
                destination: Text("ashchan@gmail.com"),
                tag: "account1",
                selection: $selection
            ) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.green)

                Text(verbatim: "ashchan@gmail.com")
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
        Sidebar(selection: .constant("general"))
    }
}
