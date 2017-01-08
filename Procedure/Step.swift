//
//  Step.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

extension Step {
    
    public enum FlowControl {
        case next
        case previous
        case cancel
        case finish
        case jump(other: SimpleStep)
    }
}

internal let kGroup = DispatchSpecificKey<DispatchGroup>()
open class Step : SimpleStep, ActionTrigger, _RunnableStep, SequenceStep {
    
    public typealias IntentType = Intent
    
    public var identifier: String
    
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
    
    internal let autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency
    internal let attributes: DispatchQueue.Attributes
    internal let qos: DispatchQoS
    internal let queue: DispatchQueue
    
    public var maximum:Int = 10
    
    public var flowControls:(Intents)->FlowControl = { _ in
        return .next
    }
    
    public convenience init(do task: @escaping Action.TaskBlock){
        self.init(action: Action(do: task))
    }
    
    internal init(actions:[Action] = [], identifier: String = Utils.Generate.identifier, attributes: DispatchQueue.Attributes = .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, qos: DispatchQoS = .userInteractive, other: Step? = nil){
        self.autoreleaseFrequency = autoreleaseFrequency
        self.attributes = attributes
        self.qos = qos
        self.identifier = identifier
        
        self.queue = DispatchQueue(label: identifier, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: other?.queue)
        
        self.add(actions: actions)
        
    }
    
    public convenience init(actions acts: [Action], queue other:DispatchQueue){
        self.init(identifier: other.label)
        self.add(actions: acts.map{ $0.copy })
    }
    
    public convenience init(action: Action) {
        self.init(actions: [action])
    }
    
    public required convenience init(actions acts: [Action] = []) {
        self.init(actions: acts, queue: DispatchQueue(label: Utils.Generate.identifier))
    }
    
    public func add(actions acts: [Action]){
        for act in acts {
            self.add(action: act)
        }
    }
    
    public func add(action act: Action){
        actions.append(act)
    }
    
    public func remove(actions acts: [Action]){
        for act in acts {
            self.remove(action: act)
        }
    }
    
    public func remove(action act: Action){
        actions = actions.filter {
            return $0 != act
        }
    }
    
    public func run(with inputs: Intents = []){
        DispatchQueue.main.async {[unowned self] _ in
            self._run(with: inputs)
        }
        
    }
    
    public func cancel(){
        for act in actions {
            act.cancel()
        }
    }
    
    internal func _run(with inputs: Intents = []){
        let queue = self.queue
        let group = DispatchGroup()
        queue.setSpecific(key: kGroup, value: group)
        let current = self
        
        let semaphore = DispatchSemaphore(value: maximum)
        
        var outputs: Intents = []
        
        self.actions.forEach{ action in
            group.enter()
            action.run(withGifts: inputs, inQueue: queue){[unowned self] action, result in
                outputs.add(intents: result.outcomes)
                
                semaphore.signal()
                group.leave()
            }
            
            semaphore.wait()
        }

        group.notify(queue: DispatchQueue.main){
            current.actionsDidFinish(original: inputs, outputs: outputs)
        }
        
        
        
    }
    
    internal func actionsDidFinish(original inputs: Intents, outputs: Intents){
        
        let newInputs = inputs + outputs
        
        let control = flowControls(outputs)
        switch control {
        case .cancel:
            print("cancelled")
        case .finish:
            print("finished")
        case .next:
            self.goNext(withGifts: newInputs)
        case .previous:
            self.back(withGifts: newInputs)
            self.previous?.run(with: newInputs)
        case .jump(let other):
            other.run(with: newInputs)
        }
        
    }
    
    
    public func goNext(withGifts inputs: Intents){
        self.next?.run(with: inputs)
    }
    
    public func back(withGifts inputs: Intents){
        self.previous?.run(with: inputs)
    }
    
    public func `continue`(byAction action: Action)->Step{
        let nextStep = Step(actions: [action])
        return self.continue(byStep: nextStep)
    }
    
    public func `continue`(byActions actions: [Action])->Step{
        let nextStep = Step(actions: actions)
        return self.continue(byStep: nextStep)
    }
    
    public func `continue`<T:SimpleStep>(byStep step:T)->T{
        var last = self.last
        last.next = step
        return step
    }
}

extension Step : Hashable {
    
    public var hashValue: Int{
        return identifier.hashValue
    }
}

public func ==<T:Hashable>(lhs: T, rhs: T)->Bool{
    return lhs.hashValue == rhs.hashValue
}

extension Step : Copyable{
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let actionsCopy = self.actions.map{ $0.copy }
        let aCopy = Step(identifier: identifier, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, qos: qos)
        aCopy.add(actions: actionsCopy)
        aCopy.flowControls = self.flowControls
        return aCopy
    }
}

extension Step {
    
    public func add(do block: @escaping Action.TaskBlock)->Action{
        let act = Action(do: block)
        self.add(action: act)
        return act
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
