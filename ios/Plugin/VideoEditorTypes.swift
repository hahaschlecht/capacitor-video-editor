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
    var amountThumbnails: Int
}

public struct ReturnVideo {
    var path: String = "";
    var webPath: String = "";
    var exif: Any?;
    var format: String? = "";
}

public struct ConcatItem: Codable {
    var path: String;
    var start: String;
    var duration: String;
}

public struct ConcatItems: Codable {
    let items: [ConcatItems]
}
