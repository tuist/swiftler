import Swiftler

// Test to see what the @nif macro expands to
@nif func test_string() -> String {
    return "Test"
}

// Let's see if we can call it directly
func callTest() {
    let result = test_string()
    print(result)
}