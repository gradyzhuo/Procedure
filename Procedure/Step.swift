//
//  Step.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

open class Step : SimpleStep, ActionTrigger, _RunnableStep, SequenceStep {

    internal var outputs: Intents = []
    
    public var identifier: String{ return queue.label }
    
    public internal(set) var actions: [Action] = []
    
    public var next: SimpleStep?{
        didSet{
            let current = self
            (next as? _RunnableStep).map{nextStep in
                var nextStep = nextStep
                nextStep._previous = current
            }
        }
    }
    
    internal var _previous: RunnableStep?
    public var previous: RunnableStep?{
        return _previous
    }
    
    public var predicate: Predicate<Intents>?
    internal let dispatchGroup = DispatchGroup()
    internal let queue:DispatchQueue
    
    public convenience init(do task: @escaping Action.TaskBlock){
        self.init(action: Action(do: task))
    }
    
    public static func stepByStep<T: SimpleStep>(_ previousStep:T, action: Action)->Self{
        var previousStep = previousStep
        let nextStep = self.init(actions: [action])
        previousStep.continue(byStep: nextStep)
        return nextStep
    }
    
    public init(actions acts: [Action], queue q:DispatchQueue = DispatchQueue(label: Utils.Generate.identifier)){
        queue = q
        self.add(actions: acts)
    }
    
    public convenience init(action: Action) {
        self.init(actions: [action])
    }
    
    public required convenience init(actions acts: [Action] = []) {
        self.init(actions: acts)
    }
    
    public func add(actions acts: [Action]){
        acts.forEach{ self.add(action: $0) }
    }
    
    public func add(action act: Action){
        actions.append(act)
        act.add(delegate: self)
    }
    
    public func run(withGifts inputs: Intents = []){
        let queue = self.queue
        let group = self.dispatchGroup
        let actions = self.actions
        let current = self
        
        DispatchQueue.main.async {
            
            actions.forEach{ action in
                group.enter()
                action.run(withGifts: inputs, inQueue: queue)
            }
            
            group.notify(queue: DispatchQueue.main){
                current.actionsDidFinish(original: inputs)
            }
            
        }
        
    }
    
    internal func actionsDidFinish(original inputs: Intents){
        self.goNext(withGifts: inputs+outputs)
    }
    
    
    public func goNext(withGifts inputs: Intents){
        self.next?.run(withGifts: inputs)
    }
    
    public func `continue`(byAction action: Action)->Step{
        let nextStep = Step(actions: [action])
        var current = self
        return current.continue(byStep: nextStep)
    }
}

extension Step : Hashable {
    
    public var hashValue: Int{
        return self.identifier.hashValue
    }
}

public func ==<T:Hashable>(lhs: T, rhs: T)->Bool{
    return lhs.hashValue == rhs.hashValue
}

extension Step : Copyable{
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let actionsCopy = self.actions.map{ $0.copy }
        return Step(actions: actionsCopy)
    }
}

extension Step {
    
    public func add(do block: @escaping Action.TaskBlock)->Action{
        let act = Action(do: block)
        self.add(action: act)
        return act
    }
}


extension Step : Action.Delegate {
    public func action(_ action: Action, didCompletionWithOutput output: Intent?) {
        
        if let gift = output{
            self.outputs.add(gift: gift)
        }
        dispatchGroup.leave()
    }
    
}

extension Step {
    
    public internal(set) static var sharedSteps:[String:Step] = [:]
    
    public static func shared(forKey key: String)->Step?{
        return sharedSteps[key]?.copy
    }
    
    public func share(forKey key:String){
        Step.sharedSteps[key] = self.copy
    }
}
