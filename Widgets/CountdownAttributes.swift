// Shared between the iOS app and the widget extension.
import ActivityKit
import Foundation

struct CountdownAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var end: Date
    }
}
