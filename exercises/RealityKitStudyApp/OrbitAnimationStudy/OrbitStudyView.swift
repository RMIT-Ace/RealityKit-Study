//
//  ContentView.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 1/9/2025.
//

import SwiftUI
import RealityKit

struct OrbitStudyView: View {
    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            
            let root = Entity()
            content.add(root)
            root.transform = Transform(translation: .init(x: 0, y: 0, z: -0.5))
            
            if let earthURL = Bundle.main.url(forResource: "Earth", withExtension: "usdz"),
               let earth = try? await Entity(contentsOf: earthURL) {
                root.addChild(earth)
                earth.components[RotationComponent.self] = RotationComponent(
                    rotationSpeed: 1,
                    rotationAxis: [0, 1, 0]
                )
            }
            
            if let moonURL = Bundle.main.url(forResource: "Moon", withExtension: "usdz"),
               let moon = try? await Entity(contentsOf: moonURL) {
                root.addChild(moon)
                moon.transform = Transform(translation: .init(x: 0.25, y: 0, z: 0))
                let startPosition = moon.transform.translation
                var animationDefinition = OrbitAnimation(
                    duration: 10,
                    axis: [0, 1, 0],
                    startTransform: Transform(translation: startPosition),
                    rotationCount: 1,
                    bindTarget: .transform
                )
                animationDefinition.repeatMode = .repeat
                animationDefinition.spinClockwise = false
                let animationResource = try! AnimationResource.generate(with: animationDefinition)
                moon.playAnimation(animationResource)
                
                // FIXME: cannot do 2 animation types!!!
                moon.components[RotationComponent.self] = RotationComponent(
                    rotationSpeed: 5,
                    rotationAxis: [0, 1, 0]
                )

            }
        }
        .onAppear {
            RotationSystem.registerSystem()
        }
    }
}

#Preview {
    OrbitStudyView()
}
