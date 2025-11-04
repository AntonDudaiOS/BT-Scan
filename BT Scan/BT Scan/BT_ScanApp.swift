//
//  BT_ScanApp.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import SwiftUI

@main
struct BT_ScanApp: App {
    @StateObject private var bluetooth = BLEManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bluetooth)
        }
    }
}
