//
//  Data+Extension.swift
//  BT Scan
//
//  Created by Anton.Duda on 04.11.2025.
//

import Foundation

extension Data {
    var hexEncodedString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var utf8String: String? {
        return String(data: self, encoding: .utf8)
    }
}
