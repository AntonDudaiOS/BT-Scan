//
//  DeviceCharacteristicModel.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import CoreBluetooth

struct DeviceCharacteristicModel: Identifiable {
    let id = UUID()
    let characteristic: CBCharacteristic
    var previewValue: String?
}
