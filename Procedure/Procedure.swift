//
//  Procedure.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

open class Procedure : SimpleStep {
    
    public private(set) var first: SimpleStep
    public private(set) var last: SimpleStep
    
    public var next: SimpleStep?{
        set{
            last.next = newValue
        }
        get{
            return last.next
        }
    }
    
    public func run(with intents: Intents) {
        self.first.run(with: intents)
    }
    
    public var identifier: String = ""
    
    public init(first: SimpleStep) {
        self.first = first
        self.last = first.last
    }
    
    public func step(at index: Int)->SimpleStep?{
        var target: SimpleStep? = first
        for _ in 0...index{
            target = target?.next
        }
        return target
    }
    
    public func extend(with newLastStep: SimpleStep){
        last.next = newLastStep
        last = newLastStep.last
    }
    
    public func syncLastStep(){
        last = first.last
    }
}
