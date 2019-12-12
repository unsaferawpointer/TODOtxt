//
//  Token.swift
//  TODOtxt
//
//  Created by subzero on 21.11.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

protocol LineObject {
    var string: String { get }
    var body: String { get }
}

protocol TokenProtocol {
    var value: Any { get }
    var rawValue: String { get }
}

struct Token<T> {
    
    var value: T
    
    var valueRange: NSRange
    var enclosingRange: NSRange
}

struct MarkToken {
    
    var value: String
    
    var prefixRange: NSRange
    var markRange: NSRange
    var enclosingRange: NSRange
    
}

struct EventDateToken {
    
    var value: Date
    
    var timeRange: NSRange
    var dateRange: NSRange
    var dateTimeRange: NSRange
    
}

/// For app defined key word. Example @due(2019-10-10 12:30) @ - prefix, due - keyWord, 2019-10-10 12:30 - parameter
struct KeywordToken<T> {
    
    var prefix: String
    
    var value: T
    var rawValue: String
    
    var prefixRange: NSRange
    var keywordRange: NSRange
    var enclosingRange: NSRange
}

/// For task date token
struct DateToken {
    
    var value: Date
    
    //var prefixRange: NSRange
    //var keywordRange: NSRange
    //var timeRange: NSRange
    //var dateRange: NSRange
    var dateTimeRange: NSRange
    var enclosingRange: NSRange
    
}


struct HashtagToken {
    
    var value: String
    
    var prefixRange: NSRange
    var wordRange: NSRange
    var enclosingRange: NSRange
    
}
