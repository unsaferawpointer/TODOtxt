//
//  Document.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var badgeCount: Int {
        return 0
    }
    
    var str: String = ""
    
    // Document has only one NSWindowController
    var textViewController: TextViewController? {
        guard windowControllers.count > 0 else { return nil }
        return windowControllers[0].contentViewController as? TextViewController
    }
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        Swift.print(#function)
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
        if let contentView = textViewController {
            contentView.objectValue = str
            contentView.taskDocumentView.delegate = self
        }
        
    }
    
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        if let data = textViewController?.taskDocumentView.data {
            return data
        } else {
            return Data()
        }
        
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        Swift.print(#function)
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        guard let str = String(data: data, encoding: .utf8) else { throw DataError.invalidFormat }
        guard str.count <= 4000 else { throw DataError.overflow}
        self.str = str
        textViewController?.objectValue = str
    }
    
}

extension Document: TaskDocumentViewDelegate {
    func dataDidChange() {
        updateChangeCount(.changeDone)
    }
}
