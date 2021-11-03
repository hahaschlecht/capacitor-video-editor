import Foundation
import Capacitor
import Photos
import PhotosUI

@objc(VideoEditorPlugin)
public class VideoEditorPlugin: CAPPlugin {
    private var call: CAPPluginCall?
    private var settings = VideoSettings(maxVideos: 0)
    
    
    
    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        var result: [String: Any] = [:]
        for permission in CameraPermissionType.allCases {
            let state: String
            switch permission {
            case .camera:
                state = AVCaptureDevice.authorizationStatus(for: .video).authorizationState
            case .photos:
                if #available(iOS 14, *) {
                    state = PHPhotoLibrary.authorizationStatus(for: .readWrite).authorizationState
                } else {
                    state = PHPhotoLibrary.authorizationStatus().authorizationState
                }
            }
            result[permission.rawValue] = state
        }
        call.resolve(result)
    }
    
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        // get the list of desired types, if passed
        let typeList = call.getArray("permissions", String.self)?.compactMap({ (type) -> CameraPermissionType? in
            return CameraPermissionType(rawValue: type)
        }) ?? []
        // otherwise check everything
        let permissions: [CameraPermissionType] = (typeList.count > 0) ? typeList : CameraPermissionType.allCases
        // request the permissions
        let group = DispatchGroup()
        for permission in permissions {
            switch permission {
            case .camera:
                group.enter()
                AVCaptureDevice.requestAccess(for: .video) { _ in
                    group.leave()
                }
            case .photos:
                group.enter()
                if #available(iOS 14, *) {
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { (_) in
                        group.leave()
                    }
                } else {
                    PHPhotoLibrary.requestAuthorization({ (_) in
                        group.leave()
                    })
                }
            }
        }
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.checkPermissions(call)
        }
    }
    
    @objc func getVideos(_ call: CAPPluginCall) {
        self.call = call
        self.settings.maxVideos = call.getInt("maxVideos") ?? 0
        
        
        DispatchQueue.main.async {
            self.showVideos()
        }
    }
}

@available(iOS 14, *)
extension VideoEditorPlugin: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else {
            
            self.call?.reject("User cancelled photos app")
            return
        }
        print(result)
        
        var ReturnVideos: [PluginCallResultData] = [];
        
        let processGroup = DispatchGroup()
        
        for result in results {
            processGroup.enter();
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                //  UIImage
                // TODO something
            } else {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                    if let error = error {
                        print(error)
                        self.call?.reject("Error processing video 1")
                        print("error video")
                        processGroup.leave();
                        return
                    }
                    guard let url = url else {
                        self.call?.reject("Error processing video 2")
                        print("error video")
                        processGroup.leave();
                        return
                    }
                    
                    
                    let fileName = "video_\(Int(Date().timeIntervalSince1970))\(UUID().uuidString).\(url.pathExtension)"
                    let newUrl = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
                    
                    try? FileManager.default.copyItem(at: url, to: newUrl)
                    
                    guard let test = self.bridge?.portablePath(fromLocalURL: newUrl) else {
                        self.call?.reject("Unable to get portable path to file")
                        print("error video")
                        processGroup.leave();
                        return
                    }
                    
                    
                    
                    let string1 = "-i ";
                    let string2 = " -y -ss 00:00:01.000 -vframes 1 ";
                    let thumbFileName = "thumb_\(Int(Date().timeIntervalSince1970))\(UUID().uuidString).png";
                    let thumbUrl = URL(fileURLWithPath: NSTemporaryDirectory() + thumbFileName)
                    
                    let command = string1 + newUrl.absoluteString + string2 + thumbUrl.absoluteString;
                    
                    print("FFMPEG start")

                    FFmpegKit.execute(command);
                    
                    print("FFMPEG finish?!")
                    guard let thumbLink = self.bridge?.portablePath(fromLocalURL: thumbUrl) else {
                        self.call?.reject("Unable to get portable path to file")
                        print("error video")
                        processGroup.leave();
                        return
                    }
                    
                    let info = FFprobeKit.getMediaInformation(newUrl.absoluteString).getMediaInformation();
                    let duration = info?.getDuration()
                
                    print("GOT INFORMATION ON VIDEO DURATION", duration ?? "")
                    
                    
                    let video: PluginCallResultData = [
                        "webPath": test.absoluteString,
                        "thumbnail": thumbLink.absoluteString,
                        "duration" : duration ?? "",
                    ]
                    ReturnVideos.append(video)
                    processGroup.leave();
                }
            }
            
        }
        processGroup.notify(queue: .main) {
            print("Finished all requests", ReturnVideos);
            self.call?.resolve(["videos": ReturnVideos]);
        }
        
    }
}

private extension VideoEditorPlugin {
    
    func showVideos() {
        // check for permission
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .restricted || authStatus == .denied {
            call?.reject("User denied access to photos")
            return
        }
        // we either already have permission or can prompt
        if authStatus == .authorized {
            presentSystemAppropriateVideoPicker()
        } else {
            PHPhotoLibrary.requestAuthorization({ [weak self] (status) in
                if status == PHAuthorizationStatus.authorized {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentSystemAppropriateVideoPicker()
                    }
                } else {
                    self?.call?.reject("User denied access to photos")
                }
            })
        }
    }
    
    func presentSystemAppropriateVideoPicker() {
        if #available(iOS 14, *) {
            presentVideoPicker()
        } else {
            call?.reject("Feature only avaiable in ios 14")
        }
    }
    
    @available(iOS 14, *)
    func presentVideoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = settings.maxVideos
        configuration.filter = .videos
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        // present
        bridge?.viewController?.present(picker, animated: true, completion: nil)
    }
}
