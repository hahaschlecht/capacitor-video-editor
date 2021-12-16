import Foundation
import Capacitor
import Photos
import PhotosUI
import JavaScriptCore

@objc(VideoEditorPlugin)
public class VideoEditorPlugin: CAPPlugin {
    private var call: CAPPluginCall?
    private var settings = VideoSettings(maxVideos: 0, amountThumbnails: 1)
    
    
    
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
        self.settings.amountThumbnails = call.getInt("amountThumbnails") ?? 1
        
        DispatchQueue.main.async {
            self.showVideos()
        }
    }
    
    @objc func trim(_ call: CAPPluginCall) {
        self.call = call
        let path = call.getString("path") ?? ""
        let start = call.getString("start") ?? ""
        let end = call.getString("end") ?? ""
        let fileExtension = call.getString("extension") ?? ""
        
        trimVideo(start: start,end: end, path: path, fileExtension: fileExtension)
    }
    
    @objc func concatVideos(_ call: CAPPluginCall) {
        self.call = call
        
        let audio = call.getString("audio")
        
        let items = call.getArray("videos") ?? JSArray()
        
        let amountThumnails = call.getInt("amountThumbnails") ?? 1
    
        
        var concatItems: [ConcatItem] = [];
        
        for item in items{
            guard let trimItem = item as? NSDictionary else {
                call.reject("Bad request")
                return
            }
            guard let path = trimItem["path"] as? String else  {
                call.reject("Bad request")
               return
            }
            guard let start = trimItem["start"] as? String else  {
                call.reject("Bad request")
               return
            }
            guard let duration = trimItem["duration"] as? String else  {
                call.reject("Bad request")
               return
            }
            
            
            
            let item = ConcatItem(path: path, start: start, duration: duration)
            
            
            concatItems.append(item)
            
        }
        
        let filterCommand = getFilterCommand(videos: concatItems, audio: audio)
        
        var inputCommands = "";
        for video in concatItems  {
            inputCommands = "\(inputCommands) \(getInputCommand(path: video.path))"
        }
        
        if audio != nil {
           inputCommands = "\(inputCommands) \(getInputCommand(path: audio!))"
        }
        
        let outputName = getRandomFileName(prefix: "concat_video", pathExtension: "mp4")
        let outputUrl = getUrl(fileName: outputName)
        let y = " -y"
        
        // let filterCommand = getFilterCommand(amountVideos: count, start: "00:00:05.5", duration: "00:00:02.5")
        let command = inputCommands + filterCommand + outputUrl.absoluteString + y
        
        FFmpegKit.executeAsync(command, withExecuteCallback: {Session in
            let state = Session?.getState() ?? SessionState.failed
            print("STATE: \(state)")
            if (state == SessionState.failed){
                self.call?.reject("Error trimming video")
            }
            if (state == SessionState.completed){
                guard let webPath = self.bridge?.portablePath(fromLocalURL: outputUrl) else {
                    self.call?.reject("Unable to get portable path to file")
                    return
                }

                let info = FFprobeKit.getMediaInformation(outputUrl.absoluteString).getMediaInformation();
                let duration = info?.getDuration() ?? ""
                let size = info?.getSize()
                print("hello from thumbnail amount \(amountThumnails)")
                for n in [amountThumnails] {
                    print("hello from thumbnail \(n)")
                }
    
                
               // let thumb = self.getThumbnail(url: outputUrl, at: "00:00:01.000")
                let thumbnails = self.getThumbnail(url: outputUrl, duration: duration)

                let video: PluginCallResultData = [
                    "webPath": webPath.absoluteString,
                    "thumbnails": thumbnails,
                    "duration" : duration,
                    "path": outputUrl.absoluteString,
                    "extension": "mp4",
                    "size": size ?? ""
                ]

                self.call?.resolve(video);
            }


        })}
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
                    print("hello from thumbnail amount raw \(self.settings.amountThumbnails)")
                    
                    
                    let info = FFprobeKit.getMediaInformation(newUrl.absoluteString).getMediaInformation();
                    let duration = info?.getDuration() ?? ""
                    let fileExtension = URL(fileURLWithPath: info?.getFilename() ?? "").pathExtension
                    
                    // let thumb = self.getThumbnail(url: newUrl, at: "00:00:01.000")
                    
                    
                    let thumbnails = self.getThumbnail(url: newUrl, duration: duration)
                    
                    // print("GOT INFORMATION ON VIDEO DURATION", thumbnails)
                    
                    
                    let video: PluginCallResultData = [
                        "webPath": test.absoluteString,
                        "thumbnails": thumbnails,
                        "duration" : duration,
                        "path": newUrl.absoluteString,
                        "extension": String(fileExtension)
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
    
    
    
    func trimVideo(start: String, end: String, path: String, fileExtension: String) {
        let input = "-i \(path)"
        let seek = " -ss \(start)"
        let to = " -to \(end)"
        let copy = " -async -1 "
        print("ORIGINAL EXTENSUIN \(fileExtension)")
        let fileName = "cut_video_\(Int(Date().timeIntervalSince1970))\(UUID().uuidString).mp4"
        let scale = " -vf scale=w=576:h=1024:force_original_aspect_ratio=decrease -preset slow -crf 18 "
        
        
        let outputPath = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
        
        
        let command = input + seek + to + copy + scale + outputPath.absoluteString
        
        print("executing trim with command: \(command) and path: \(outputPath)")
        
        
        FFmpegKit.executeAsync(command, withExecuteCallback: {Session in
            let state = Session?.getState() ?? SessionState.failed
            print("STATE: \(state)")
            if (state == SessionState.failed){
                self.call?.reject("Error trimming video")
            }
            if (state == SessionState.completed){
                guard let webPath = self.bridge?.portablePath(fromLocalURL: outputPath) else {
                    self.call?.reject("Unable to get portable path to file")
                    print("error video")
                    return
                }
                
                let info = FFprobeKit.getMediaInformation(outputPath.absoluteString).getMediaInformation();
                let duration = info?.getDuration()
                
                let video: PluginCallResultData = [
                    "webPath": webPath.absoluteString,
                    "thumbnail": "",
                    "duration" : duration ?? "",
                    "path": outputPath.absoluteString,
                    "extension": String(fileExtension)
                ]
                
                self.call?.resolve(video);
            }
            
            
        })
        
    }

    
    func getInputCommand(path: String) -> String{
        return "-i \(path)"
    }
    
    func getFilterCommand(videos: [ConcatItem], audio: String?) -> String{
        let width = "1080"
        let height = "1920"
        func getVideoFilter(index: Int) -> String {
            return "[\(index):v]scale=w=\(width):h=\(height):force_original_aspect_ratio=decrease,pad=\(width):\(height):(ow-iw)/2:(oh-ih)/2,fps=24,setpts=PTS-STARTPTS[resize\(index)];"
        }
        
        func getAudioFilter(index: Int) -> String{
            return "[\(index):a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,volume=0.2,asetpts=PTS-STARTPTS[audio\(index)];"
        }
        
        func getTrimVideo(index: Int, start: String, end: String) -> String {
            return "[resize\(index)]trim=start=\(start):end=\(end),setpts=PTS-STARTPTS[ag\(index)];"
        }
        func getTrimAudio(index: Int, start: String, end: String) -> String{
            return "[audio\(index)]atrim=start=\(start):end=\(end),asetpts=PTS-STARTPTS[au\(index)];"
        }
        
        
        // do we really need this? audio should not be regualted for videos that don't have voice overlay
        
        func getTrimAudioLowerVolume(index: Int, start: String, end: String) -> String{
            return "[audio\(index)]atrim=start=\(start):end=\(end),asetpts=PTS-STARTPTS[au\(index)];"
        }
        
        func getVideo(index: Int) -> String{
            return "[ag\(index)]"
        }
        
        func getAudio(index: Int) -> String{
            return "[au\(index)]"
        }
        
        func getConcat(amount: Int) -> String {
            return "concat=n=\(amount):v=1:a=1[v][a]"
        }
        
        func getAudioMixer(index: Int) -> String {
            return ";[a][\(index)]amix[a]"
        }
        
        var commandString = " -filter_complex \""
        
        var i = 0
        while i < videos.count {
            commandString = "\(commandString)" + getVideoFilter(index: i)
            i += 1
        }
        
        i = 0
        while i < videos.count {
            commandString = "\(commandString)" + getAudioFilter(index: i)
            i += 1
        }
        
        
        i = 0
        while i < videos.count {
            commandString = "\(commandString)" + getTrimVideo(index: i, start: videos[i].start, end: videos[i].duration)
            i += 1
        }
        
        if audio != nil {
            i = 0
            while i < videos.count {
                commandString = "\(commandString)" + getTrimAudioLowerVolume(index: i, start: videos[i].start, end: videos[i].duration)
                i += 1
            }
        } else {
            i = 0
            while i < videos.count {
                commandString = "\(commandString)" + getTrimAudio(index: i, start: videos[i].start, end: videos[i].duration)
                i += 1
            }
        }
        
        
        
        i = 0
        while i < videos.count {
            commandString = "\(commandString)" + getVideo(index: i) + getAudio(index: i)
            i += 1
        }
        
        commandString = "\(commandString)" + getConcat(amount: videos.count)
        
        
        if audio != nil {
            commandString = "\(commandString)" + getAudioMixer(index: videos.count)
        }
        
        commandString = commandString + "\" -map [v] -map [a] "
        
        if audio != nil {
            commandString = commandString + "-map \(videos.count):a "
        }
    
        
        return commandString
    }
    
    func getRandomFileName(prefix: String, pathExtension: String) -> String{
            return "\(prefix)\(Int(Date().timeIntervalSince1970))\(UUID().uuidString).\(pathExtension)"
    }
    
    func getUrl(fileName: String) -> URL{
        return URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
    }
    
    func getThumbnail(url: URL, duration: String)-> [String]{
        let amount = self.settings.amountThumbnails
        let amountThumbnailsArray = Array(1...amount)
        let durationDouble = Double(duration)  ?? 0.0
        let interval: TimeInterval = (durationDouble - 0.002) / Double(amount)
        let string1 = "-i ";
        let string2 = " -vf fps=1/\(interval) ";
        let uuid = UUID().uuidString
        let thumbFileName = "thumb_\(uuid)_\u{0025}d.jpg";
        let thumbUrl = URL(fileURLWithPath: NSTemporaryDirectory() + thumbFileName).absoluteString.removingPercentEncoding ?? ""
        let y = " -y"

        let command = string1 + url.absoluteString + string2 + thumbUrl + y;
        
        FFmpegKit.execute(command);
        
        var thumbnails: [String] = []
        
        for n in amountThumbnailsArray {
            let url = URL(fileURLWithPath: NSTemporaryDirectory() + "thumb_\(uuid)_\(n).jpg")
            print("url out \(url)")
            guard  let thumb = self.bridge?.portablePath(fromLocalURL: url) else {
                self.call?.reject("Unable to get portable path to file")
                return []
            }
            thumbnails.append(thumb.absoluteString)
        }
        return thumbnails
    }
}


