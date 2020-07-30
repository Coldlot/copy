@dynamicMemberLookup
struct ChangeableWrapper<Wrapped> {
    private let wrapped: Wrapped
    private var changes: [PartialKeyPath<Wrapped>: Any] = [:]
    
    init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<Wrapped, T>) -> T {
        get {
            changes[keyPath].flatMap { $0 as? T } ?? wrapped[keyPath: keyPath]
        }
        
        set {
            changes[keyPath] = newValue
        }
    }
    
    subscript<T: Changeable>(
        dynamicMember keyPath: KeyPath<Wrapped, T>
    ) -> ChangeableWrapper<T> {
        get {
            ChangeableWrapper<T>(self[dynamicMember: keyPath])
        }

        set {
            self[dynamicMember: keyPath] = T(copy: newValue)
        }
    }
}

protocol Changeable {
    init(copy: ChangeableWrapper<Self>)
}

extension Changeable {
    func changing(_ change: (inout ChangeableWrapper<Self>) -> Void) -> Self {
        var copy = ChangeableWrapper<Self>(self)
        change(&copy)
        return Self(copy: copy)
    }
}


struct User {
    let id: Int
    let name: String
    let age: Int
}

extension User: Changeable {
    init(copy: ChangeableWrapper<Self>) {
        self.init(
            id: copy.id,
            name: copy.name,
            age: copy.age
        )
    }
}

let steve = User(id: 1, name: "Steve", age: 21)

let steveJobs = steve.changing { newUser in
    newUser.name = "Steve Jobs"
    newUser.age = 30
}
