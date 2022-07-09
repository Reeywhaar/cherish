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
    var filenames: [String] = []
    weak var timer: Timer?
    
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
        filenames.append(filename)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: processFiles)
        return true
    }
        
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        self.filenames.append(contentsOf: filenames)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: processFiles)
    }
    
    @objc
    func doString(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        let strs = pboard.readObjects(forClasses: [NSAttributedString.self, NSURL.self]) ?? []
        let items = strs.compactMap { str -> URL? in
            if let str = str as? NSAttributedString {
                for attr in str.attributes(at: 0, effectiveRange: nil) {
                    if attr.key != .link { continue }
                    if let url = attr.value as? URL { return url }
                    if let linkstr = attr.value as? String,
                       let url = URL(string: linkstr ) { return url }
                }
                
                if let url = URL(string: str.string) { return url }
                return toDataUrl(string: str.string)
            }
            
            if let url = str as? NSURL { return url as URL }
            
            return nil
        }
     
        shareController.share(items)
    }
    
    private func processFiles() {
        if filenames.isEmpty { return }
        AppLogger.info("Share \(self.filenames.count) files")
        shareController.share(filenames.map{ URL(fileURLWithPath: $0) })
        filenames.removeAll()
    }
    
    private func toDataUrl(string: String) -> URL {
        let encoded = Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "data:application/octet-stream;base64,\(encoded)")!
    }
}
