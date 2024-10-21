/*
Abstract:
An extension on the composition that contains functions related to snapping WordCards and Boards together.
 
Taken from SwiftSplash.
*/

import SwiftUI
import RealityKit
import RealityKitContent
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
        
        guard let wordCard = wordCard else {
            return
        }
        
        let nearestBoard = findNearestBoard(wordCard: wordCard)
        let closestBoardPoint = nearestBoard.closestPoint  // where we snap to
        distance = nearestBoard.distance
        
        let wordCardCenterPoint = wordCard.visualBounds(relativeTo: nil).center  // TODO: is this the right wa to do this?
        
        // Nothing in snap distance, return.
        guard distance < maximumSnapDistance,
              let board = nearestBoard.closestBoard,
              let closestBoardPoint = closestBoardPoint
        else {
            isSnapping = false
            isDragging = false
            isRotating = false
            return
        }
                
        // TODO: Check vectors to make sure the board and the card are coplanar.
//        let wordCardNormalVector =
//        let boardNormalVector =
//        let dotProduct = simd_dot(simd_normalize(boardNormalVector), simd_normalize(wordCardNormalVector))
        // TODO: If they're not coplanar, then make them so.
//        if dotProduct != 1 {
//
//        }
        
        // TODO: If snapping would overlap with a wordCard already on the board, then don't snap.
//        if (snapping would overlap) {
//            logger.info("Track pieces don't snap if there's already a piece attached to the snap point. Returning.")
//            isSnapping = false
//            isDragging = false
//            isRotating = false
//            return
//        }
        
        // Snap the pieces together.
        Task(priority: .userInitiated) {
            let lastMoved = Date.timeIntervalSinceReferenceDate
            let startTime = Date.timeIntervalSinceReferenceDate
            let deltaVector = closestBoardPoint - wordCardCenterPoint
            let dragStartPosition = draggedEntity.scenePosition
            let dragEndPosition = dragStartPosition + deltaVector
            
            // Move the card with animation.
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
                
                // Wait for one 90FPS frame.
                try? await Task.sleep(for: .milliseconds(11.111_11))
            }
            // TODO: make board parent of wordcard
            isSnapping = false
            isDragging = false
            isRotating = false
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


func findNearestBoard (wordCard: Entity) -> (closestBoard: Entity?, closestPoint: SIMD3<Float>?, distance: Float) {
    let boardQuery = EntityQuery(where: .has(RealityKitContent.BoardComponent.self))
    
    guard let boards = wordCard.scene?.performQuery(boardQuery) else { return (nil, nil, Float.greatestFiniteMagnitude) }
    
    var closestDistance = Float.greatestFiniteMagnitude
    var closestPoint = SIMD3<Float>.zero
    var closestBoard: Entity? = nil
    boards.forEach() { board in
        
        let boardBoundingBox = board.visualBounds(relativeTo: nil)
        let cardCenter = wordCard.visualBounds(relativeTo: nil).center
        
        let distance = boardBoundingBox.distanceSquared(toPoint: cardCenter)
        let point = boardBoundingBox.closestPoint(toPoint: cardCenter)
        
        if distance < closestDistance {
            closestDistance = distance
            closestPoint = point
            closestBoard = board
        }
    }
    
    return (closestBoard, closestPoint, closestDistance)

}

extension BoundingBox {
    // thanks Claude
    func closestPoint(toPoint point: SIMD3<Float>) -> SIMD3<Float> {
        let minBound = self.min
        let maxBound = self.max
        
        // Clamp the point to the bounding box
        /// Independently project each of the target point's components onto the surface of the box. This ensures that it's the closest. Try it irl.
        let x = Swift.max(minBound.x, Swift.min(maxBound.x, point.x))
        let y = Swift.max(minBound.y, Swift.min(maxBound.y, point.y))
        let z = Swift.max(minBound.z, Swift.min(maxBound.z, point.z))
        
        return SIMD3<Float>(x, y, z)
    }
}
