//
//  MacCheeseApp.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

@main
struct MacCheeseApp: App {
    @StateObject private var globalTimer = GlobalTimer.shared
    
    var body: some Scene {
        WindowGroup {
            Login_View(userPkey: 1)
                .environmentObject(globalTimer)
        }
    }
}
