//
//  MainView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/13.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @Binding var selection: String?

    var body: some View {
        NavigationView {
            Sidebar(selection: $selection)
                .toolbar {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                            .help("Toggle Sidebar")
                    }
                }
                .frame(minWidth: 220, alignment: .leading)

            Text("Welcome")
        }
       .frame(minWidth: 480, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct Source_Previews: PreviewProvider {
    static var previews: some View {
        MainView(selection: .constant(""))
    }
}
