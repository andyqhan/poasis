import Foundation
import OSLog
import RealityKit

/// Indicate how close two compatible connection points have to be
/// in order to snap.
let maximumSnapDistance = Float(0.14)

/// The app doesn't continue snapping pieces forever. Constantly snapping pieces could
/// result in weird interactions when connection points are close.
var secondsAfterDragToContinueSnap = TimeInterval(0.025)

/// The piece being dragged or rotated using gesture entities.
var draggedPiece: Entity? = nil

/// Indicate how close two connection points must be to be considered connected.
let snapEpsilon = 0.000_000_1

/// When someone is dragging one or more track pieces using a gesture, this is `true`.
var isDragging = false

/// When someone is rotating one or more track pieces using a gesture, this is `true`.
var isRotating = false

var isSnapping = false

