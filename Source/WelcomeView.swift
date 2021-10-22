//
//  WelcomeView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/16.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showingOAuthPrompt = false

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

            Button(action: addAccount) {
                Text("Authorize and add your Google Account")
            }
            .sheet(isPresented: $showingOAuthPrompt) {
                OAuthPrompt()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
    }

    private func addAccount() {
        showingOAuthPrompt = true
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
