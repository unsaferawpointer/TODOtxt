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
    static let badgeFilterDidChange = Notification.Name("badgeFilterDidChange")
    static let showBadgeDidChange = Notification.Name("showBadgeDidChange")
}


enum Appearance: String, CaseIterable {
    
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var name: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
}

class Preferences {
    
    static let shared: Preferences = Preferences()
    
    var themePairs: [ThemePair] = []
    var theme: Theme {
        
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
    
    // -------- BADGE_FILTER --------
    let SHOW_BADGE_KEY = "show_badge_key"
    var showBadge = false {
        didSet {
            let value = badgeFilter?.predicateFormat
            userDefaults.set(value, forKey: BADGE_FILTER_KEY)
            NotificationCenter.default.post(name: .showBadgeDidChange, object: nil)
        }
    }
    
    let BADGE_FILTER_KEY = "badge_filter_key"
    var badgeFilter: NSPredicate? {
        didSet {
            let value = badgeFilter?.predicateFormat
            userDefaults.set(value, forKey: BADGE_FILTER_KEY)
            NotificationCenter.default.post(name: .badgeFilterDidChange, object: nil)
        }
    }
    
    // -------- APPEARANCE --------
    let APPEARANCE_KEY = "appearance_key"
    var appearance: Appearance = .system {
        didSet {
            let value = appearance.rawValue
            userDefaults.set(value, forKey: APPEARANCE_KEY)
            NotificationCenter.default.post(name: .appearanceDidChange, object: nil)
        }
    }
    
    // -------- THEME --------
    let THEME_PAIR_INDEX_KEY = "theme_pair_index"
    var themePairIndex: Int = 0
    
    private init() {
        
        userDefaults.register(defaults: [THEME_PAIR_INDEX_KEY : NSNumber(value: 0)])
        self.themePairIndex = userDefaults.index(forKey: THEME_PAIR_INDEX_KEY)
        
        userDefaults.register(defaults: [APPEARANCE_KEY : "system"])
        let appearanceValue = userDefaults.string(forKey: APPEARANCE_KEY)!
        self.appearance = Appearance(rawValue: appearanceValue)!
        
        userDefaults.register(defaults: [BADGE_FILTER_KEY : "context = 'example'"])
        let badgeFilterValue = userDefaults.string(forKey: BADGE_FILTER_KEY)!
        self.badgeFilter = NSPredicate(format: badgeFilterValue, argumentArray: nil)
        
        userDefaults.register(defaults: [SHOW_BADGE_KEY : false])
        self.showBadge = userDefaults.bool(forKey: SHOW_BADGE_KEY)
        
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
    
    // ********** Set **********
    func setTheme(index: Int) {
        self.themePairIndex = index
        userDefaults.set(index: index, forKey: THEME_PAIR_INDEX_KEY)
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }
    
}

