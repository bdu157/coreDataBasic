//
//  TaskController.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/14/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import Foundation
import CoreData

let baseURL = URL(string: "https://task-coredata.firebaseio.com/")!

class TaskController {
    
    typealias CompletionHandler = (Error?) -> Void
    
    init() {
        fetchTaskFromServer()
    }
    
    // Fetch the Tasks from the server
    func fetchTaskFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching tasks: \(error)")
                completion(error)
                return
            }
            guard let data = data else {
                NSLog("no data returned by the data task")
                completion(NSError())
                return
            }
            
            do {
                let taskRepresentations = Array(try JSONDecoder().decode([String: TaskRepresentation].self, from: data).values)
                try self.updateTasks(with: taskRepresentations)
                completion(nil)
            } catch {
                NSLog("Error decoding task representations: \(error)")
                completion(error)
            }
        }.resume()
    }
    
            //comparing what we have in CoreData
            private func updateTasks(with representations: [TaskRepresentation]) throws {
                for taskRep in representations {
                    guard let uuid = UUID(uuidString: taskRep.identifier) else { continue}
                    
                    let task = self.task(forUUID: uuid)
                    
                    if let task = task {
                        self.update(task: task, with: taskRep)
                    }  else {
                        let _ = Task(taskRepresentation: taskRep)
                    }
                }
                try self.saveToPersistentStore()
                }
    
                    //Get task from UUID - one task from coreData to compare this to fetcheddata from firebase
                    private func task(forUUID uuid: UUID) -> Task? {
                        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "identifier == %@", uuid as NSUUID)  //%@ is an argument - UUID here is because in coreData identifier datatype is UUID
                        
                        do {
                            let moc = CoreDataStack.shared.mainContext
                            return try moc.fetch(fetchRequest).first //just one of tasks
                        } catch {
                            NSLog("Error fetching task with uuid \(uuid): \(error)")
                            return nil
                        }
                    }
    
                    //updating app data after comparing coredata and firebase
                    private func update(task: Task, with representation: TaskRepresentation) {
                        task.name = representation.name
                        task.notes = representation.notes
                        task.priority = representation.priority
                    }
    
    //PUT request
    func put(task: Task, completion: @escaping CompletionHandler = { _ in }) {
        
        let uuid = task.identifier ?? UUID()  //this is just having uuid (identifier) fom task being passed in as a parameter
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        guard var representation = task.taskRepresentation else {  //computed property taskRepresentation
            completion(NSError())
            return
        }
        
        representation.identifier = uuid.uuidString  //assigning identifier of computed property to uuid.uuidString as same as uuid.uuidString being used above
        task.identifier = uuid  //this should match so locally with this and server above will have same UUID(), this is because we want to have same UUID for coreData and firebase
        do {
            try saveToPersistentStore() //saving this into coreData in addition to putting it to server below
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task \(task): \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_ , _, error) in
            if let error = error {
                NSLog("Error Putting task to server: \(error)")
                completion(error)
                return
            }
            completion(nil)
        }.resume()
    }
    
    func saveToPersistentStore() throws {
        let moc = CoreDataStack.shared.mainContext
        try moc.save()
    }
    
    //delete from server
    func deleteTaskFromServer(_ task: Task, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = task.identifier else {
            completion(NSError())
            return
        }
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            print(response!)
            completion(error)
        }.resume()
    }
}
