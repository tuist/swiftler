import Swiftler
import Foundation

#nifLibrary(name: "calculator", functions: [
    add(_:_:), 
    subtract(_:_:), 
    multiply(_:_:), 
    divide(_:_:),
    power(_:_:),
    sqrt(_:),
    factorial(_:),
    is_prime(_:),
    gcd(_:_:),
    fibonacci(_:),
    circle_area(_:),
    greet(_:)
])

// Basic arithmetic operations

@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

@nif func subtract(_ a: Int, _ b: Int) -> Int {
    a - b
}

@nif func multiply(_ a: Int, _ b: Int) -> Int {
    a * b
}

@nif func divide(_ a: Int, _ b: Int) -> Int {
    guard b != 0 else { return 0 }
    return a / b
}

// Advanced mathematical operations

@nif func power(_ base: Int, _ exponent: Int) -> Int {
    Int(pow(Double(base), Double(exponent)))
}

@nif func sqrt(_ n: Double) -> Double {
    Foundation.sqrt(n)
}

@nif func factorial(_ n: Int) -> Int {
    guard n >= 0 else { return 0 }
    guard n > 1 else { return 1 }
    return (2...n).reduce(1, *)
}

@nif func is_prime(_ n: Int) -> Bool {
    guard n > 1 else { return false }
    guard n != 2 else { return true }
    guard n % 2 != 0 else { return false }
    
    let sqrtN = Int(Foundation.sqrt(Double(n)))
    for i in stride(from: 3, through: sqrtN, by: 2) {
        if n % i == 0 {
            return false
        }
    }
    return true
}

@nif func gcd(_ a: Int, _ b: Int) -> Int {
    let absA = abs(a)
    let absB = abs(b)
    var x = absA
    var y = absB
    
    while y != 0 {
        let temp = y
        y = x % y
        x = temp
    }
    
    return x
}

@nif func fibonacci(_ n: Int) -> Int {
    guard n >= 0 else { return 0 }
    guard n > 1 else { return n }
    
    var a = 0
    var b = 1
    
    for _ in 2...n {
        let temp = a + b
        a = b
        b = temp
    }
    
    return b
}

@nif func circle_area(_ radius: Double) -> Double {
    Double.pi * radius * radius
}

// String operations

@nif func greet(_ name: String) -> String {
    "Hello, \(name)! Welcome to Swiftler Calculator."
}
