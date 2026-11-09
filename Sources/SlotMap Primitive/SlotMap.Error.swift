extension __SlotMap where S: ~Copyable {

    public enum Error: Swift::Error, Sendable, Equatable {

        case full

        case stale
    }
}
