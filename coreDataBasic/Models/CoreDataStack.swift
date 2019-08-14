//
//  CoreDataStack.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/11/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    // stored property
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Task")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        })
        //make sure view context automatically merges to parent - NSPersistent container being merged into main view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    //computed property
    var mainContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    //this is going to replace saveToPersistentStroe which is not currencty being run in performAndWait correctly
    func save(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        var error: Error?
        
        //could be the main context or a background context
        context.performAndWait {
            do {
                try context.save()
            } catch let saveError {
                error = saveError
            }
        }
        if let error = error {throw error}
    }
}
