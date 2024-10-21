//
//  AppState.swift
//
//  Created by Andy Han on 8/13/24.
//

import ARKit
import Foundation
import RealityKit


@Observable
@MainActor
public class AppState {
    var session: ARKitSession = ARKitSession()
    var worldInfo = WorldTrackingProvider()
    var wordReelViews: [WordReelView] = []
    var rootEntity: Entity = Entity()
    var isImmersiveSpaceOpen = false

    
    init() {
        Task.detached(priority: .high) {
            do {
                try await self.session.run([self.worldInfo])
                print("World tracking provider running")
            } catch {
                print("Error running world tracking provider: \(error)")
            }
        }
    }
    
    func removeWordReelView(id: UUID) {
        wordReelViews.removeAll { $0.id == id }
    }
}
