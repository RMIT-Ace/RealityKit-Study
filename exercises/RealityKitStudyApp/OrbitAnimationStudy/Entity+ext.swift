//
//  Entity+ext.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 8/9/2025.
//

import Foundation
import RealityKit

extension Entity {
    
    /// Add and entity to the main body, not the pivot-point body.
    func addChildToMainBody(_ child: Entity) {
        guard let mainBody = findEntity(named: "NonRotatingMainBody") else {
            print("WARN: Entity does not have main body.")
            return
        }
            
        mainBody.addChild(child)
    }
}
