//
//  BluetoothManager.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/8/25.
//

import UIKit
import CoreBluetooth


// 프로토콜에 포함되어 있는 일부 함수를 옵셔널로 설정합니다.
extension BluetoothManager.BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: BluetoothManager.PeripheralDevice) { }
    func serialDidConnectPeripheral(peripheral: BluetoothManager.PeripheralDevice) { }
}

/// 블루투스 통신을 담당할 시리얼을 클래스로 선언합니다. CoreBluetooth를 사용하기 위한 프로토콜을 추가해야합니다.
class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // 블루투스를 연결하는 과정에서의 시리얼과 뷰의 소통을 위해 필요한 프로토콜입니다.
    protocol BluetoothSerialDelegate : AnyObject {
        func serialDidDiscoverPeripheral(peripheral: PeripheralDevice)
        func serialDidConnectPeripheral(peripheral: PeripheralDevice)
    }
    
    // 주변기기 정보 객체입니다.
    struct PeripheralDevice: Equatable, Hashable {
        let peripheral: CBPeripheral
        let RSSI: Float
        let manufacturerName: String
        
        /// 수신 강도
        var RSSIStatus: String {
            switch self.RSSI {
            case -50 ..< 0:
                return "아주 좋음"
            case -70 ..< -50:
                return "좋음"
            case -80 ..< -70:
                return "보통"
            case -90 ..< -80:
                return "나쁨"
            default:
                return "통신 불가"
            }
        }
    }
    
    /// 블루투스와 관련된 일을 전담하는 글로벌 시리얼 핸들러입니다.
    static let shared = BluetoothManager()
    
    private override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// centralManager은 블루투스 주변기기를 검색하고 연결하는 역할을 수행합니다.
    var centralManager: CBCentralManager!
    
    /// pendingPeripheral은 현재 연결을 시도하고 있는 블루투스 주변기기를 의미합니다.
    var pendingPeripheral: PeripheralDevice?
    
    /// connectedPeripheral은 연결에 성공된 기기를 의미합니다. 기기와 통신을 시작하게되면 이 객체를 이용하게됩니다.
    var connectedPeripheral: CBPeripheral?
    
    /// 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수입니다.
    weak var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
    var serviceUUID = CBUUID(string: "FFE0")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var characteristicUUID = CBUUID(string : "FFE1")
    
    // BluetoothSerialDelegate 프로토콜에 등록된 메서드를 수행하는 delegate입니다.
    weak var delegate: BluetoothSerialDelegate?
    
    // 회사 식별 목록
    let companyIdentifiers = {
        let yamlDic = try? FormatUtil.loadYAMLFromBundle(filename: "company_identifiers")
        let dic = yamlDic?["company_identifiers"] as? [[String : Any]]
        return dic
    }()
    
    /// 기기 검색을 시작합니다. 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾아냅니다.
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
       
      // CBCentralManager의 메서드인 scanForPeripherals를 호출하여 연결가능한 기기들을 검색합니다. 이 떄 withService 파라미터에 nil을 입력하면 모든 종류의 기기가 검색되고, 지금과 같이
      // serviceUUID를 입력하면 특정 serviceUUID를 가진 기기만을 검색합니다.
//        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            print(peripheral)
            delegate?.serialDidDiscoverPeripheral(peripheral: .init(peripheral: peripheral,
                                                                    RSSI: 0.0,
                                                                    manufacturerName: ""))
        }
    }

    /// 기기 검색을 중단합니다.
    func stopScan() {
        centralManager.stopScan()
    }

      /// 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도합니다.
    func connectToPeripheral(_ peripheral: PeripheralDevice) {
        // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
        pendingPeripheral = peripheral
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    // CBCentralManagerDelegate에 포함되어 있는 메서드입니다.
    // central 기기의 블루투스가 켜져있는지, 꺼져있는지 확인합니다. 확인하여 centralManager.state의 값을 .powerOn 또는 .powerOff로 변경합니다.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        pendingPeripheral = nil
        connectedPeripheral = nil
    }
    
    // 기기가 검색될 때마다 호출되는 메서드입니다.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RSSI는 기기의 신호 강도를 의미합니다.
        let manufacturerName = manufacturerName(advertisementData) ?? ""
        delegate?.serialDidDiscoverPeripheral(peripheral: .init(peripheral: peripheral,
                                                                RSSI: Float(truncating: RSSI),
                                                                manufacturerName: manufacturerName))
        
    }
    
    // 기기가 연결되면 호출되는 메서드입니다.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
    
        // peripheral의 Service들을 검색합니다.파라미터를 nil으로 설정하면 peripheral의 모든 service를 검색합니다.
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        print("연결 실패: \(error?.localizedDescription ?? "")")
    }
    
    
    // service 검색에 성공 시 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 characteristic을 검색합니다.
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    // characteristic 검색에 성공 시 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정을 완료합니다.
            if characteristic.uuid == characteristicUUID {
                // 해당 기기의 데이터를 구독합니다.
                peripheral.setNotifyValue(true, for: characteristic)
                // 데이터를 보내기 위한 characteristic을 저장합니다.
                writeCharacteristic = characteristic
                // 데이터를 보내는 타입을 설정합니다. 이는 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경됩니다.
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                delegate?.serialDidConnectPeripheral(peripheral: .init(peripheral: peripheral,
                                                                       RSSI: 0.0,
                                                                       manufacturerName: ""))
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 함수입니다.
        // 제가 테스트한 주변 기기는 .withoutResponse이기 때문에 호출되지 않습니다.
        // writeType이 .withResponse인 블루투스 기기로부터 응답이 왔을 때 필요한 코드를 작성합니다.(필요하다면 작성해주세요.)
     
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 함수입니다.
        // 신호 강도와 관련된 코드를 작성합니다.(필요하다면 작성해주세요.)
    }
}

extension BluetoothManager {
    // 광고 데이터 안에 제조사 데이터가 있는지 확인
    private func manufacturerName(_ advertisementData: [String : Any]) -> String? {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }
        
        print("🏷 제조사 데이터: \(manufacturerData as NSData)")
        
        // 바이트 배열로 변환
        let bytes = [UInt8](manufacturerData)
        
        // 예시: 앞 2바이트는 제조사 ID (리틀 엔디안)
        if bytes.count >= 2 {
            let manufacturerID = UInt16(bytes[1]) << 8 | UInt16(bytes[0])
            print("🏭 제조사 ID: \(String(format: "0x%04X", manufacturerID))")
            
            let findDevice = companyIdentifiers?.first(where: { "\($0["value"] ?? "")" == "\(manufacturerID)" })
            
            
            if
                let temp = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
                let adLocalName = temp.toOptionalIfEmpty
            {
                print("🏭 제조사 명: \(adLocalName)")
                return adLocalName
            } else if let manufacturerName = "\(findDevice?["name"] ?? "")".toOptionalIfEmpty {
                print("🏭 제조사 명: \(manufacturerName)")
                return manufacturerName
            }
            
            // 이후 바이트는 커스텀 데이터
            let customPayload = bytes.dropFirst(2)
            print("📦 제조사 정의 데이터: \(customPayload.map { String(format: "%02X", $0) }.joined(separator: " "))")
            return nil
        } else {
            return nil
        }
    }
}
