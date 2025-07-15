import Swiftler

#nifLibrary(name: "adder", functions: [add(_:_:)])

@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}

@nif func multiply(_ a: Int, _ b: Int) -> Int {
    a * b
}

@nif func greet(_ name: String) -> String {
    "Hello, \(name) from Swift!"
}