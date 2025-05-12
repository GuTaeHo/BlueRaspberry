//
//  MainView.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/8/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: BluetoothDeviceListView()) {
                    Button("블루투스 기기 목록",
                           systemImage: "globe") {
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
