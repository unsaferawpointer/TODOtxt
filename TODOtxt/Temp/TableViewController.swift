//
//  TableViewController.swift
//  TODOtxt
//
//  Created by subzero on 20/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class Node: NSObject {
    
    @objc var name: String
    @objc var children: [Node] = []
    @objc var count: Int { return children.count }
    @objc var isLeaf: Bool { return children.isEmpty }
    
    init(name: String, children: [Node] = []) {
        self.name = name
        self.children = children
    }
}

class TableViewController: NSViewController {
    
    var storage: TaskStorage?
    @objc dynamic var nodes: [Node] = [Node(name: "+travel", children: [Node(name: "(A) Do it +travel"), Node(name: "(B) Then do that +travel")])]
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        guard storage != nil else { return }
        
        let array = storage!.storage.compactMap { (element) -> Task? in
            return element as? Task
        }
        
        let dictionary = Dictionary(grouping: array) { (element) -> String in
            return element.context ?? "empty"
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key < rhs.key
        }
        
        /*
        nodes = data.flatMap { (element) -> Node in
            return Node(name: element.key, children: element.value)
        }
 */
        
        
    }
    
    private func reload() {
        let array = storage!.storage.compactMap { (element) -> Task? in
            return element as? Task
        }
        
        let dictionary = Dictionary(grouping: array) { (element) -> String in
            return element.context ?? "empty"
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key < rhs.key
        }
        
        /*
        nodes = data.flatMap { (element) -> Node in
            return Node(name: element.key, children: element.value)
        }*/
    }
    
    
    
}
