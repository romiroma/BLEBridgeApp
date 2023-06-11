
class Box<ObjectType: AnyObject & Identifiable> {

    var object: ObjectType

    init(object: ObjectType) {
        self.object = object
    }
}

import Dispatch

class Storage<ObjectType: AnyObject & Identifiable> {

    private let queue: DispatchQueue = .init(label: "Storage.queue")
    private var storage: [ObjectType.ID: Box<ObjectType>] = [:]

    subscript(id: ObjectType.ID) -> ObjectType? {

        get {
            queue.sync {
                storage[id]?.object
            }
        }
        set {
            queue.async {
                switch (newValue, self.storage[id]) {
                case (.none, .none):
                    break
                case (.some(let obj), .none):
                    self.storage[id] = .init(object: obj)
                case (.some(let obj), .some(let box)):
                    box.object = obj
                case (.none, .some):
                    self.storage.removeValue(forKey: id)
                }
            }
        }
    }
}
