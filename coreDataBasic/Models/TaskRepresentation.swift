//
//  TaskRepresentation.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/14/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import Foundation

struct TaskRepresentation: Codable {
    var name: String
    var notes: String?
    var priority: String
    var identifier: String
}


