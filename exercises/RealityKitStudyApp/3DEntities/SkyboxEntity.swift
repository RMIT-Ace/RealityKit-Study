//
//  SkyboxEntity.swift
//  RealityKitStudyApp
//
//  Created by Ace on 12/9/2025.
//

import Foundation
import SwiftUI
import RealityKit

/**
 Create an entity suitable for using as "skybox" in VR environment.
 
 - SeeAlso:
    - https://www.cephalopod.studio/blog/creating-immersive-visionos-environments-with-reality-kit-and-skyboxes-from-blockade-labs-with-a-true-3d-world-surprise

 */
class SkyboxEntity: Entity {
    enum SkyboxEntityError: Error {
        case couldNotLoadTexture(_ TextureResourceName: String)
    }
    
    required init() {
        super.init()
        let mesh = MeshResource.generateSphere(radius: 10)
        let material = SimpleMaterial(color: .darkGray, isMetallic: false)
        let skyBoxEntity = ModelEntity(mesh: mesh, materials: [material])
        skyBoxEntity.scale = [-1, 1, 1]
        self.addChild(skyBoxEntity)
    }
    
    required init(radius: Float = 100, textureResourceName: String) async throws {
        guard let texture = try? await TextureResource(named: textureResourceName) else {
            throw SkyboxEntityError.couldNotLoadTexture(textureResourceName)
        }
        super.init()
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = UnlitMaterial(texture: texture)
        let skyBoxEntity = ModelEntity(mesh: mesh, materials: [material])
        skyBoxEntity.scale = [-1, 1, 1]
        self.addChild(skyBoxEntity)
    }
}
