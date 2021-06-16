//
//  AccountView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct AccountView: View {
    @AppStorage("accounts") var accounts = Accounts()
    @State var account: Account

    var body: some View {
        VStack {
            Text(account.email)
            Button(action: delete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

private extension AccountView {
    func delete() {
        // TODO
        //   * confirmation alert
        //   * stop checker
        //   * remove keychain (auth info)
        accounts.removeAll { $0.id == account.id }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: Account(email: "ashchan@gmail.com", enabled: true, notificationEnabled: true))
    }
}
