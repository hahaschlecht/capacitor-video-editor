//
//  VideoEditorTypes.swift
//  Plugin
//
//  Created by Valentin Rentzsch  on 26.10.21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation


internal enum CameraPermissionType: String, CaseIterable {
    case camera
    case photos
}

public struct VideoSettings {
    var maxVideos: Int
}

public struct ReturnVideo {
    var path: String = "";
    var webPath: String = "";
    var exif: Any?;
    var format: String? = "";
}
