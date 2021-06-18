//
//  ShortcutsView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/18.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutsView: View {
    var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline, spacing: 15) {
                Text("Check All Mails")
                    .frame(alignment: .trailing)
                KeyboardShortcuts.Recorder(for: .checkAllMails)
            }

            HStack(alignment: .firstTextBaseline, spacing: 15) {
                Text("Compose Mail")
                    .frame(alignment: .trailing)
                KeyboardShortcuts.Recorder(for: .composeMail)
            }

            Spacer()
        }
        .navigationTitle("Shortcuts")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color.white)
    }
}

struct ShortcutsView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsView()
    }
}
