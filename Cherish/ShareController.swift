//
//  ShareController.swift
//  Cherish
//
//  Created by Mikhail Vyrtsev on 03.07.2022.
//

import Foundation
import AppKit

class ShareController: NSObject, NSSharingServiceDelegate {
    var afterShare: (() -> Void)? = nil
    
    func share(_ items: [Any]?) {
        guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop) else {
            AppLogger.error("No sharing service available")
            return
        }

        if !service.canPerform(withItems: items) {
            AppLogger.error("Can't perform: file is likely to be nonexistent.")
            return
        }
        
        service.delegate = self
        service.perform(withItems: items!)
    }

    func sharingService(_ sharingService: NSSharingService, willShareItems items: [Any]) {
        AppLogger.info("Sending \(items.count) files")
        afterShare?()
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        AppLogger.info("\(items.count) files were sent")
        afterShare?()
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        AppLogger.error("Share failed: \(error.localizedDescription)")
        afterShare?()
    }
}
