//
//  always_on_clockApp.swift
//  always_on_clock
//
//  Created by Kirill Milititskiy on 07/11/2026.
//

import SwiftUI

@main
struct always_on_clockApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { setClockIdleTimer(for: scenePhase) }
        }
        .onChange(of: scenePhase) { phase in setClockIdleTimer(for: phase) }
    }
}

@MainActor
func setClockIdleTimer(for phase: ScenePhase) {
    UIApplication.shared.isIdleTimerDisabled = phase == .active
}
