import Buffer_Test_Support
import Index
import Memory
import Memory_Allocator
import Memory_Allocator_Pool
import Ownership_Shared_Primitive
import SlotMap
import Storage
import Store
import Testing

private typealias Slots<E: ~Copyable> =
    Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<E>

enum `SlotMap Tests` {}

extension `SlotMap Tests` {
    @Suite
    struct `Slot Map Column Law Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `the shared generational column obeys the seam ledger laws`() {
            let violations = Seam.Ledger.violations(
                makeEmpty: { Ownership.Shared(Slots<Int>.create(slotCapacity: 4)) },
                element: { $0 }
            )
            #expect(violations.isEmpty, "\(violations)")
        }
    }
}

extension `SlotMap Tests` {
    @Suite(.serialized)
    struct `Slot Map Core Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `insert, contains, withElement, remove, stale handles, counts`() throws {
            var m = SlotMap<Int>(slotCapacity: 4)
            let isEmpty = m.isEmpty
            #expect(isEmpty)
            let h1 = try m.insert(10)
            let h2 = try m.insert(20)
            let n = m.count
            #expect(n == Index<Int>.Count(UInt(2)))
            let free = m.freeCapacity
            #expect(free == Index<Int>.Count(UInt(2)))
            let v = try m.withElement(at: h2) { copy $0 }
            #expect(v == 20)
            try m.withMutableElement(at: h1) { $0 += 1 }
            let v1 = try m.withElement(at: h1) { copy $0 }
            #expect(v1 == 11)
            let removed: Int? = m.remove(h1)
            #expect(removed == 11)
            let stale: Int? = m.remove(h1)
            #expect(stale == nil)
            let hasH1 = m.contains(h1)
            let hasH2 = m.contains(h2)
            #expect(!hasH1)
            #expect(hasH2)
        }

        @Test
        func `forEach walks occupied slots; removeAll stales everything`() throws {
            var m = SlotMap<Int>(slotCapacity: 4)
            let h1 = try m.insert(1)
            try m.insert(2)
            _ = m.remove(h1)
            try m.insert(3)
            var seen: [Int] = []
            m.forEach { seen.append($0) }
            #expect(seen.sorted() == [2, 3])
            m.removeAll()
            let isEmpty = m.isEmpty
            #expect(isEmpty)
            var seen2: [Int] = []
            m.forEach { seen2.append($0) }
            #expect(seen2.isEmpty)
        }

        @Test
        func `pinned clone keeps handles live on both values`() throws {
            var m = SlotMap<Int>(slotCapacity: 4)
            let h = try m.insert(7)
            var c = m.clone()
            let onBoth = m.contains(h) && c.contains(h)
            #expect(onBoth)
            try c.withMutableElement(at: h) { $0 = 70 }
            let mine = try m.withElement(at: h) { copy $0 }
            let theirs = try c.withElement(at: h) { copy $0 }
            #expect(mine == 7)
            #expect(theirs == 70)
        }
    }
}

extension `SlotMap Tests` {
    @Suite(.serialized)
    struct `Slot Map CoW Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `sibling handles survive a copy-on-write detach — live and stale alike`() throws {
            var a = SlotMap<Int>.Shared(slotCapacity: 4)
            let hStale = try a.insert(1)
            _ = a.remove(hStale)
            let hLive = try a.insert(2)
            let b = a
            try a.insert(3)
            let aCount = a.count
            let bCount = b.count
            #expect(aCount == Index<Int>.Count(UInt(2)))
            #expect(bCount == Index<Int>.Count(UInt(1)))
            let liveOnBoth = a.contains(hLive) && b.contains(hLive)
            #expect(liveOnBoth)
            let staleOnBoth = a.contains(hStale) || b.contains(hStale)
            #expect(!staleOnBoth)
            let aV = try a.withElement(at: hLive) { copy $0 }
            let bV = try b.withElement(at: hLive) { copy $0 }
            #expect(aV == 2)
            #expect(bV == 2)
        }

        @Test
        func `mutation through a handle detaches; the sibling keeps the old element`() throws {
            var a = SlotMap<Int>.Shared(slotCapacity: 2)
            let h = try a.insert(5)
            let b = a
            try a.withMutableElement(at: h) { $0 = 50 }
            let mine = try a.withElement(at: h) { copy $0 }
            let theirs = try b.withElement(at: h) { copy $0 }
            #expect(mine == 50)
            #expect(theirs == 5)
            let removedFromA: Int? = a.remove(h)
            #expect(removedFromA == 50)
            let stillOnB = b.contains(h)
            #expect(stillOnB)
        }

        @Test
        func `generic clone always detaches; removeAll detaches`() throws {
            var a = SlotMap<Int>.Shared(slotCapacity: 2)
            let h = try a.insert(9)
            var c = a.clone()
            try c.withMutableElement(at: h) { $0 = 90 }
            let mine = try a.withElement(at: h) { copy $0 }
            #expect(mine == 9)
            let b = a
            a.removeAll()
            let aEmpty = a.isEmpty
            let bHas = b.contains(h)
            #expect(aEmpty)
            #expect(bHas)
        }
    }
}

extension `SlotMap Tests` {
    @Suite(.serialized)
    struct `Slot Map Teardown Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `the direct lane tears down live slots via the leaf oracle`() throws {
            MapProbe.reset()
            do {
                var m = SlotMap<MapItem>(slotCapacity: 4)
                try m.insert(MapItem(1))
                let h2 = try m.insert(MapItem(2))
                if let removed: MapItem = m.remove(h2) {
                    let id = removed.id
                    #expect(id == 2)
                } else {
                    Issue.record("expected the removed element")
                }
                let mid = MapProbe.sorted
                #expect(mid == [2])
            }
            let all = MapProbe.sorted
            #expect(all == [1, 2])
        }

