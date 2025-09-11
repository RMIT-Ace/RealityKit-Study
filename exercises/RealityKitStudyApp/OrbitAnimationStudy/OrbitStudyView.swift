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
    @State var root: Entity? = nil
    @State private var skyBox: Entity? = nil
    @State private var isSkyboxVisible = false

    // Keep a reference to the light so we can re-aim it during updates.
    @State private var sunLight: Entity? = nil
    
    @State private var crosshair: Entity? = nil
    
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
                root.name = "root"
                content.add(root)
                root.transform = Transform(
                    translation: .init(x: -3, y: 0, z: -0.7)
                )
                self.root = root
                
                for stellaObj in vm.stellarObjects {
                    await addSolarObject(stellaObj, to: root)
                }
                
                // Crosshair
                let sphereSize: Float = 0.001
                let mesh01 = MeshResource.generateSphere(radius: sphereSize)
                let sphere = ModelEntity(mesh: mesh01)
                sphere.name = "crosshair"
                sphere.transform.translation.z = -0.15
                let cameraAnchor = AnchorEntity(.camera)
                sphere.setParent(cameraAnchor)
                sphere.components.set(
                    CollisionComponent(
                        shapes: [.generateSphere(radius: sphereSize)],
                        mode: .trigger
                                      )
                )
                sphere.components.set(InputTargetComponent())
                content.add(cameraAnchor)
                crosshair = sphere
                
                
                // Raycast
                
            } update: { content in
                Task { @MainActor in
                    self.skyBox?.isEnabled = isSkyboxVisible
                    if let sun = vm.stellarObjects.first {
                        await updateOrbitAndRotation(
                            for: sun,
                            speed: secondsInOneEarthDay
                        )
                    }
                }
            }
            .onAppear {
                Task { @MainActor in
                    RotationSystem.registerSystem()
                }
            }
            .gesture(
                TapGesture().targetedToAnyEntity().onEnded { event in
                    
                    // 1) Ensure we have a crosshair and a scene
                    guard let crosshair = self.crosshair,
                          let scene = crosshair.scene else {
                        print("WARN: No crosshair or scene available")
                        return
                    }

                    // 2) Get crosshair world position
                    let crosshairWorldPos = crosshair.convert(position: crosshair.position, to: nil)

                    // 3) Choose a world-space direction to raycast along
                    // If your crosshair is visually drawn in front of the camera along +Z (in camera space),
                    // you typically want to raycast forward in the camera's look direction in world space.
                    if let cameraAnchor = crosshair.anchor {
                        // Camera’s forward is its -Z axis in its local space.
                        let cameraForwardLocal = SIMD3<Float>(0, 0, -1)
                        let cameraForwardWorld = cameraAnchor.convert(direction: cameraForwardLocal, to: nil)

                        // 4) Construct the end point far along that world direction
                        let endPos = crosshairWorldPos + normalize(cameraForwardWorld) * 100.0

                        // 5) Perform the raycast
                        let results = scene.raycast(from: crosshairWorldPos, to: endPos)

                        if let hit = results.first {
                            print("DEBUG: ray hit entity: \(hit.entity.parent?.name) at position: \(hit.position) distance: \(hit.distance)")
                            // Optional: respond to hit, e.g., select or highlight
                        } else {
                            print("DEBUG: raycast found no hits")
                        }
                    }
                }
            )
            
            // MARK: - SwiftUI components
            
            controlPanelView()
        }
        .ignoresSafeArea()
    }

    // MARK: - Private
    
    private func controlPanelView() -> some View {
        HStack(alignment: .top) {
            VStack {
                Slider(value: $secondsInOneEarthDay, in: 0.1...5, step: 0.1)
                Text("1 Earth Day = \(secondsInOneEarthDay, specifier: "%.1f")s")
            }
            Toggle("Skybox", isOn: $isSkyboxVisible)
                .frame(width: 150)
        }
        .padding(.horizontal, 20)
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
            stellarObj.components.set( InputTargetComponent() )
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
    
    // See: https://www.cephalopod.studio/blog/creating-immersive-visionos-environments-with-reality-kit-and-skyboxes-from-blockade-labs-with-a-true-3d-world-surprise
    private func makeSkybox() async -> Entity? {
        guard let texture = try? await TextureResource(named: "starfield") else {
            fatalError("ERROR: Failed to load skybox texture")
        }
        let mesh = MeshResource.generateSphere(radius: 50)
        //    let material = SimpleMaterial(color: .darkGray, isMetallic: false)
        let material = UnlitMaterial(texture: texture)
        let skyBoxEntity = ModelEntity(mesh: mesh, materials: [material])
        skyBoxEntity.scale = [-1, 1, 1]
        return skyBoxEntity
    }
}

#Preview {
    OrbitStudyView()
        .environment(SolarSysViewModel())
}
