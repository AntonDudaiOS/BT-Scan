//
//  ContentView.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @EnvironmentObject var bluetooth: BLEManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    Text("BT: \(stateText(bluetooth.state))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if bluetooth.isScanning {
                        ProgressView().scaleEffect(0.9)
                    }
                    Button(bluetooth.isScanning ? "Stop" : "Scan") {
                        bluetooth.isScanning ? bluetooth.stopsScanning() : bluetooth.startScanning()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                List(bluetooth.devices) { d in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(d.name.isEmpty ? "(no name)" : d.name).font(.headline)
                            Text(d.peripheral.identifier.uuidString).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(d.rssi) dBm").font(.subheadline).monospaced()
                        Button("Connect") {
                            bluetooth.connect(d)
                        }
                        .padding(.leading, 8)
                    }
                }
                .listStyle(.plain)
                
                NavigationLink(
                    destination: PeripheralDetailView()
                        .environmentObject(bluetooth),
                    isActive: Binding(get: { bluetooth.connectedDevice != nil },
                                      set: { _ in })
                ) {
                    EmptyView()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(bluetooth.logs.indices, id: \.self) { i in
                            Text("• \(bluetooth.logs[i])")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.padding(.vertical, 4)
                }.frame(height: 100)
            }
            .padding()
            .navigationTitle("BLE Scanner")
        }
    }
    
    private func stateText(_ s: CBManagerState) -> String {
        switch s {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        @unknown default: return "n/a"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BLEManager())
}
