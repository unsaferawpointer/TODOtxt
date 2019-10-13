//
//  TextViewController.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa



class TextViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    @IBOutlet weak var taskDocumentView: TaskDocumentView!
    
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    var objectValue: String = "" {
        didSet {
            taskDocumentView.reload(str: objectValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        
        //invalidateTheme()
        
        //scrollView.delegate = textview
        
        
        // ---------- setup notifications ----------
        //NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: .themeDidChange, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange(_:)), name: .appearanceDidChange, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(reload(_:)), name: .badgeFilterDidChange, object: nil)
        
    }
    
    @objc func themeDidChange(_ notification: Notification) {
        print(#function)
        //invalidateTheme()
    }
    
    @objc func appearanceDidChange(_ notification: Notification) {
        print(#function)
        //invalidateTheme()
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}





