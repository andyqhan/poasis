//
//  Created by Andy Han on 4/20/24.
//

import SwiftUI
import RealityKitContent

@main
@MainActor
struct PoaisisApp: App {
    @State private var immersionStyle: ImmersionStyle = .mixed
    @State private var appState = AppState()
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    init() {
        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.ConnectableStateComponent.registerComponent()
        RealityKitContent.BoardComponent.registerComponent()
    }
    var body: some Scene {
        WindowGroup("Selection window", id: "selection") {
            BoxSelectionView()
                .environment(appState)
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositionView()
                .environment(appState)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
