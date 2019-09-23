//
//  DocumentController.swift
//  TODOtxt
//
//  Created by subzero on 22/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class DocumentController: NSDocumentController {
    
    open override func addDocument(_ document: NSDocument) {
        super.addDocument(document)
        print(#function)
        updateCount()
    }

    open override func removeDocument(_ document: NSDocument) {
        super.removeDocument(document)
        print(#function)
        updateCount()
    }
    
    private func updateCount() {
        var count = 0
        for document in documents as! [Document] {
            count += document.badgeCount
            print("newCount = \(count)")
        }
        NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)": nil
    }
    
}
