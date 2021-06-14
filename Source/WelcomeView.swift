//
//  WelcomeView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/13.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        Text("Welcome!")
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
    }
}

struct Source_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
