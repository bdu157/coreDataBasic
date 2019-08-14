//
//  Task+Convenience.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/11/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import Foundation
import CoreData

enum TaskPriority: String {
    case low
    case normal
    case high
    case critical
    
    
    //to use segmentedContol which goes by Int 0 - low, 1 - normal, 2 - high, 3 - critical
    static var allPriorities: [TaskPriority] {
        return [.low, .normal, .high, .critical]
    }
}

extension Task {  //created by CoreData
    
    var taskRepresentation: TaskRepresentation? {
        guard let name = self.name,
            let priority = priority else { return nil} //making sure we have these two
        return TaskRepresentation(name: name, notes: notes, priority: priority, identifier: identifier?.uuidString ?? "")
    }
    
    //initializing task object
    convenience init(name: String, notes: String? = nil, priority: TaskPriority = .normal, idenfitier: UUID = UUID(),context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
        self.identifier = idenfitier
    }
    
    //another one to take taskRepresentation - initializing task object from taskRepresentation
    convenience init?(taskRepresentation: TaskRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let priority = TaskPriority(rawValue: taskRepresentation.priority),
            let identifier = UUID(uuidString: taskRepresentation.identifier) else {return nil}
        
        self.init(name: taskRepresentation.name,
                  notes: taskRepresentation.notes,
                  priority: priority,
                  idenfitier: identifier,
                  context: context)
    }
}

//to turn a normal into taskRespresentation

