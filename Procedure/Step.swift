//
//  Step.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public protocol RunnableStep : Identitiable {
    func run(withGifts: BanShoutGifts)
}

internal protocol _RunnableStep {
    var _previous: RunnableStep? { set get }
}

public protocol SimpleStep : RunnableStep, SequenceStep {
    var previous: RunnableStep? { get }
    var next: SimpleStep? { set get }
    
    @discardableResult func `continue`<T:SimpleStep>(byStep step:T)->T
}

public protocol SequenceStep: RunnableStep {
    var last:SimpleStep { get }

}

extension SimpleStep {
    
    public var last:SimpleStep{
        var next: SimpleStep = self
        
        while let n = next.next {
            next = n
        }
        
        return next
    }
    
}

public protocol ActionTrigger {
    var actions: [Action] { get }
    
    init(actions: [Action])
    
    func add(actions: [Action])
}

open class Step : SimpleStep, ActionTrigger, _RunnableStep, SequenceStep {

    internal var outputs: BanShoutGifts = []
    
    public var identifier: String{ return queue.label }
    
    public internal(set) var actions: [Action] = []
    public var next: SimpleStep?{
        didSet{
            (next as? _RunnableStep).map{ [unowned self] nextStep in
                var step = nextStep
                step._previous = self
            }
        }
    }
    
    internal var _previous: RunnableStep?
    public var previous: RunnableStep?{
        return _previous
    }
    
    public var predicate: Predicate<BanShoutGifts>?
    internal let dispatchGroup = DispatchGroup()
    internal let queue = DispatchQueue(label: Utils.Generate.identifier)
    
    public convenience init(do task: @escaping Action.TaskBlock){
        self.init(action: Action(do: task))
    }
    
    public static func stepByStep<T: SimpleStep>(_ previousStep:T, action: Action)->Self{
        let nextStep = self.init(actions: [action])
        previousStep.continue(byStep: nextStep)
        return nextStep
    }
    
    public convenience init(action: Action) {
        self.init(actions: [action])
    }
    
    public required init(actions acts: [Action] = []) {
        self.add(actions: acts)
    }
    
    public func add(actions acts: [Action]){
        acts.forEach{ self.add(action: $0) }
    }
    
    public func add(action act: Action){
        actions.append(act)
        act.add(delegate: self)
    }
    
    public func run(withGifts inputs: BanShoutGifts = []){
        
        DispatchQueue.main.async { [unowned self] _ in
            
            self.actions.forEach{ action in
                self.dispatchGroup.enter()
                action.run(withGifts: inputs, inQueue: self.queue)
            }
            
            self.dispatchGroup.notify(queue: DispatchQueue.main){
                self.actionsDidFinish(original: inputs)
            }
        }
        
    }
    
    internal func actionsDidFinish(original inputs: BanShoutGifts){
        self.goNext(withGifts: inputs+outputs)
    }
    
    
    public func goNext(withGifts inputs: BanShoutGifts){
        self.next?.run(withGifts: inputs)
    }
    
    public func `continue`<T:SimpleStep>(byStep step:T)->T{
        self.next = step
        return step
    }
    
    public func `continue`(byAction action: Action)->Step{
        let nextStep = Step(actions: [action])
        return self.continue(byStep: nextStep)
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

extension Step {
    
    public func add(do block: @escaping Action.TaskBlock)->Action{
        let act = Action(do: block)
        self.add(action: act)
        return act
    }
}


extension Step : Action.Delegate {
    public func action(_ action: Action, didCompletionWithOutput output: BanShoutGift?) {
        
        if let gift = output {
            self.outputs.add(gift: gift)
        }
        dispatchGroup.leave()
    }
    
}

//public struct MultipleOutputStep : RunnableStep {
//    
//    public var identifier: String
//
//    
//    public var nexts: [RunnableStep]?
//    public internal(set) var previous: RunnableStep?
//    
//    public func run(withBanShoutGifts BanShoutGifts: BanShoutGifts = []) {
//        
//    }
//    
//}
