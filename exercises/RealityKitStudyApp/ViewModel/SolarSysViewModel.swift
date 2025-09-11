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
            scale: 1.0 * 10,        // NOTE: This is NOT correct scale!
            distanceCenter: 0.0,
            rotationSpeed: 27.0,    // 27 earth-day.
            orbitalSpeed: 0.0,      // Doesn't orbit any object.
            satellites: [
                StellarObject(
                    name: "Mercury",
                    scale: 1.0 / 3.0,
                    distanceCenter: 58.0 * stellarDistanceRatio,
                    rotationSpeed: 176, // 176 earth-day!!!
                    orbitalSpeed: 88.0  // 88 earth-day
                ),
                StellarObject(
                    name: "Venus",
                    scale: 1.0,
                    distanceCenter: 108.2 * stellarDistanceRatio,
                    rotationSpeed: 243.0,   // Year is shorter than day! :-)
                    orbitalSpeed: 225.0     // 225 earth-day
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
                            distanceCenter: 10 * stellarDistanceRatio,
                            rotationSpeed: 27.3,    // 27.3 days around itself.
                            orbitalSpeed: 27.3,     // 27.3 days around Earth.
                        )
                    ]
                ),
                StellarObject(
                    name: "Mars",
                    scale: 1.0 / 2.0,       // Half earth size.
                    distanceCenter: 228.0 * stellarDistanceRatio,
                    rotationSpeed: 1.0,     // Roughly same as Earth day.
                    orbitalSpeed: 687.0     // 687 earth-day
                ),
                StellarObject(
                    name: "Jupiter",
                    scale: 11.0,                    // 11 time bigger than Earth.
//                    distanceCenter: 778.5 * stellarDistanceRatio, // Too far
                    distanceCenter: 500 * stellarDistanceRatio,
                    rotationSpeed: 10.0 / 24.0,     // Roughly 10 Earth-hour.
                    orbitalSpeed: 4333.0            // 4,333 earth-day
                ),
            ]
        )
    ]
}
