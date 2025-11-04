## BT-Scan (iOS, SwiftUI + CoreBluetooth)

A minimal iOS application built with SwiftUI and CoreBluetooth for scanning, connecting to, and reading from Bluetooth Low Energy (BLE) devices.
Ideal for developers testing BLE peripherals or building Proof-of-Concept apps.

## 🔧 Requirements
Xcode 15 or later
iOS 15+ (can be lowered to 13/14 if needed)
Real iPhone/iPad (the iOS Simulator does not support BLE)
Bluetooth permission

## 🚀 Quick Start
Clone the repository and open the project in Xcode.
Build and run the app on a real device.
Tap Start to begin scanning. Select a device → Connect → Discover Services / Characteristics → Read / Notify.

## Architecture
BLEManager.swift — ObservableObject wrapper around CoreBluetooth:
Manages CBCentralManager and CBPeripheralDelegate
Publishes scanning state, devices, services, and characteristics
Handles connection, discovery, reading, and notifications
ContentView.swift — main view for scanning and listing devices
PeripheralDetailView.swift (optional) — connected device view showing discovered services and characteristics

## Main Data Models
DeviceModel — represents a discovered BLE peripheral (name, RSSI, CBPeripheral)
DeviceCharacteristicModel — wraps CBCharacteristic and its readable value
