//
//  Storage.swift
//  TODOtxt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

enum DataError: Error {
    case overflow, invalidFormat
}



class ParserOperation: Operation {
    
    var taskStorage: TaskStorage = TaskStorage()
    var string: String = ""
    
    init(string: String) {
        self.string = string
    }
    
    override func main() {
        //sleep(1)
        let parser = Parser()
        let array = parser.parse(string: string)
        self.taskStorage = TaskStorage(tasks: array)
    }
    
}

class TaskStorage {
    
    private (set) var storage: [Task] 
    private(set) var hashtagsStorage: Bag<String> = Bag<String>()
    
    init() {
        self.storage = [Task]()
    }
    
    init(tasks: [Task]) {
        self.storage = tasks
        insert(tasks)
    }
    
    func reload(_ str: String) {
        let parser = Parser()
        let tasks = parser.parse(string: str)
        self.storage = []
        self.hashtagsStorage = Bag<String>()
        insert(tasks)
    }
    
    // ******** basic operation ********
    
    func insert(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        hashtagsStorage.insert(mentions)
        storage.append(contentsOf: tasks)
    }
    
    func remove(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        hashtagsStorage.remove(mentions)
        for task in tasks {
            if let index = storage.firstIndex(of: task) {
                storage.remove(at: index)
            } else {
                fatalError("TaskStorage don`t contains task = \(task)")
            }
        }
    }
    
    
    
}

extension TaskStorage {
    
    var count: Int {
        return storage.count
    }
    
    var mentions: [String] {
        return hashtagsStorage.storage
    }
    
}

