//
//  SolarSysViewModel.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 9/9/2025.
//

import Foundation

@Observable
class SolarSysViewModel {
    
    static let stellarDistanceRatio: Float = 1 / 100.0
    
    let stellarObjects: [StellarObject] = [
        StellarObject(
            name: "Sun",
            scale: 1.0,
            distanceCenter: 0.0,
            rotationSpeed: 1.0,
            orbitalSpeed: 1.0,
            satellites: [
                StellarObject(
                    name: "Mercury",
                    scale: 1.0,
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
                    rotationSpeed: 1.0,
                    orbitalSpeed: 1.0,
                    satellites: [
                        StellarObject(
                            name: "Moon",
                            scale: 1.0,
                            distanceCenter: 0.384 * stellarDistanceRatio,
                            rotationSpeed: 1.0,
                            orbitalSpeed: 1.0,
                        )
                    ]
                )
            ]
        )
    ]
}
