//
//  ContentView.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 1/9/2025.
//

import SwiftUI
import RealityKit

struct OrbitStudyView: View {
    
    static let oneRotationPerSec: Float = .pi * 2
    
    @State var oneEarthDay: Float = 5.0
    @State var earthRotationSpeed: Float = 0.0
    @State var moonOrbitalSpeed: Float = 0.0
    @State var moonRotationSpeed: Float = 0.0
    
    @State var earth: Entity? = nil
    @State var moon: Entity? = nil
    
    @State private var skyBox: Entity? = nil
    @State private var isSkyboxVisible = false

    var body: some View {
        VStack {
            RealityView { content in
                content.camera = .spatialTracking
                
                if let skyBox = await makeSkybox() {
                    self.skyBox = skyBox
                    content.add(skyBox)
                } else {
                    print("WARN: No skybox specified")
                }
                
                let root = Entity()
                content.add(root)
                root.transform = Transform(translation: .init(x: 0, y: 0, z: -0.5))
                
                if let earth = await makeEarth(rotationSpeed: earthRotationSpeed) {
                    self.earth = earth
                    root.addChild(earth)
                }
                
                if let moon = await makeMoon(orbitalSpeed: moonOrbitalSpeed, rotationSpeed: moonRotationSpeed) {
                    self.moon = moon
                    root.addChild(moon)
                }
                
            } update: { content in
                Task { @MainActor in
                    await updateSpeeds(secondsInEarthDay: oneEarthDay)
                    self.skyBox?.isEnabled = isSkyboxVisible
                }
            }
            .frame(maxHeight: .infinity)
            .onAppear {
                Task { @MainActor in
                    await updateSpeeds(secondsInEarthDay: 5.0)
                    RotationSystem.registerSystem()
                }
            }
            .onChange(of: oneEarthDay) { _, _ in
                Task { @MainActor in
                    await updateSpeeds(secondsInEarthDay: oneEarthDay)
                }
            }
            
            VStack {
                Toggle("Skybox", isOn: $isSkyboxVisible)
                Slider(value: $oneEarthDay, in: 1...10, step: 1)
                Text("1 Earth Day = \(oneEarthDay, specifier: "%.0f") seconds")
            }
            .padding(.horizontal, 20)
            
        }
        .ignoresSafeArea()
    }
    
    private func updateSpeeds(secondsInEarthDay: Float = 10.0) async {
        oneEarthDay = secondsInEarthDay
        earthRotationSpeed = Self.oneRotationPerSec / oneEarthDay
        moonOrbitalSpeed = earthRotationSpeed / 27.3
        moonRotationSpeed = earthRotationSpeed / 27.3

        earth?.components[RotationComponent.self] = RotationComponent(
            rotationSpeed: earthRotationSpeed,
            rotationAxis: [0, 1, 0]
        )
        // Rotation (of pivotEntity of the moon, a.k.a parent of the moon.
        if let moonPivot = moon {
            // Adjust orbital rate.
            moonPivot.components[RotationComponent.self] = RotationComponent(
                rotationSpeed: moonOrbitalSpeed,
                rotationAxis: [0, 1, 0]
            )
            
            // Adjust revolution rate.
            if let moon = moonPivot.findEntity(named: "Moon") {
                moon.components[RotationComponent.self] = RotationComponent(
                    rotationSpeed: moonRotationSpeed,
                    rotationAxis: [0, 1, 0]
                )
            } else {
                print("ERROR: moon(child) is nil")
            }
        } else {
            print("ERROR: moon(pivot) is nil")
        }
    }
    
    private func makeEarth(rotationSpeed: Float = 0.0) async -> Entity? {
        guard let earthURL = Bundle.main.url(forResource: "Earth", withExtension: "usdz"),
              let earth = try? await Entity(contentsOf: earthURL) else {
            print("ERROR: loading Earth model")
            return nil
        }
        return earth
    }
    
    private func makeMoon(orbitalSpeed: Float = 0.0, rotationSpeed: Float = 0.0) async -> Entity? {
        guard let moonURL = Bundle.main.url(forResource: "Moon", withExtension: "usdz"),
              let moon = try? await Entity(contentsOf: moonURL) else {
            print("ERROR: loading Moon model")
            return nil
        }
        
        let moonPivot = Entity()
        moonPivot.addChild(moon)
        moon.name = "Moon"
        moon.transform = Transform(
            scale: SIMD3(repeating: 0.25),
            translation: .init(x: 0.25, y: 0, z: 0)
        )
        return moonPivot
    }
}

#Preview {
    OrbitStudyView()
}

// See: https://www.cephalopod.studio/blog/creating-immersive-visionos-environments-with-reality-kit-and-skyboxes-from-blockade-labs-with-a-true-3d-world-surprise
fileprivate func makeSkybox() async -> Entity? {
    guard let texture = try? await TextureResource(named: "starfield") else {
        fatalError("ERROR: Failed to load skybox texture")
    }
    let mesh = MeshResource.generateSphere(radius: 500)
//    let material = SimpleMaterial(color: .darkGray, isMetallic: false)
    let material = UnlitMaterial(texture: texture)
    let skyBoxEntity = ModelEntity(mesh: mesh, materials: [material])
    skyBoxEntity.scale = [-1, 1, 1]
    return skyBoxEntity
}
