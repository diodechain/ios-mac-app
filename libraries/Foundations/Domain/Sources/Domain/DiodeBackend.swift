//
//  DiodeBackend.swift
//  ProtonVPN
//
//  Copyright (c) 2026 Proton Technologies AG
//

import Foundation

public enum DiodeBackend {
    #if DIODE_BACKEND
    public static let isEnabled = true
    #else
    public static let isEnabled = false
    #endif
}
