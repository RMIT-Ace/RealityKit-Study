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
    @State var universeScale: Float = 0.1
    @State var universeZ: Float = -0.07
    @State var root: Entity? = nil
    @State private var skyBox: Entity? = nil
    @State private var isSkyboxVisible = false
    @State private var sunLight: Entity? = nil
    @State private var crosshairTarget: String = ""
    
    let ratio: Float = 0.00005
    @State private var entityPosition: SIMD3<Float> = .zero
    @State private var currentZoom: Float = 1.0
    @State private var accumScale: Float = 0.1
    var moveGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                guard let root = self.root else { return }
                let translation = value.translation
                entityPosition.x += Float(translation.width) * ratio
                entityPosition.y -= Float(translation.height) * ratio
                entityPosition.z = root.position.z
                root.position = entityPosition
            }
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                universeScale = accumScale * Float(value)
            }
            .onEnded { value in
                accumScale = universeScale
            }
    }

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
                    self.root?.position.z = universeZ
                    if let sun = vm.stellarObjects.first {
                        await updateOrbitAndRotation(for: sun, speed: secondsInOneEarthDay)
                    }
                }
            }
            .ignoresSafeArea()
            .gesture(moveGesture)
            .gesture(zoomGesture)
            
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
            translation: .init(x: -0.5, y: 0, z: universeZ),
//            translation: .init(x: -3, y: 0, z: -0.3),
        )
        root.components.set(CollisionComponent(shapes: [
            .generateBox(size: [1, 1, 1])
        ]))
        root.components.set(InputTargetComponent())
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
                Slider(value: $universeScale, in: 0.01 ... 1.0, step: 0.00001)
                Slider(value: $universeZ, in: -3.0 ... -0.1, step: 0.00001)
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
        if let obj = await CelestialEntity(
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
    
}

#Preview {
    OrbitStudyView()
        .environment(SolarSysViewModel())
}
