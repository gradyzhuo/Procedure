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

open class Step : SimpleStep, Invocable, Flowable, Shareable, CustomStringConvertible {

    public typealias IntentType = Intent
    
    public var identifier: String{
        return queue.label
    }
    public lazy var name: String = self.identifier
    
    public internal(set) var actions: [Action] = []
    
    public var next: SimpleStep?{
        didSet{
            let current = self
            next.map{ nextStep in
                var nextStep = nextStep
                nextStep.previous = current
            }
        }
    }
    
    internal let autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency
    internal let attributes: DispatchQueue.Attributes
    internal let qos: DispatchQoS
    public var queue: DispatchQueue
    
    public var flowHandler:(Intents)->FlowControl = { _ in
        return .next
    }
    
    public convenience init(do task: @escaping Action.Task){
        self.init(action: Action(do: task))
    }
    
    internal init(actions:[Action] = [], attributes: DispatchQueue.Attributes = .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, qos: DispatchQoS = .userInteractive, other: Step? = nil){
        self.autoreleaseFrequency = autoreleaseFrequency
        self.attributes = attributes
        self.qos = qos
        
        self.queue = DispatchQueue(label: Utils.Generate.identifier(), qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: other?.queue)
        
        self.invoke(actions: actions)
        
    }
    
    public convenience init(action: Action) {
        self.init(actions: [action])
    }
    
    public required convenience init(actions acts: [Action] = []) {
        self.init(actions: acts, attributes: .concurrent, autoreleaseFrequency: .inherit, qos: .userInteractive, other: nil)
    }
    
    public func invoke(actions acts: [Action]){
        for act in acts {
            self.invoke(action: act)
        }
    }
    
    public func invoke(action act: Action){
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
        DispatchQueue.main.async {
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
        
        
        var outputs: Intents = []
        
        self.actions.forEach{ action in
            group.enter()
            action.run(with: inputs, inQueue: queue){ action, result in
                outputs.add(intents: result.outcomes)
                
                group.leave()
            }
        }
        let current = self
        group.notify(queue: DispatchQueue.main){
            current.actionsDidFinish(original: inputs, outputs: outputs)
        }
        
    }
    
    internal func actionsDidFinish(original inputs: Intents, outputs: Intents){
        
        let newInputs = inputs + outputs
        
        let control = flowHandler(outputs)
        switch control {
        case .cancel:
            print("cancelled")
        case .finish:
            print("finished")
        case .next:
            self.goNext(with: newInputs)
        case .previous:
            self.back(with: newInputs)
        case .jump(let other):
            other.run(with: newInputs)
        }
        
    }
    
    
    public func goNext(with intents: Intents){
        self.next?.run(with: intents)
    }
    
    public func back(with intents: Intents){
        self.previous?.run(with: intents)
    }
    
    public var description: String{
        
        let actionDescriptions = actions.reduce("") { (result, action) -> String in
            return result.count == 0 ? "<\(action)>" : "\(result)\n<\(action)>"
        }
        
        return "\(type(of: self))(\(identifier)): [\(actionDescriptions)]"
    }
    
    deinit {
        print("deinit Step : \(identifier)")
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
        let aCopy = Step(attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, qos: qos)
        aCopy.invoke(actions: actionsCopy)
        aCopy.flowHandler = flowHandler
        return aCopy
    }
}

extension Step {
    
    public func invoke(do block: @escaping Action.Task)->Action{
        let act = Action(do: block)
        self.invoke(action: act)
        return act
    }
}

