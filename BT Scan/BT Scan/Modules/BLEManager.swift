//
//  BLEManager.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {
    @Published var isScanning: Bool = false
    @Published var state: CBManagerState = .unknown
    @Published var devices: [DevicesModel] = []
    @Published var connectedDevice: CBPeripheral?
    @Published var services: [CBService] = []
    @Published var characteristics: [CBService: [DeviceCharacteristicModel]] = [:]
    @Published var logs: [String] = []
    
    private var centralManager: CBCentralManager!
    private var rssiMap: [CBPeripheral: Int] = [:]
    
    private var strongPeriferalRef: Set<ObjectIdentifier> = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScanning(for serviceUUIDs: [CBUUID]? = nil) {
        guard state == .poweredOn else {
            logs.append("Bluetooth is not powered on yet \(state.rawValue)")
            return
        }
        devices.removeAll()
        rssiMap.removeAll()
        isScanning = true
        logs.append("Scanning started")
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopsScanning() {
        isScanning = false
        centralManager.stopScan()
        logs.append("Scanning stopped")
    }
    
    func connect(_ device: DevicesModel) {
        stopsScanning()
        connectedDevice = device.peripheral
        connectedDevice?.delegate = self
        logs.append("Connecting to \(device.name)")
        centralManager.connect(device.peripheral, options: nil)
        strongPeriferalRef.insert(ObjectIdentifier(device.peripheral))
    }
    
    func disconnect() {
        connectedDevice?.delegate = nil
        centralManager.cancelPeripheralConnection(connectedDevice!)
        strongPeriferalRef.remove(ObjectIdentifier(connectedDevice!))
        connectedDevice = nil
        logs.append("Disconnected")
    }
    
    func discoverAll() {
        connectedDevice?.discoverServices(nil)
    }
    
    func discoverCharacteristic(for service: CBService) {
        connectedDevice?.discoverCharacteristics(nil, for: service)
    }
    
    func readValue(for characteristic: CBCharacteristic) {
        connectedDevice?.readValue(for: characteristic)
    }
    
    func toggleNotification(for characteristic: CBCharacteristic) {
        guard let dev = connectedDevice else { return }
        dev.setNotifyValue(!(characteristic.isNotifying), for: characteristic)
    }
    
    // MARK: - Helpers
        private func upsertDevice(_ peripheral: CBPeripheral, name: String, rssi: Int) {
            rssiMap[peripheral] = rssi
            let displayName = name.isEmpty ? (peripheral.name ?? "Unnamed") : name
            let entry = DevicesModel(peripheral: peripheral, name: displayName, rssi: rssi)
            var mapByID = Dictionary(uniqueKeysWithValues: devices.map { ($0.peripheral.identifier, $0) })
            mapByID[peripheral.identifier] = entry
            devices = Array(mapByID.values).sorted { $0.rssi > $1.rssi }
        }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        logs.append("State: \(central.state.rawValue)")
        if state != .poweredOn {
            isScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Unknown"
        let newDevice = DevicesModel(peripheral: peripheral, name: name, rssi: RSSI.intValue)
        
        if let index = devices.firstIndex(of: .init(peripheral: peripheral, name: name, rssi: RSSI.intValue)) {
            devices[index] = newDevice
        } else {
            devices.append(newDevice)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        logs.append("Connected to \(peripheral.identifier)")
        services.removeAll()
        characteristics.removeAll()
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        logs.append("Disconnected: \(peripheral.identifier) \(error?.localizedDescription ?? "")")
        if connectedDevice == peripheral { connectedDevice = nil }
        strongPeriferalRef.remove(ObjectIdentifier(peripheral))
    }
    
    
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        logs.append("Failed to connect to \(error?.localizedDescription ?? "")")
        connectedDevice = nil
        strongPeriferalRef.remove(ObjectIdentifier(peripheral))
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let error = error {
            logs.append("discoverServices error: \(error.localizedDescription)")
            return
        }
        services = peripheral.services ?? []
        logs.append("Find \(services.count) services")
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error = error { logs.append("discoverCharacteristics error: \(error.localizedDescription)"); return }
        let chs = service.characteristics ?? []
        let wrapped = chs.map { DeviceCharacteristicModel(characteristic: $0) }
        characteristics[service] = wrapped
        logs.append("service \(service.uuid) → characteristic: \(chs.count)")
        objectWillChange.send()
        
        for ch in chs where ch.properties.contains(.read) {
            peripheral.readValue(for: ch)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error { logs.append("updateValue error: \(error.localizedDescription)"); return }
        let data = characteristic.value ?? Data()
        let preview = characteristic.properties.contains(.read) || characteristic.properties.contains(.notify)
        ? (data.utf8String ?? "0x" + data.hexEncodedString)
        : nil
        
        for (service, list) in characteristics {
            if let idx = list.firstIndex(where: { $0.characteristic.uuid == characteristic.uuid }) {
                var newList = list
                newList[idx].previewValue = preview
                characteristics[service] = newList
                break
            }
        }
        objectWillChange.send()
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error { logs.append("notifyState error: \(error.localizedDescription)"); return }
        logs.append("Notify \(characteristic.uuid): \(characteristic.isNotifying)")
    }
}
