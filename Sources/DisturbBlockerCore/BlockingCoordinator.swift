import Foundation

public final class BlockingCoordinator {
    private let appEngine: AppBlockingEngine
    private let browserEngine: BrowserBlockingEngine

    public init(appEngine: AppBlockingEngine = AppBlockingEngine(), browserEngine: BrowserBlockingEngine = BrowserBlockingEngine()) {
        self.appEngine = appEngine
        self.browserEngine = browserEngine
    }

    public func enforce(mode: BlockMode) -> [BlockEvent] {
        appEngine.enforce(mode: mode) + browserEngine.enforce(mode: mode)
    }
}
