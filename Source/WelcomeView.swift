//
//  WelcomeView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI
import GTMAppAuth

struct WelcomeView: View {
    @AppStorage(Accounts.storageKey) var accounts = Accounts()

    var body: some View {
        VStack {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 100, height: 100)

                VStack {
                    Divider()
                }
                .frame(width: 100, height: 20)

                Image(systemName: "person.icloud")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
            }

            Button(action: authorize) {
                Text("Authorize and add your Google Account")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private extension WelcomeView {
    func authorize() {
        // TODO: google auth
        // let account = Account(email: "ashchan@gmail.com", enabled: true, notificationEnabled: true)
        // accounts.add(account: account)
        OAuthClient.authorize() { state in
            switch state {
            case .success(let state):
                let authorization = GTMAppAuthFetcherAuthorization(authState: state)
                var account = Account(email: authorization.userEmail!, enabled: true, notificationEnabled: true)
                account.authorization = authorization
                accounts.add(account: account)
                // TODO: this is for experiment only
            case .failure(let error):
                print(error)
            }
       }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
