import Testing
@testable import SwiftlerNative

@Suite("Swift Native Function Tests")
struct SwiftlerNativeTests {
    
    @Test("Math operations work correctly")
    func mathOperations() {
        #expect(add(5, 3) == 8)
        #expect(multiply(4, 6) == 24)
        
        let area = calculateCircleArea(5.0)
        let expected = Double.pi * 25.0
        #expect(abs(area - expected) < 0.0001)
    }
    
    @Test("String operations work correctly")
    func stringOperations() {
        let greeting = greet("World")
        #expect(greeting == "Hello, World from Swift!")
    }
    
    @Test("Fibonacci calculation is correct")
    func fibonacciCalculation() {
        #expect(fibonacci(0) == 0)
        #expect(fibonacci(1) == 1)
        #expect(fibonacci(5) == 5)
        #expect(fibonacci(10) == 55)
    }
    
    @Test("Prime number detection works")
    func primeDetection() {
        #expect(isPrime(2) == true)
        #expect(isPrime(3) == true)
        #expect(isPrime(4) == false)
        #expect(isPrime(17) == true)
        #expect(isPrime(25) == false)
    }
    
    @Test("C-exported functions work correctly")
    func cExportedFunctions() {
        // Test C-exported versions
        #expect(add_swift(5, 3) == 8)
        #expect(multiply_swift(4, 6) == 24)
        #expect(fibonacci_swift(5) == 5)
        #expect(is_prime_swift(17) == true)
        #expect(is_prime_swift(4) == false)
        #expect(calculate_circle_area_swift(5.0) - (Double.pi * 25.0) < 0.0001)
    }
    
    @Test("String C export works")
    func stringCExport() {
        let namePtr = "World".withCString { $0 }
        let resultPtr = greet_swift(namePtr)
        let result = String(cString: resultPtr)
        #expect(result == "Hello, World from Swift!")
        
        // Clean up the allocated string
        free(UnsafeMutableRawPointer(mutating: resultPtr))
    }
    
    @Test("Edge cases are handled correctly")
    func edgeCases() {
        #expect(isPrime(-5) == false)
        #expect(isPrime(0) == false)
        #expect(isPrime(1) == false)
        #expect(fibonacci(-1) == -1)
    }
}