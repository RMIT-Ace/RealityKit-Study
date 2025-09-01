//
//  RotationComponent.swift
//  RealityKitStudyApp
//
//  Created by Ace on 1/9/2025.
//

import Foundation
import RealityKit

struct RotationComponent: Component {
    var rotationSpeed: Float = 0.0
    var rotationAxis: SIMD3<Float> = [1, 0, 0]
}
