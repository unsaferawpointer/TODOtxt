//
//  Preferences.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

extension UserDefaults {
    func index(forKey key: String) -> Int {
        return (value(forKey: key) as! NSNumber).intValue
    }
    
    func set(index: Int, forKey key: String) {
        self.setValue(NSNumber(value: index), forKeyPath: key)
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name(rawValue: "styleDidChange")
    static let markStyleDidChange = Notification.Name("markStyleDidChange")
    static let appearanceDidChange = Notification.Name("appearanceDidChange")
}


enum Appearance: Int, CaseIterable {
    case system = 0, light, dark
    var name: String {
        switch self {
        case .system:
            return "Auto"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
}

class Preferences {
    
    static let shared: Preferences = Preferences()
    
    var items: [Item] = []
    
    var themePairs: [ThemePair] = []
    var theme: Theme {
        let appearance = Appearance(rawValue: appearanceIndex)!
        var themePair = themePairs[0]
        if themePairIndex < themePairs.count {
            themePair = themePairs[themePairIndex]
        }
        
        switch appearance {
        case .system:
            return isDarkMode ? themePair.dark : themePair.light
        case .light:
            return themePair.light
        case .dark:
            return themePair.dark
        }
    }
    
    var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    let APPEARANCE_INDEX_KEY = "appearance_index_key"
    var appearanceIndex: Int = 0
    
    let THEME_PAIR_INDEX_KEY = "theme_pair_index"
    var themePairIndex: Int = 0
    
    let MARK_STYLE_INDEX_KEY = "mark_style_index"
    var markStyleIndex: Int = 0
    
    private init() {
        
        userDefaults.register(defaults: [THEME_PAIR_INDEX_KEY : NSNumber(value: 0)])
        self.themePairIndex = userDefaults.index(forKey: THEME_PAIR_INDEX_KEY)
        
        userDefaults.register(defaults: [APPEARANCE_INDEX_KEY : NSNumber(value: 0)])
        self.appearanceIndex = userDefaults.index(forKey: APPEARANCE_INDEX_KEY)
        
        userDefaults.register(defaults: [MARK_STYLE_INDEX_KEY : NSNumber(value: 0)])
        self.markStyleIndex = userDefaults.index(forKey: MARK_STYLE_INDEX_KEY)
        
        configureThemes()
    }
    
    private func configureThemes() {
        self.themePairs = []
        if  let path = Bundle.main.path(forResource: "Themes", ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path) {
            let data = try! PropertyListSerialization.propertyList(from: xml, options:.mutableContainersAndLeaves, format: nil) as! [[String: Any]]
            for dictionary in data {
                let name = dictionary["name"] as! String
                let light = dictionary["light"] as! [String : String]
                let dark = dictionary["dark"] as! [String : String]
                let lightTheme = Theme(scheme: light)
                let darkTheme = Theme(scheme: dark)
                let themePair = ThemePair(name: name, light: lightTheme, dark: darkTheme)
                themePairs.append(themePair)
            }
        }
    }
    
    public var isDarkMode: Bool {
        let isDarkMode: Bool
        
        if #available(macOS 10.14, *) {
            let appearance = NSApplication.shared.effectiveAppearance
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                isDarkMode = true
            } else {
                isDarkMode = false
            }
        } else {
            isDarkMode = false
        }
        
        return isDarkMode
    }
    
    // ********** Set **********
    
    func setTheme(index: Int) {
        self.themePairIndex = index
        userDefaults.set(index: index, forKey: THEME_PAIR_INDEX_KEY)
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }
    
    func setAppearance(index: Int) {
        
        let oldTheme = theme
        
        self.appearanceIndex = index
        userDefaults.set(index: index, forKey: APPEARANCE_INDEX_KEY)
        
        guard oldTheme != theme else { return }
        
        NotificationCenter.default.post(name: .appearanceDidChange, object: nil)
    }
    
    func setMarkStyle(index: Int) {
        self.markStyleIndex = index
        userDefaults.set(index: index, forKey: MARK_STYLE_INDEX_KEY)
        NotificationCenter.default.post(name: .markStyleDidChange, object: nil)
    }
    
}

