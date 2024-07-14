/*
Abstract:
An extension on the composition that contains functions related to snapping WordCards and Boards together.
 
Taken from SwiftSplash.
*/

import SwiftUI
import RealityKit
import simd

struct DragSnapInfo: Sendable {
    var entity: Entity
    var otherSelectedEntities: [Entity]
}
extension CompositionView {
    @MainActor

    func handleSnap(_ snapInfo: DragSnapInfo,
                    allConnectableEntities: QueryResult<Entity>) {
        let draggedEntity = snapInfo.entity
       
        guard let state = draggedEntity.connectableStateComponent else {
            print("No entity recently dragged with state component.")
            return
        }
        
        // Calculate the time since the last move because snapping only happens for a short period of time after the player stops dragging.
        let timeSinceLastMove = Date.timeIntervalSinceReferenceDate - state.lastMoved
        
        // If no time has elapsed, then the piece is still being dragged and the app won't snap it.
        if timeSinceLastMove <= snapEpsilon {
            return
        }
        isSnapping = true

        var wordCard: Entity? = draggedEntity
        // The distance to the target board
        var distance = Float.greatestFiniteMagnitude
        // The target board
        var board: Entity? = nil
        
        if let firstPiece = firstPiece {
            let inConnectionFirst = appState.findNearestConnectionPoint(entity: firstPiece, connectionType: .inPoint)
            firstDistance = inConnectionFirst.distance
            firstConnection = inConnectionFirst.closestEntity
        }
        if let lastPiece = lastPiece {
            let outConnectionLast = appState.findNearestConnectionPoint(entity: lastPiece, connectionType: .outPoint)
            lastDistance = outConnectionLast.distance
            lastConnection = outConnectionLast.closestEntity
        }
        let distance = min(firstDistance, lastDistance)
        let snapTo = (firstDistance <= lastDistance) ? firstConnection : lastConnection
        let connectionType: ConnectionPointType = (firstDistance <= lastDistance) ? .inPoint : .outPoint
        
        // Nothing in snap distance, return.
        guard distance < maximumSnapDistance,
              let entity = (connectionType == .inPoint) ? firstPiece : lastPiece,
              let snapTo = snapTo,
              let ourSnapPoint = (connectionType == .inPoint) ? entity.inConnection?.scenePosition : entity.outConnection?.scenePosition,
              let otherSnapPoint = (connectionType == .inPoint) ? snapTo.outConnection?.scenePosition : snapTo.inConnection?.scenePosition,
              let ourConnectionVectorEntity = (connectionType == .inPoint) ? entity.inConnectionVector : entity.outConnectionVector,
              let otherConnectionVectorEntity = (connectionType == .inPoint) ? snapTo.outConnectionVector : snapTo.inConnectionVector else {
            logger.info("Returning because snap distance too large, or snap point or entity is nil")
            isSnapping = false
            isDragging = false
            isRotating = false
            return
        }
        
        let ourConnectionVector = ourConnectionVectorEntity.scenePosition - entity.scenePosition
        let otherConnectionVector = otherConnectionVectorEntity.scenePosition - snapTo.scenePosition
        
        // Check vectors to make sure the pieces are pointing in opposite directions.
        let dotProduct = simd_dot(simd_normalize(ourConnectionVector), simd_normalize(otherConnectionVector))
        
        if !((dotProduct > 0.95 && dotProduct < 1.05) ||
            (dotProduct < -0.95 && dotProduct > -1.05)) {
            isSnapping = false
            isDragging = false
            isRotating = false
            return
        }
        
        // If there's already comething connected to it, the piece doesn't snap.
        if (connectionType == .inPoint && snapTo.connectableStateComponent?.nextPiece != nil
            && snapTo.connectableStateComponent?.nextPiece != entity)
            || (connectionType == .outPoint && snapTo.connectableStateComponent?.previousPiece != nil
                && snapTo.connectableStateComponent?.previousPiece != entity) {
            logger.info("Track pieces don't snap if there's already a piece attached to the snap point. Returning.")
            isSnapping = false
            isDragging = false
            isRotating = false
            return
        }
        
        // Snap the pieces together.
        Task(priority: .userInitiated) {
            let lastMoved = Date.timeIntervalSinceReferenceDate
            let startTime = Date.timeIntervalSinceReferenceDate
            let deltaVector = otherSnapPoint - ourSnapPoint
            let dragStartPosition = draggedEntity.scenePosition
            let dragEndPosition = dragStartPosition + deltaVector
            
            var piecesToMove = [Entity]()
            if draggedEntity != appState.trackPieceBeingEdited && !appState.additionalSelectedTrackPieces.contains(draggedEntity) {
                appState.clearSelection()
            } else {
                guard let trackPieceBeingEdited = appState.trackPieceBeingEdited else {
                    isSnapping = true
                    return
                }
                piecesToMove.append(trackPieceBeingEdited)
                piecesToMove.append(contentsOf: appState.additionalSelectedTrackPieces)
            }
            var now = Date.timeIntervalSinceReferenceDate
            while now <= lastMoved + secondsAfterDragToContinueSnap {
                now = Date.timeIntervalSinceReferenceDate
                let totalElapsedTime = now - startTime
                
                let alpha = totalElapsedTime / secondsAfterDragToContinueSnap
                
                let newPosition = quarticLerp(dragStartPosition, dragEndPosition, Float(alpha))
                let otherDelta = newPosition - draggedEntity.scenePosition
                Task { @MainActor in
                    draggedEntity.scenePosition = newPosition
                }
                let others = piecesToMove.filter { $0 != draggedEntity }
                for other in others {
                    Task { @MainActor in
                        other.scenePosition += otherDelta
                    }
                }
                
                // Wait for one 90FPS frame.
                try? await Task.sleep(for: .milliseconds(11.111_11))
            }
            isSnapping = false
            isDragging = false
            isRotating = false
            appState.updateConnections()
            appState.updateVisuals()
        }
    }
}
/// This function performs a linear interpolation on a provided `Float` value based on a start, end, and progress value. It applies
/// a quartic  calculation to the result, which causes snapping to accelerate as it gets closer to the snap point. This gives a more
/// natural feel, much like a magnet accelerating toward the opposite pole of another magnet.
func quarticLerp(_ start: Float, _ end: Float, _ alpha: Float) -> Float {
    
    let alpha = min(max(alpha * alpha * alpha * alpha, 0), 1)
    
    return start * (1.0 - alpha) + end * alpha
}
/// This function performs a linear interpolation on a provided `SIMD3<Float>` value based on a start, end, and progress value. It applies
/// a quartic calculation to the result, which causes snapping to accelerate as it gets closer to the snap point. This gives a more
/// natural feel, much like a magnet accelerating toward the opposite pole of another magnet.
func quarticLerp(_ start: SIMD3<Float>, _ end: SIMD3<Float>, _ alpha: Float) -> SIMD3<Float> {
    let x = quarticLerp(start.x, end.x, alpha)
    let y = quarticLerp(start.y, end.y, alpha)
    let z = quarticLerp(start.z, end.z, alpha)
    return SIMD3<Float>(x: x, y: y, z: z)
}


func findNearestBoard (wordCard: Entity) -> (closestBoard: Entity?, distance: Float) {
    // TODO: go to the parent of wordCard (root) and find all children which are Boards, compute distance, return least
}
