//
//  OrbitAnimationStudyApp.swift
//  OrbitAnimationStudy
//
//  Created by Ace on 1/9/2025.
//

import SwiftUI

@main
struct OrbitAnimationStudyApp: App {
    @State private var solarSysVM = SolarSysViewModel()
    
    var body: some Scene {
        WindowGroup {
            OrbitStudyView()
                .environment(solarSysVM)
        }
    }
}
