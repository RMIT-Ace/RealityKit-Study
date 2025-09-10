//
//  SolarSysViewModel.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 9/9/2025.
//

import Foundation

@Observable
class SolarSysViewModel {
    
    /// For scaling distance of objects to fit in the virtual room.
    static let stellarDistanceRatio: Float = 1 / 50.0
    
    let stellarObjects: [StellarObject] = [
        StellarObject(
            name: "Sun",
            scale: 1.0 * 10,
            distanceCenter: 0.0,
            rotationSpeed: 27.0,    // 27 earth-day.
            orbitalSpeed: 0.0,      // Doesn't orbit any object.
            satellites: [
                StellarObject(
                    name: "Mercury",
                    scale: 1.0 / 3.0,
                    distanceCenter: 58.0 * stellarDistanceRatio,
                    rotationSpeed: 1.0,
                    orbitalSpeed: 1.0
                ),
                StellarObject(
                    name: "Venus",
                    scale: 1.0,
                    distanceCenter: 108.2 * stellarDistanceRatio,
                    rotationSpeed: 1.0,
                    orbitalSpeed: 1.0
                ),
                StellarObject(
                    name: "Earth",
                    scale: 1.0,
                    distanceCenter: 149.6 * stellarDistanceRatio,
                    rotationSpeed: 1.0,         // 1 Day (duh!)
                    orbitalSpeed: 365.25,       // Days to complete orbit around the sun.
                    satellites: [
                        StellarObject(
                            name: "Moon",
                            scale: 1.0 / 3.0,
                            distanceCenter: 12 * stellarDistanceRatio,
                            rotationSpeed: 27.3,    // 27.3 days around itself.
                            orbitalSpeed: 27.3,     // 27.3 days around Earth.
                        )
                    ]
                )
            ]
        )
    ]
}
