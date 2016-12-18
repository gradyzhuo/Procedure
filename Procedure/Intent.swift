//
//  BanShoutGift.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation


public protocol Intent {
    var name: String { get }
    var gift: [String: Any]? { get }
}

public enum ActionError : Error {
    case error(name: String, userInfo: [String : Any]?)
}


extension ActionError : Intent {
    
    public var name: String{
        switch self {
        case .error(let name, _):
            return name
        }
    }
    
    public var gift: [String : Any]?{
        switch self {
        case .error(_, let gift):
            return gift
        }
    }

    public init(name: String, userInfo: [String: Any]? = nil){
        self = ActionError.error(name: name, userInfo: userInfo)
    }
}

public struct BanShoutGift : Intent  {
    
    public let name: String
    public let gift: [String: Any]?
    
    public init(name: String, gift: [String: Any]? = nil){
        self.name = name
        self.gift = gift
    }
    
}


public struct Intents {
    internal var gifts: [String: Intent] = [:]
    
    public mutating func add(gift: Intent){
        gifts[gift.name] = gift
    }
    
    public mutating func add(gifts: [Intent]){
        gifts.forEach{ self.gifts[$0.name] = $0 }
    }
    
    public mutating func add(gifts: Intents){
        gifts.gifts.forEach{ self.gifts[$0] = $1 }
    }
    
    public mutating func remove(for name: String)->Intent?{
        return gifts.removeValue(forKey: name)
    }
    
    public mutating func remove(gift: Intent){
        gifts.removeValue(forKey: gift.name)
    }
    
    public func gift(for name: String)-> Intent? {
        return gifts[name]
    }
    
    public init(gifts: [Intent]){
        self.add(gifts: gifts)
    }
    
    public subscript(name: String)->Intent?{
        
        set{
            guard let gift = newValue else {
                return
            }
            
            gifts[gift.name] = gift
        }
        
        get{
            return gift(for: name)
        }
        
    }
}

extension Intents : ExpressibleByArrayLiteral{
    public typealias Element = BanShoutGift
    
    
    public init(arrayLiteral elements: Element...) {
        elements.forEach{ gifts[$0.name] = $0 }
    }

}

extension Intents : ExpressibleByDictionaryLiteral{
    public typealias Key = String
    public typealias Value = Intent
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        elements.forEach{ gifts[$0.0] = $0.1 }
    }
    
}

public func +(lhs: Intents, rhs: Intents)->Intents{
    var gifts = lhs
    gifts.add(gifts: rhs)
    return gifts
}

public func +(lhs: Intents, rhs: Intent)->Intents{
    var gifts = lhs
    gifts.add(gift: rhs)
    return gifts
}
