//
//  DeviceModel.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import CoreBluetooth

struct DevicesModel: Identifiable, Hashable {
    let id = UUID()
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
}
