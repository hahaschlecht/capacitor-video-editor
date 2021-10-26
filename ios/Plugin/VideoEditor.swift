import Foundation

@objc public class VideoEditor: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
