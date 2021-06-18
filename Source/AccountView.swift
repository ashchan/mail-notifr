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
        VStack {
            Text(account.email)
            Button(action: delete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(account.email)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        AccountView(account: Account(email: "ashchan@gmail.com", enabled: true, notificationEnabled: true))
    }
}
