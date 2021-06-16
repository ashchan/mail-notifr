//
//  WelcomeView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("accounts") var accounts = Accounts()

    var body: some View {
        VStack {
            Text("Add your Gmail account")
            Button(action: authorize) {
                Image(systemName: "person.icloud")
                Text("Authorize and add account")
            }
        }
    }
}

private extension WelcomeView {
    func authorize() {
        // TODO: google auth
        let account = Account(email: "ashchan@gmail.com", enabled: true, notificationEnabled: true)
        accounts.append(account)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
