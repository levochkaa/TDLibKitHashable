// TDLibKitHashableApp.swift

import SwiftUI
import TDLibKit

@main
struct TDLibKitHashableApp: App {
    init() {
        TdApi.shared.startTdLibUpdateHandler()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
