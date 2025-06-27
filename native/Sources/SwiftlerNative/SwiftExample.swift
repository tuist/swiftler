import Darwin

/// Example Swift functions for static linking

public func add(_ a: Int32, _ b: Int32) -> Int32 {
    return a + b
}

public func multiply(_ a: Int32, _ b: Int32) -> Int32 {
    return a * b
}

public func greet(_ name: String) -> String {
    return "Hello, \(name) from Swift!"
}

public func calculateCircleArea(_ radius: Double) -> Double {
    return Double.pi * radius * radius
}

public func fibonacci(_ n: Int32) -> Int32 {
    guard n > 1 else { return n }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

public func isPrime(_ number: Int32) -> Bool {
    guard number > 1 else { return false }
    guard number != 2 else { return true }
    guard number % 2 != 0 else { return false }
    
    let upperLimit = Int32(sqrt(Double(number)))
    for i in stride(from: 3, through: upperLimit, by: 2) {
        if number % i == 0 {
            return false
        }
    }
    return true
}