//
//  BanShoutGift.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation


public protocol SimpleIntent {
    var name: String { get }
    var value: Any? { get }
}

public struct Intent : SimpleIntent  {
    
    public let name: String
    public let value: Any?
    
    public init(name: String, value: Any? = nil){
        self.name = name
        self.value = value
    }
    
}

extension Intent : ExpressibleByStringLiteral{
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    
    public init(stringLiteral value: StringLiteralType){
        self = Intent(name: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self = Intent(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = Intent(stringLiteral: value)
    }
}



public struct Intents {
    public typealias IntentType = SimpleIntent
    internal var storage: [String: IntentType] = [:]
    
    public var count:Int{
        return storage.count
    }
    
    public mutating func add(intent: IntentType){
        storage[intent.name] = intent
    }
    
    public mutating func add(intents: [IntentType]){
        for intent in intents {
            self.add(intent: intent)
        }
    }
    
    public mutating func add(intents: Intents){
        for (_, intent) in intents.storage{
            self.add(intent: intent)
        }
    }
    
    public mutating func remove(for name: String)->IntentType!{
        return storage.removeValue(forKey: name)
    }
    
    public mutating func remove(intent: IntentType){
        storage.removeValue(forKey: intent.name)
    }
    
    public func intent(for name: String)-> IntentType! {
        return storage[name]
    }
    
    public init(array intents: [IntentType]){
        self.add(intents: intents)
    }
    
    public init(intents: Intents){
        self.add(intents: intents)
    }
    
    public subscript(name: String)->IntentType!{
        
        set{
            guard let intent = newValue else {
                return
            }
            
            self.add(intent: intent)
        }
        
        get{
            return intent(for: name)
        }
        
    }
}

extension Intents : ExpressibleByArrayLiteral{
    public typealias Element = IntentType
    
    
    public init(arrayLiteral elements: Element...) {
        for element in elements {
            self.add(intent: element)
        }
    }

}

extension Intents : ExpressibleByDictionaryLiteral{
    public typealias Key = String
    public typealias Value = Any
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        for (key, value) in elements {
            let intent = Intent(name: key, value: value)
            self.add(intent: intent)
        }
    }
    
}

public func +(lhs: Intents, rhs: Intents)->Intents{
    var gifts = lhs
    gifts.add(intents: rhs)
    return gifts
}

public func +(lhs: Intents, rhs: Intents.IntentType)->Intents{
    var intents = lhs
    intents.add(intent: rhs)
    return intents
}
