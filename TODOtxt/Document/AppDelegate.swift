//
//  AppDelegate.swift
//  TODOtxt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadge(_:)), name: .showBadgeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadge(_:)), name: .badgeFilterDidChange, object: nil)
    }
    
    
    @objc func updateBadge(_ sender: Any) {
        
        let showBadge = Preferences.shared.showBadge
        if showBadge {
            var count = 0
            for document in DocumentController.shared.documents as! [Document] {
                count += document.badgeCount
            }
            NSApplication.shared.dockTile.badgeLabel = "\(count)"
        } else {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}

