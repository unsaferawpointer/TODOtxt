//
//  RefreshableScrollView.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol RefreshableScrollViewDelegate {
    func startResfresh()
}

enum State {
    case none(offset: Int), up(offset: Int), down(offset: Int), refreshing(offset: Int)
}

class RefreshableScrollView: NSScrollView {
    
    var delegate: RefreshableScrollViewDelegate?
    
    let OFFSET = -80
    var state: State = .none(offset: 0)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(_:)), name: NSView.boundsDidChangeNotification, object: self.contentView)
        self.state = .none(offset: Int(self.contentView.bounds.origin.y))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(_:)), name: NSView.boundsDidChangeNotification, object: self.contentView)
        self.state = .none(offset: Int(self.contentView.bounds.origin.y))
    }
    
    @objc func boundsDidChange(_ notification: NSNotification){
        
        guard notification.object is NSClipView else { return }
        //print(notification.object)
        //guard sender is NSClipView else { return }
        let bounds = self.contentView.bounds
        let y = Int(bounds.origin.y)
        //print("y = \(y)")
        //print("frame = \(self.contentView.frame)")
        //print("bounds = \(self.contentView.bounds)")
        switch state {
        case .none(let offset):
            let delta = y - offset
            if delta == 0 {
                self.state = .none(offset: y)
            } else if delta < 0 {
                self.state = .down(offset: y)
            } else {
                self.state = .up(offset: y)
            }
        case .up(let offset):
            if offset < OFFSET {
                self.state = .refreshing(offset: y)
            } else {
                let delta = y - offset
                if delta == 0 {
                    self.state = .none(offset: y)
                } else if delta < 0 {
                    self.state = .down(offset: y)
                } else {
                    self.state = .up(offset: y)
                }
            }
        case .down(let offset):
            
            if offset < OFFSET {
                self.state = .refreshing(offset: y)
                delegate?.startResfresh()
            } else {
                let delta = y - offset
                if delta == 0 {
                    self.state = .none(offset: y)
                } else if delta < 0 {
                    self.state = .down(offset: y)
                } else {
                    self.state = .up(offset: y)
                }
            }
            
        case .refreshing(let offset):
            if offset < OFFSET {
                self.state = .refreshing(offset: y)
            } else {
                let delta = y - offset
                if delta == 0 {
                    self.state = .none(offset: y)
                } else if delta < 0 {
                    self.state = .down(offset: y)
                } else {
                    self.state = .up(offset: y)
                    print("refresh")
                }
            }
        }
        
        print("state = \(state)")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