        @Test
        func `the boxed move-only lane tears down via the box drain`() throws {
            MapProbe2.reset()
            do {
                var m = SlotMap<MapItem2>.Shared(slotCapacity: 4)
                try m.insert(MapItem2(7))
                try m.insert(MapItem2(8))
                let n = m.count
                #expect(n == Index<MapItem2>.Count(UInt(2)))
            }
            let all = MapProbe2.sorted
            #expect(all == [7, 8])
        }
    }
}

extension `SlotMap Tests` {
    @Suite(.serialized)
    struct `Slot Map Failure Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `insert on a full map throws full and leaves the map unchanged`() throws {
            var m = SlotMap<Int>(slotCapacity: 2)
            let h1 = try m.insert(1)
            try m.insert(2)
            do {
                try m.insert(3)
                Issue.record("insert on a full map returned a handle")
            } catch {
                #expect(error == .full)
            }
            let n = m.count
            #expect(n == Index<Int>.Count(UInt(2)))
            _ = m.remove(h1)
            let h3 = try m.insert(3)
            let v = try m.withElement(at: h3) { copy $0 }
            #expect(v == 3)
        }

        @Test
        func `insert on a full shared map throws full and leaves the map unchanged`() throws {
            var m = SlotMap<Int>.Shared(slotCapacity: 1)
            try m.insert(1)
            let sibling = m
            do {
                try m.insert(2)
                Issue.record("insert on a full shared map returned a handle")
            } catch {
                #expect(error == .full)
            }
            let n = m.count
            let siblingCount = sibling.count
            #expect(n == Index<Int>.Count(UInt(1)))
            #expect(siblingCount == Index<Int>.Count(UInt(1)))
        }

        @Test
        func `insert on a full move-only map throws full and destroys the rejected element`() throws {
            MapProbe.reset()
            do {
                var m = SlotMap<MapItem>(slotCapacity: 1)
                try m.insert(MapItem(1))
                do {
                    try m.insert(MapItem(2))
                    Issue.record("insert on a full map returned a handle")
                } catch {
                    #expect(error == .full)
                }
                let rejected = MapProbe.sorted
                #expect(rejected == [2])
            }
            let all = MapProbe.sorted
            #expect(all == [1, 2])
        }

        @Test
        func `a stale handle makes withElement and withMutableElement throw stale`() throws {
            var m = SlotMap<Int>(slotCapacity: 2)
            let h = try m.insert(1)
            _ = m.remove(h)
            try m.insert(2)
            var called = false
            do {
                _ = try m.withElement(at: h) { copy $0 }
                Issue.record("withElement accepted a stale handle")
            } catch {
                #expect(error == .stale)
            }
            do {
                try m.withMutableElement(at: h) { _ in called = true }
                Issue.record("withMutableElement accepted a stale handle")
            } catch {
                #expect(error == .stale)
            }
            #expect(!called)
        }

        @Test
        func `a stale handle on a shared map throws stale without detaching`() throws {
            var m = SlotMap<Int>.Shared(slotCapacity: 2)
            let h = try m.insert(1)
            _ = m.remove(h)
            let live = try m.insert(2)
            let sibling = m
            do {
                _ = try m.withElement(at: h) { copy $0 }
                Issue.record("withElement accepted a stale handle")
            } catch {
                #expect(error == .stale)
            }
            do {
                try m.withMutableElement(at: h) { $0 = 99 }
                Issue.record("withMutableElement accepted a stale handle")
            } catch {
                #expect(error == .stale)
            }
            let mine = try m.withElement(at: live) { copy $0 }
            let theirs = try sibling.withElement(at: live) { copy $0 }
            #expect(mine == 2)
            #expect(theirs == 2)
        }
    }
}

private struct MapItem: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
    deinit { MapProbe.record(id) }
}

private enum MapProbe {}

extension MapProbe {

    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func record(_ id: Int) { unsafe _destroyed.append(id) }
    static var sorted: [Int] { unsafe _destroyed.sorted() }
}

private struct MapItem2: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
    deinit { MapProbe2.record(id) }
}

private enum MapProbe2 {}

extension MapProbe2 {

    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func record(_ id: Int) { unsafe _destroyed.append(id) }
    static var sorted: [Int] { unsafe _destroyed.sorted() }
}

extension `SlotMap Tests` {
    @Suite
    struct `Slot Map Sendable Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        @Test
        func `sendable composes through both columns`() {
            let a = SlotMap<Int>(slotCapacity: 1)
            requireSendable(a)
            let b = SlotMap<Int>.Shared(slotCapacity: 1)
            requireSendable(b)
            #expect(Bool(true))
        }
    }
}

private func requireSendable<T: Sendable & ~Copyable>(_ value: borrowing T) {}
