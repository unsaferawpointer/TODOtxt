//
//  FilterViewController.swift
//  TODOtxt
//
//  Created by subzero on 04/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class FilterViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    @objc var selectedIndex: Int = 0 {
        didSet {
            print("selectedIndex = \(selectedIndex)")
            isHidden = !(templatesPopUpButton.lastItem == templatesPopUpButton.item(at: selectedIndex))
        }
    }

    
    @IBOutlet weak var nameTextfield: NSTextField!
    @IBOutlet weak var conditionTextfield: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var templatesPopUpButton: NSPopUpButton!
    
    var filter: Filter?
    
    @objc var isHidden: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
        conditionTextfield.delegate = self
        
        
    }
    
    
    @IBAction func buttonClicked(_ sender: Any) {
        print(#function)
    }
    
    
    
}

extension FilterViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        print(#function)
        
    }
}
