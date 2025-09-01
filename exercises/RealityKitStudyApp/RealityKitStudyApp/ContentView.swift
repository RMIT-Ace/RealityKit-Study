//
//  ContentView.swift
//  RealityKitStudyApp
//
//  Created by Ace on 31/8/2025.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            
            let a = ModelEntity(
                mesh: .generateSphere(radius: 0.005), // 10cm diameter
                materials: [SimpleMaterial(color: .black, isMetallic: false)]
            )
            a.transform = Transform(translation: SIMD3(0, 0, 0))
            content.add(a)
            
            let box1 = makeBox(colors: [.green, .blue], size: 0.05, opacity: 0.5)
            content.add(box1)
            
            
            let box2 = makeBox(colors: [.red, .blue], size: 0.05)
            content.add(box2)
            box2.transform = Transform(translation: SIMD3(0.1, 0, 0))   // Shift right 100 cm
            box2.transform.scale = SIMD3(repeating: 0.5)
            
            let box3 = makeBox(colors: [.blue, .purple], size: 0.05)
            content.add(box3)
            box3.transform = Transform(translation: SIMD3(0.2, 0, 0))   // Shift right 200 cm
            box3.transform.scale = SIMD3(repeating: 1.0 / 3.0)
            box3.transform.rotation = .init(angle: -90.0 * .pi / 180.0, axis: [0, 0, 1] )
            
            box3.components[RotationComponent.self] = RotationComponent(rotationSpeed: 2, rotationAxis: [1, 0, 0])
        }
        .onAppear {
            RotationSystem.registerSystem()
        }
    }
    
    private func makeBox(
        colors: [UIColor] = [.black, .blue],
        size: Float = 0.0,
        opacity: CGFloat = 1.0
    ) -> ModelEntity {
        let material = SimpleMaterial(
            color: colors[0].withAlphaComponent(opacity),
            isMetallic: false
        )
        let box = ModelEntity(
            mesh: .generateBox(size: size),
            materials: [material]
        )
        let head = ModelEntity(
            mesh: .generateSphere(radius: size / 3),
            materials: [
                SimpleMaterial(
                    color: colors[1].withAlphaComponent(opacity), isMetallic: false
                )
            ]
        )
        box.addChild(head)
        head.transform = Transform(
            translation: SIMD3(0,
                               size / 2 + (size / 3), // Attach on top of body
                               0)
        )

        return box
    }
}

#Preview {
    ContentView()
}
