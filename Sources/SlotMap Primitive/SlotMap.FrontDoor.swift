public import Memory_Allocator
public import Memory_Allocator_Pool
public import Memory
public import Storage

public typealias SlotMap<E: ~Copyable> =
    __SlotMap<Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<E>>
