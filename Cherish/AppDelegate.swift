//
//  AppDelegate.swift
//  Cherish
//
//  Created by Mikhail Vyrtsev on 06.07.2022.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    private var shareController = ShareController()
    var urls: [URL] = []
    weak var timer: Timer?
    weak var execTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApplication.shared.servicesProvider = self
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if(NSApplication.shared.windows.count < 2) {
                #if !DEBUG
                exit(0)
                #else
                AppLogger.log("DEBUG EXIT")
                self?.timer?.invalidate()
                self?.timer = nil
                #endif
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        addToQueue([filename].map{ URL(fileURLWithPath: $0) })
        return true
    }
        
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        addToQueue(filenames.map{ URL(fileURLWithPath: $0) })
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        addToQueue(urls)
    }
    
    @objc
    func doString(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        let items = pboard.pasteboardItems?.compactMap { item -> Any? in
            guard let string = item.string(forType: .string) else { return nil }
            return toDataUrl(string: string)
        }
     
        shareController.share(items)
    }
    
    private func addToQueue(_ urls: [URL]) {
        self.urls.append(contentsOf: urls)
        execTimer?.invalidate()
        self.execTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] timer in
            self?.processFiles()
        }
    }
    
    private func processFiles() {
        if urls.isEmpty { return }
        AppLogger.info("Share \(self.urls.count) items")
        shareController.share(urls)
        urls.removeAll()
    }
    
    private func toDataUrl(string: String) -> URL {
        let encoded = Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "data:application/octet-stream;base64,\(encoded)")!
    }
}
