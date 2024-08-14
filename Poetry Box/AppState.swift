//
//  AppState.swift
//  Poetry Box
//
//  Created by Andy Han on 8/13/24.
//

import ARKit
import Foundation


@Observable
@MainActor
public class AppState {
    var session: ARKitSession = ARKitSession()
    var worldInfo = WorldTrackingProvider()
    
    init() {
        Task.detached(priority: .high) {
            do {
                try await self.session.run([self.worldInfo])
            } catch {
                print("Error running world tracking provider: \(error)")
            }
        }
    }
}
