//
//  BlueRaspberryApp.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/8/25.
//

import SwiftUI
import SoyBeanUI

@main
struct BlueRaspberryApp: App {
    init() {
        print(Font.registerFonts())
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
