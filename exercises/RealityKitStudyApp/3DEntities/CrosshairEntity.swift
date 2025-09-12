//
//  CrosshairEntity.swift
//  RealityKitStudyApp
//
//  Created by Ace on 12/9/2025.
//

import Foundation
import RealityKit
internal import Combine

/// Create a "crosshair" entity at the center of the camera view.
/// Crosshair calls the callback "action" function periodically with
/// object it detects or nil if there is none.
///
class CrosshairEntity: Entity {
    
    private var action: (_ hitEntity: Entity?, _ distance: Float) -> Void
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private var cancellables: Set<AnyCancellable> = []
    private var crosshair: ModelEntity?
    
    required init() {
        fatalError("ERROR: CrosshairEntity is not intended to be instantiated directly.")
    }
    
    required init(
        distanceFromCamera: Float = -0.1,
        action: @escaping (Entity?, Float) -> Void = { _, _ in }
    ) async {
        self.action = action
        super.init()
        
        let sphereSize: Float = 0.0006
        let mesh01 = MeshResource.generateSphere(radius: sphereSize)
        let sphere = ModelEntity(mesh: mesh01)
        sphere.name = "crosshair"
        sphere.transform.translation.z = distanceFromCamera
        let cameraAnchor = AnchorEntity(.camera)
        sphere.setParent(cameraAnchor)
        sphere.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: sphereSize)],
                mode: .trigger
                              )
        )
        self.addChild(cameraAnchor)
        self.crosshair = sphere
        
        timer
            .sink { _ in Task { @MainActor in await self.performRaycast() } }
            .store(in: &cancellables)
    }
    
    private func performRaycast() async {
        guard let crosshair = crosshair,
              let scene = crosshair.scene else {
            print("WARN: No crosshair or scene available")
            return
        }

        let crosshairWorldPos = crosshair.convert(position: crosshair.position, to: nil)

        // Choose a world-space direction to raycast along
        // If your crosshair is visually drawn in front of the camera along +Z (in camera space),
        // you typically want to raycast forward in the camera's look direction in world space.
        if let cameraAnchor = crosshair.anchor {
            // Camera’s forward is its -Z axis in its local space.
            let cameraForwardLocal = SIMD3<Float>(0, 0, -0.2)
            let cameraForwardWorld = cameraAnchor.convert(direction: cameraForwardLocal, to: nil)
            let endPos = crosshairWorldPos + normalize(cameraForwardWorld) * 100.0
            let results = scene.raycast(from: crosshairWorldPos, to: endPos)
            let distance = results.first?.distance
            action(results.first?.entity, distance ?? 0.0)
        }
    }
}
