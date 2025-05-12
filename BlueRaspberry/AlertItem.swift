//
//  AlertItem.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/12/25.
//

import Foundation


struct AlertItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var message: String
}
