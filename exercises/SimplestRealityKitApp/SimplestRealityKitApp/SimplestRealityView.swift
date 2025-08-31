//
//  ContentView.swift
//  SimplestRealityKitApp
//
//  Created by Ace on 31/8/2025.
//

import SwiftUI
import RealityKit   // (1)

/// Demonstrate the simplest implementation of RealityKit app
/// with camera tracking.
///
/// 1. Import RealityKit to access its features
/// 2. Use RealityView container
/// 3. Required Privacy - Camera Usage Description in Info.plist
/// 4. Two things to make an entity visible: mesh, and materials.
/// 5. Move text away from viewer, i.e. by 0.5 meter
///
struct SimplestRealityView: View {
    var body: some View {
        RealityView { content in    // (2)
            content.camera = .spatialTracking   // (3)
            
            let a = ModelEntity(    // (4)
                mesh: .generateText(
                    "Hello, World!",
                    extrusionDepth: 0.02,
                    font: .boldSystemFont(ofSize: 0.15),
                    containerFrame: CGRect(
                        x: -0.5, y: -0.8, width: 1.2, height: 1
                    )
                ),
                materials: [
                    SimpleMaterial(color: .orange, isMetallic: true)
                ]
            )
            
            a.transform = Transform(translation: SIMD3<Float>(0, 0, -0.5)) // (5)
            content.add(a)
        }
    }
}

#Preview {
    SimplestRealityView()
}
