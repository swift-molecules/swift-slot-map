public import Buffer_Protocol
public import Index
import Ordinal_Standard_Library_Integration
public import SlotMap_Primitive
public import Store_Protocol

extension __SlotMap
where
    S: ~Copyable,
    S: Store.`Protocol` & Buffer.`Protocol`
{

    @inlinable
    public var count: Index.Index<S.Element>.Count {
        store.count
    }

    @inlinable
    public var isEmpty: Bool { store.isEmpty }

    @inlinable
    public var capacity: Index.Index<S.Element>.Count { store.capacity }

    @inlinable
    public var freeCapacity: Index.Index<S.Element>.Count {
        store.capacity.subtract.saturating(store.count)
    }
}
