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
    
    @State var sunRotationSpeed: Float = 0.0
    @State var earthOrbitalSpeed: Float = 0.0
    @State var earthRotationSpeed: Float = 0.0
    @State var moonOrbitalSpeed: Float = 0.0
    @State var moonRotationSpeed: Float = 0.0
    
    @State var root: Entity? = nil
    @State var sun: Entity? = nil
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
                root.transform = Transform(translation: .init(x: 0, y: 0, z: -0.1))
                self.root = root
                
                if let sun = await makeStellarObject(name: "Sun") {
                    self.sun = sun
                    root.addChild(sun)
                }
                
                if let earth = await makeStellarObject(
                    name: "Earth",
                    distanceFromCenter: 1.0
                ) {
                    self.earth = earth
                    sun?.addChildToMainBody(earth)
                }
                
                if let moon = await makeStellarObject(
                    name: "Moon",
                    scale: 0.25,
                    distanceFromCenter: 0.25
                ) {
                    self.moon = moon
                    earth?.addChildToMainBody(moon)
                }
                
                // Camera
//                let camera = Entity()
//                let cameraPosition = SIMD3<Float>(x: 0, y: 0, z: 1.0)
//                camera
//                    .look(
//                        at: earth!.position,
//                        from: sun!.position,
//                        relativeTo: earth
//                    )
//                camera.components.set(PerspectiveCameraComponent())
//                root.addChild(camera)
                
            } update: { content in
                Task { @MainActor in
                    self.skyBox?.isEnabled = isSkyboxVisible
                    await updateOrbitAndRotation()
                }
            }
            .background(.black)
            .frame(maxHeight: .infinity)
            .onAppear {
                Task { @MainActor in
                    RotationSystem.registerSystem()
                }
            }
            
            HStack(alignment: .top) {
                VStack {
                    Slider(value: $oneEarthDay, in: 0.1...5, step: 0.1)
                    Text("1 Earth Day = \(oneEarthDay, specifier: "%.1f") seconds")
                }
                Toggle("Skybox", isOn: $isSkyboxVisible)
                    .frame(width: 150)
            }
            .padding(.horizontal, 20)
            
        }
        .ignoresSafeArea()
    }
    
    private func updateOrbitAndRotation() async {
        sunRotationSpeed = earthRotationSpeed / 27
        earthRotationSpeed = Self.oneRotationPerSec / oneEarthDay
        earthOrbitalSpeed = earthRotationSpeed / 365.25
        
        sunRotationSpeed = earthRotationSpeed / 27
        moonOrbitalSpeed = earthRotationSpeed / 27.3
        moonRotationSpeed = earthRotationSpeed / 27.3
        
        await updateRotation(for: "Sun", speed: sunRotationSpeed)
        
        await updateRotation(for: "Earth", speed: earthRotationSpeed)
        await updateOrbit(for: "Earth", speed: earthOrbitalSpeed)
        
        await updateRotation(for: "Moon", speed: moonRotationSpeed)
        await updateOrbit(for: "Moon", speed: moonOrbitalSpeed)
    }
    
    private func updateRotation(
        for name: String,
        speed: Float
    ) async {
        guard let root = root,
              let entity = root.findEntity(named: name),
              let firstChild = entity.findEntity(named: "MainBody") else {
            print("ERROR: failed to find entity with name: \(name)")
            return
        }
        firstChild.components[RotationComponent.self] = RotationComponent(
            rotationSpeed: speed,
            rotationAxis: [0, 1, 0 ]
        )
    }
    
    private func updateOrbit(
        for name: String,
        speed: Float
    ) async {
        guard let root = root,
              let entity = root.findEntity(named: name) else {
            print("ERROR: failed to find entity with name: \(name)")
            return
        }

        entity.components[RotationComponent.self] = RotationComponent(
            rotationSpeed: speed,
            rotationAxis: [0, 1, 0]
        )
    }
    
    private func makeStellarObject(
        name: String,
        scale: Float = 1.0,
        distanceFromCenter: Float = 0.0
    ) async -> Entity? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
              let stellarObj = try? await Entity(contentsOf: url) else {
            print("ERROR: loading Moon model")
            return nil
        }
        
        let objPivotPoint = Entity()
        objPivotPoint.name = name
        stellarObj.name = "MainBody"
        stellarObj.scale = SIMD3(repeating: scale)
        stellarObj.transform = Transform(
            scale: SIMD3(repeating: scale),
            translation: .init(x: distanceFromCenter, y: 0, z: 0)
        )
        objPivotPoint.addChild(stellarObj)
        
        // For adding children.
        let nonRotatingMainBody = Entity()
        nonRotatingMainBody.name = "NonRotatingMainBody"
        nonRotatingMainBody.transform = Transform(
            translation: .init(x: distanceFromCenter, y: 0, z: 0)
        )
        objPivotPoint.addChild(nonRotatingMainBody)
        
        return objPivotPoint
    }
    
    // See: https://www.cephalopod.studio/blog/creating-immersive-visionos-environments-with-reality-kit-and-skyboxes-from-blockade-labs-with-a-true-3d-world-surprise
    private func makeSkybox() async -> Entity? {
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
}

#Preview {
    OrbitStudyView()
}

