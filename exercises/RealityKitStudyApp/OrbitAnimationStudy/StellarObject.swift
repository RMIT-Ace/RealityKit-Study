//
//  StellarObject.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 9/9/2025.
//

import Foundation

struct StellarObject: Identifiable {
    let id: UUID = UUID()
    let name: String
    var scale: Float
    var distanceCenter: Float
    var rotationSpeed: Float
    var orbitalSpeed: Float
    var satellites: [StellarObject] = []
}
