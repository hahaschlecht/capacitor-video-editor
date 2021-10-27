//
//  VideoEditorExtensions.swift
//  Plugin
//
//  Created by Valentin Rentzsch  on 26.10.21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation
import Photos

internal protocol CameraAuthorizationState {
    var authorizationState: String { get }
}


extension AVAuthorizationStatus: CameraAuthorizationState {
    var authorizationState: String {
        switch self {
        case .denied, .restricted:
            return "denied"
        case .authorized:
            return "granted"
        case .notDetermined:
            fallthrough
        @unknown default:
            return "prompt"
        }
    }
}

extension PHAuthorizationStatus: CameraAuthorizationState {
    var authorizationState: String {
        switch self {
        case .denied, .restricted:
            return "denied"
        case .authorized:
            return "granted"
        #if swift(>=5.3)
        // poor proxy for Xcode 12/iOS 14, should be removed once building with Xcode 12 is required
        case .limited:
            return "limited"
        #endif
        case .notDetermined:
            fallthrough
        @unknown default:
            return "prompt"
        }
    }
}
