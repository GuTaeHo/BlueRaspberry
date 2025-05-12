//
//  BluetoothDeviceListView.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/8/25.
//

import SwiftUI


struct BluetoothDeviceListView: View {
    @ObservedObject var viewModel = BluetoothDeviceListViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                item
            }
        }
        .onAppear {
            viewModel.startScan()
        }
    }
    
    @ViewBuilder
    var item: some View {
        VStack(alignment: .leading) {
            Text("검색된 기기 수: \(viewModel.peripheralDevices.count)")
            Text("(수신 세기 기준 내림차순)")
        }.padding()
            
        ForEach(viewModel.peripheralDevices, id: \.self) { peripheral in
            VStack(alignment: .leading) {
                HStack {
                    Text("\(peripheral.peripheral.name ?? "Unknown")")
                        .textStyle(fontType: .IBMPlexBold,
                                   fontSize: 16,
                                   color: .black)
                    Spacer()
                    Text("\(peripheral.RSSIStatus)")
                }
                Text("\(peripheral.manufacturerName.toOptionalIfEmpty ?? "Unknown")")
                    .textStyle(fontType: .IBMPlexMedium,
                               fontSize: 12,
                               color: .gray)
            }
            .padding()
            .onTapGesture {
                viewModel.connectToPeripheral(selectedPeripheralDevice: peripheral)
            }
        }
    }
}

#Preview {
    BluetoothDeviceListView()
}
