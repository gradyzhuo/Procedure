//
//  Protocols.swift
//  Procedure
//
//  Created by Grady Zhuo on 18/12/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public protocol RunnableStep : Identitiable {
    func run(withGifts: Intents)
}

internal protocol _RunnableStep {
    var _previous: RunnableStep? { set get }
}

public protocol SimpleStep : RunnableStep, SequenceStep {
    var previous: RunnableStep? { get }
    var next: SimpleStep? { set get }
}

extension SimpleStep {
    
    public var last:SimpleStep{
        var next: SimpleStep = self
        
        while let n = next.next {
            next = n
        }
        
        return next
    }
    
    public mutating func `continue`<T:SimpleStep>(byStep step:T)->T{
        var last = self.last
        last.next = step
        return step
    }
    
}

public protocol SequenceStep: RunnableStep {
    var last:SimpleStep { get }
    
    @discardableResult mutating func `continue`<T:SimpleStep>(byStep step:T)->T
}

public protocol Copyable : class, NSCopying{ }

extension Copyable {
    
    public var copy: Self {
        return self.copy(with: nil) as! Self
    }
    
}

public protocol ActionTrigger {
    var actions: [Action] { get }
    
    init(actions: [Action])
    
    func add(actions: [Action])
}
