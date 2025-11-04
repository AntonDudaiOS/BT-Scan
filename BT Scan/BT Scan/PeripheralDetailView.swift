//
//  PeripheralDetailView.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import SwiftUI
import CoreBluetooth

struct PeripheralDetailView: View {
    @EnvironmentObject var bt: BLEManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let p = bt.connectedDevice {
                header(p)
                controls
                servicesList
            } else {
                Text("Not connected")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Peripheral")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func header(_ p: CBPeripheral) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(p.name ?? "Unnamed")
                    .font(.title3)
                    .bold()
                Text(p.identifier.uuidString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Disconnect", action: bt.disconnect)
                .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    private var controls: some View {
        if bt.services.isEmpty {
            Button("Discover Services", action: bt.discoverAll)
                .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var servicesList: some View {
        List {
            ForEach(bt.services, id: \.uuid.uuidString) { service in
                Section {
                    if let items = bt.characteristics[service], !items.isEmpty {
                        ForEach(items) { item in
                            characteristicRow(item)
                        }
                    } else {
                        Button("Discover Characteristics") {
                            bt.discoverCharacteristic(for: service)
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Service \(service.uuid.uuidString)")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func characteristicRow(_ item: DeviceCharacteristicModel) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Char \(item.characteristic.uuid.uuidString)")
                    .font(.subheadline)
                    .bold()
                Text(propsText(item.characteristic.properties))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let val = item.previewValue {
                    Text("Value: \(val)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if item.characteristic.properties.contains(.read) {
                    Button("Read") { bt.readValue(for: item.characteristic) }
                        .buttonStyle(.bordered)
                }
                if item.characteristic.properties.contains(.notify) {
                    Button(item.characteristic.isNotifying ? "Stop" : "Notify") {
                        bt.toggleNotification(for: item.characteristic)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private func propsText(_ p: CBCharacteristicProperties) -> String {
        var parts: [String] = []
        if p.contains(.read) { parts.append("read") }
        if p.contains(.write) { parts.append("write") }
        if p.contains(.writeWithoutResponse) { parts.append("writeNR") }
        if p.contains(.notify) { parts.append("notify") }
        if p.contains(.indicate) { parts.append("indicate") }
        return parts.joined(separator: " | ")
    }
}
