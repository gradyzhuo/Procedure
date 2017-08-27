//
//  ConditionStep.swift
//  Procedure
//
//  Created by Grady Zhuo on 12/07/2017.
//  Copyright © 2017 Grady Zhuo. All rights reserved.
//

import Foundation

open class ConditionStep : SimpleStep {
    public lazy var name: String = self.identifier
    public private(set) var predicate: NSPredicate
    public var next: SimpleStep?
    
    public func run(with intents: Intents) {
        
    }
    
    public init(predicateFormat format: String, _ arguments: CVarArg...) {
        predicate = NSPredicate(format: format, argumentArray: arguments)
    }
    
    public init(predicateFormat format: String, arguments: [Any]) {
        predicate = NSPredicate(format: format, argumentArray: arguments)
    }
}
