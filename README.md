# swift-slot-map

Use this package when you store elements, including move-only ones, in a fixed number of slots and refer to them by a handle that must stop working once its element is removed, even after another element reuses the slot. Start from `SlotMap<E>` for a uniquely owned map, or from `SlotMap<E>.Shared` for a copyable map whose copies share storage until one of them is mutated. If you choose slot numbers yourself and need no stale-handle detection, use the sibling package swift-buffer-slab instead.

## Laws

- A handle from `insert` stays live until `remove` with that handle or `removeAll`. Mutating the element through `withMutableElement` does not stale the handle.
- Once stale, a handle stays stale for good: `contains` returns false, `remove` returns nil, and `withElement` and `withMutableElement` throw `.stale` without calling their closure, even after a new element takes the same slot. Each reuse of a slot advances its generation by one.
- The slot count is fixed when the map is created; the map never grows, and `insert` into a full map throws `.full`, consuming the element and leaving the map unchanged. `count` plus `freeCapacity` always equals `capacity`.
- `forEach` visits live elements in slot order, not insertion order.
- `clone()` on `SlotMap<E>` copies every slot with its generation, so every handle means the same thing in both maps, live or stale. After that the two maps are independent.
- Copies of `SlotMap<E>.Shared` share one store. The first `insert`, `remove`, `removeAll` or `withMutableElement` on a copy detaches it, unless that `insert` or `withMutableElement` throws; the other copies keep their elements and handles. Handles minted before the detach, live or stale, mean the same thing in every copy. `clone()` on `SlotMap<E>.Shared` detaches at once.
- Each element is deinitialized exactly once: when `remove` hands it back and the caller drops it, when `withMutableElement` overwrites it, when `removeAll` runs, or when the map (the last sharing copy, for `SlotMap<E>.Shared`) is destroyed.
