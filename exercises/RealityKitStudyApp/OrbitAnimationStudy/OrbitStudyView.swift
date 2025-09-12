//
//  ContentView.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 1/9/2025.
//

import SwiftUI
import RealityKit
import ARKit

struct OrbitStudyView: View {
    @Environment(SolarSysViewModel.self) var vm
    
    // FIXME: Naming issue. Is it rotation / sec or sec / rotation?
    static let oneRotationPerSec: Float = .pi * 2
    
    @State var secondsInOneEarthDay: Float = 5.0
    @State var universeScale: Float = 1
    @State var root: Entity? = nil
    @State private var skyBox: Entity? = nil
    @State private var isSkyboxVisible = false
    @State private var sunLight: Entity? = nil
    @State private var crosshairTarget: String = ""
    
    var body: some View {
        ZStack {
            RealityView { content in
                content.camera = .spatialTracking
                await makeSkybox(content)
                await setupUniverse(content)
                content.add(await CrosshairEntity(action: updateHitTargetInfo))
                await addPlanets()
                Task { @MainActor in
                    RotationSystem.registerSystem()
                }
            } update: { content in
                Task { @MainActor in
                    self.skyBox?.isEnabled = isSkyboxVisible
                    self.root?.scale = .init(repeating: universeScale)
                    if let sun = vm.stellarObjects.first {
                        await updateOrbitAndRotation(for: sun, speed: secondsInOneEarthDay)
                    }
                }
            }
            
            .ignoresSafeArea()
            
            // MARK: - SwiftUI components
            
            VStack {
                Text(crosshairTarget)
                    .font(Font.largeTitle.bold())
                    .foregroundStyle(Color.white)
                Spacer()
            }
            VStack {
                Spacer()
                controlPanelView()
            }
            
        }
    }

    // MARK: - Private
    
    private func makeSkybox(_ content: RealityViewCameraContent) async {
        do {
            let skybox = try await SkyboxEntity(textureResourceName: "starfield")
            self.skyBox = skybox
            content.add(skybox)
        } catch {
            print("ERROR: Failed to load skybox")
        }
    }
    
    private func setupUniverse(_ content: RealityViewCameraContent) async {
        let root = Entity()
        root.name = "root"
        content.add(root)
        root.transform = Transform(
            scale: SIMD3(repeating: universeScale),
            translation: .init(x: -3, y: 0, z: -0.3),
        )
        self.root = root
        
        // Light
        let sunLightEntity = Entity()
        sunLightEntity.components.set(
            PointLightComponent(intensity: 15000000)
        )
        if let sun = root.findEntity(named: "Sun") {
            sun.addChild(sunLightEntity)
            sunLightEntity.position.y = 1
        }
    }
    
    private func addPlanets() async {
        if let root = root {
            for stellaObj in vm.stellarObjects {
                await addSolarObject(stellaObj, to: root)
            }
        }
    }

    private func controlPanelView() -> some View {
        HStack(alignment: .top) {
            VStack {
                Slider(value: $secondsInOneEarthDay, in: 0.1...60, step: 0.5)
                Text("Earth Day = \(secondsInOneEarthDay, specifier: "%.1f")s")
                Slider(value: $universeScale, in: 0.1...2.0, step: 0.00001)
            }
            Toggle("Skybox", isOn: $isSkyboxVisible)
                .frame(width: 150)
        }
        .padding(.horizontal, 20)
        .foregroundStyle(Color.white)
    }
    
    private func updateHitTargetInfo(target: Entity?, distance: Float) {
        if let parent = target?.parent {
            let distanceStr = String(format: "%0.2f", distance)
            crosshairTarget = "\(parent.name)\n \(distanceStr)m away"
        } else {
            crosshairTarget = ""
        }
    }
    
    /// Recursively update all stellaObject and their children to be relative
    /// to the given 'speed'.
    ///
    /// - Parameters:
    ///     - stellaObject: an object body in solar system, i.e. Earth, moon, Sun, etc.
    ///     - speed: Time in one Earth-Day speeds up into given 'speed' seconds.
    ///
    private func updateOrbitAndRotation(
       for stellaObject: StellarObject,
       speed: Float
    ) async {
        let standarRotationSpeed = Self.oneRotationPerSec / speed
        let rotationSpeed = standarRotationSpeed / stellaObject.rotationSpeed
        let orbitalSpeed = standarRotationSpeed / stellaObject.orbitalSpeed
        
        await updateRotation(for: stellaObject.name, speed: rotationSpeed)
        await updateOrbit(for: stellaObject.name, speed: orbitalSpeed)
        
        for child in stellaObject.satellites {
            await updateOrbitAndRotation(for: child, speed: speed)
        }
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
    
    private func addSolarObject(
        _ solarObj: StellarObject,
        to entity: Entity
    ) async {
        if let obj = await makeStellarObject(
            name: solarObj.name,
            scale: solarObj.scale,
            distanceFromCenter: solarObj.distanceCenter
        ) {
            if entity.name == "root" {
                entity.addChild(obj)
            } else {
                entity.addChildToMainBody(obj)
            }
            for child in solarObj.satellites {
                await addSolarObject(child, to: obj)
            }
        }
    }
    
    private func makeStellarObject(
        name: String,
        scale: Float = 1.0,
        distanceFromCenter: Float = 0.0
    ) async -> Entity? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
              let stellarObj = try? await ModelEntity(contentsOf: url) else {
            print("ERROR: loading Moon model")
            return nil
        }
        // MainBody - Container for pivoting/orbiting.
        let objPivotPoint = Entity()
        objPivotPoint.name = name
        stellarObj.name = "MainBody"
        stellarObj.scale = SIMD3(repeating: scale)
        stellarObj.transform = Transform(
            scale: SIMD3(repeating: scale),
            translation: .init(x: distanceFromCenter, y: 0, z: 0)
        )
        objPivotPoint.addChild(stellarObj)
        
        // Adding collision component
        var objWidth: Float = 0.0
        if let meshBounds = stellarObj.model?.mesh.bounds {
            objWidth = Float(meshBounds.max.x - meshBounds.min.x)
            stellarObj.components.set(
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
        
        return objPivotPoint
    }
    
}

#Preview {
    OrbitStudyView()
        .environment(SolarSysViewModel())
}
