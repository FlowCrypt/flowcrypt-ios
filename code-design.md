# Flowcrypt-ios Code Design

## Error Handling

We have extension with `errorMessage` property for `Error`.

It checks if `Error` has some custom message using `CustomStringConvertible` protocol, otherwise it uses `localizedDescription` property.
```swift
public extension Error {
    var errorMessage: String {
        switch self {
        case let self as CustomStringConvertible:
            return String(describing: self)
        default:
            return localizedDescription
        }
    }
}
```

Here is example of error with custom messages - https://github.com/FlowCrypt/flowcrypt-ios/blob/master/FlowCrypt/Functionality/Services/Compose%20Message%20Service/ComposeMessageError.swift

## Task Handling

- There should generally be only one "grand" try/catch inside each `Task`.
- There should be generally a single `Task` right in each handler. And then all errors downstream should mostly be re-thrown.
