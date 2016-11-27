//: Playground - noun: a place where people can play

@testable import Procedure


var action = Action { (intputs, completionHandler) in
    let after = DispatchWallTime.now() + 6.0
    DispatchQueue.global().asyncAfter(wallDeadline: after, execute: {
        completionHandler(.successWith(outcome: intputs.gift(for: "hello")))
    })
}

let step = Step(action: action)

let input = BanShoutGift(name: "hello", gift: "hello2")
step.run(withGifts: [input])

step.add { (inputs, completionHandler) in
    let after = DispatchWallTime.now() + 1.0
    DispatchQueue.global().asyncAfter(wallDeadline: after, execute: {
        completionHandler(.successWith(outcome: BanShoutGift(name: "hello2")))
    })
}

step.add { (inputs, completionHandler) in
    let after = DispatchWallTime.now() + 2.0
    DispatchQueue.global().asyncAfter(wallDeadline: after, execute: {
        completionHandler(.successWith(outcome: BanShoutGift(name: "hello3")))
    })
}

step.continue(byStep: Step{ (inputs, completionHandler) in
    completionHandler(.success)
})
.continue(byAction: Action{ (inputs, completionHandler) in
    completionHandler(.successWith(outcome: BanShoutGift(name: "hello4")))
}).continue(byAction: Action{ (inputs, completionHandler) in
    print("end: \(inputs["hello"]?.gift)")
})

RunLoop.main.run()