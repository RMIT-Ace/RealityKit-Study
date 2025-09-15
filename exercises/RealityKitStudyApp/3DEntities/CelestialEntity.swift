//
//  StellarEntity.swift
//  RealityKitStudyApp
//
//  Created by Ace on 15/9/2025.
//

import Foundation
import RealityKit

/// Represent planets or stars. A body that rotates around itself and
/// orbits around its parent (i.e. Sun).
///
class CelestialEntity: Entity {
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    required init?(
        name: String,
        scale: Float,
        distanceFromCenter: Float) async
    {
        super.init()
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
              let celestialObj = try? await ModelEntity(contentsOf: url) else {
            print("ERROR: loading Moon model")
            return nil
        }
        // MainBody - Container for pivoting/orbiting.
        let objPivotPoint = self
        objPivotPoint.name = name
        celestialObj.name = "MainBody"
        celestialObj.scale = SIMD3(repeating: scale)
        celestialObj.transform = Transform(
            scale: SIMD3(repeating: scale),
            translation: .init(x: distanceFromCenter, y: 0, z: 0)
        )
        objPivotPoint.addChild(celestialObj)
        
        // Adding collision component
        var objWidth: Float = 0.0
        if let meshBounds = celestialObj.model?.mesh.bounds {
            objWidth = Float(meshBounds.max.x - meshBounds.min.x)
            celestialObj.components.set(
                CollisionComponent(
                    shapes: [.generateSphere(radius: objWidth / 2)],
                    mode: .trigger
                )
            )
        } else {
            print("WARN: no bounds on model, using 0.0 width")
        }
        
        // For adding children. No Visual appearance..
        let nonRotatingMainBody = Entity()
        nonRotatingMainBody.name = "NonRotatingMainBody"
        nonRotatingMainBody.transform = Transform(
            translation: .init(x: distanceFromCenter, y: 0, z: 0)
        )
        objPivotPoint.addChild(nonRotatingMainBody)
    }
}
