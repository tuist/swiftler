// Test case to understand the issue

// Original function
func myFunction() -> String {
    return "Hello"
}

// Simulated peer function (what the macro generates)
public func __thunk_myFunction() -> String {
    // This should call the original function
    return myFunction()
}

// Test it
print(__thunk_myFunction())