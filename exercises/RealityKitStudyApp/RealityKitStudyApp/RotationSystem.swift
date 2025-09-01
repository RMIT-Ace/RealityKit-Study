//
//  RotationSystem.swift
//  RealityKitStudyApp
//
//  Created by Ace on 1/9/2025.
//

import Foundation
import RealityKit

struct RotationSystem: System {
    static let query = EntityQuery(where: .has(RotationComponent.self))
    
    init(scene: Scene) {
        // Register the system with the scene
    }
    
    func update(context: SceneUpdateContext) {
        // Iterate through all entities that have the RotationComponent
        for entity in context.scene.performQuery(Self.query) {
            guard let rotationComponent = entity.components[RotationComponent.self] else { continue }
            
            // Apply the animation logic
            let rotationAngle = rotationComponent.rotationSpeed * Float(context.deltaTime)
            let rotation = simd_quatf(angle: rotationAngle, axis: rotationComponent.rotationAxis)
            entity.transform.rotation *= rotation
        }
    }
}
