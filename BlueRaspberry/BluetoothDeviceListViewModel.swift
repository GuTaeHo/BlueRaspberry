//
//  BluetoothDeviceListViewModel.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/8/25.
//

import SwiftUI
import CoreBluetooth


class BluetoothDeviceListViewModel: BluetoothManager.BluetoothSerialDelegate, ObservableObject {
    @Published var peripheralDevices: [BluetoothManager.PeripheralDevice] = []
    @Published var connectedPeripheral: BluetoothManager.PeripheralDevice?
    @Published var alertItem: AlertItem?
    
    
    init() {
        BluetoothManager.shared.delegate = self
    }
    
    func startScan() {
        BluetoothManager.shared.startScan()
    }
    
    func connectToPeripheral(selectedPeripheralDevice: BluetoothManager.PeripheralDevice) {
        // 선택된 Pheripheral을 연결합니다. 검색을 중단하고, peripheralList에 저장된 peripheral 중 클릭된 것을 찾아 연결합니다.
        BluetoothManager.shared.stopScan()
        // serial의 connectToPeripheral 함수에 선택된 peripheral을 연결하도록 요청합니다.
        BluetoothManager.shared.connectToPeripheral(selectedPeripheralDevice)
    }

    func serialDidDiscoverPeripheral(peripheral: BluetoothManager.PeripheralDevice) {
        // 이미 저장되어 있는 기기라면 return합니다.
        if peripheralDevices.contains(where: { $0.peripheral.identifier == peripheral.peripheral.identifier }) {
            return
        }
        
        // 신호 세기가 정상 범위 내에 있는지 확인 후 추가합니다.
        if peripheral.RSSI > -100, peripheral.RSSI <= 0 {
            peripheralDevices.append(peripheral)
        }
        
        print(peripheral.peripheral.services)
        
        // 신호의 세기에 따라 정렬하도록 합니다.
        peripheralDevices.sort { $0.RSSI > $1.RSSI }
    }
    
    func serialDidConnectPeripheral(peripheral: BluetoothManager.PeripheralDevice) {
        alertItem = .init(title: "블루투스 연결 성공",
                          message: "\(peripheral.peripheral.name ?? "알수없는기기")와 성공적으로 연결되었습니다.")
        
        BluetoothManager.shared.delegate = nil
    }
}
