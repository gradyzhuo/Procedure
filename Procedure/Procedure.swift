//
//  Procedure.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

open class Procedure : SimpleStep {
    public private(set) var start: SimpleStep
    public private(set) var end: SimpleStep
    
    public var next: SimpleStep?{
        set{
            end.next = newValue
        }
        get{
            return end.next
        }
    }
    
    public func run(with intents: Intents) {
        start.run(with: intents)
    }
    
    public lazy var name: String = self.identifier
    
    public init(start: SimpleStep) {
        self.start = start
        self.end = start.last
    }
    
    public func step(at index: Int)->SimpleStep?{
        var target: SimpleStep? = start
        for _ in 0...index{
            target = target?.next
        }
        return target
    }
    
    public func extend(with newLastStep: SimpleStep){
        end.next = newLastStep
        end = newLastStep.last
    }
    
    public func syncEndStep(){
        end = start.last
    }
}
