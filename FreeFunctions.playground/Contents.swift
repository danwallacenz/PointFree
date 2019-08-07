
// for code completion mostly
enum f {
    static func incr(_ x: Int) -> Int {
        return x + 1
    }

    static func square(_ x: Int) -> Int {
        return x * x
    }

    static func decr(_ x: Int) -> Int {
        return  x - 1
    }
}

// =====================================
    
precedencegroup ForwardApplication {
  associativity: left
}

infix operator |>: ForwardApplication

func |> <A, B>(a: A, f: (A) -> B) -> B {
  return f(a)
}

3 |> f.incr |> f.square
3 |> f.square |> f.incr

// =====================================

precedencegroup ForwardComposition {
  associativity: left
  higherThan: ForwardApplication
}

infix operator >>>: ForwardComposition

func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> ((A) -> C) {
  return { a in
    g(f(a))
  }
}



(f.incr >>> f.square)(3)
(f.square >>> f.incr)(3)

3 |> f.incr >>> f.square
3 |> f.square >>> f.incr



// an aside
Int.isMultiple(6)(of: 0)
Int.isMultiple(6)(of: 1)
Int.isMultiple(6)(of: 2)
Int.isMultiple(6)(of: 3)
Int.isMultiple(6)(of: 4)
Int.isMultiple(6)(of: 5)
Int.isMultiple(6)(of: 6)

extension Int {
  func incr() -> Int {
    return self + 1
  }

  func square() -> Int {
    return self * self
  }
}

let g = Int.incr
type(of: g)
(3 |> Int.incr)()
//3 |> (Int.incr >>> f.square)

[1, 2, 3]
    .map(f.incr)
    .map(f.square)

[1, 2, 3].map(f.incr >>> f.square) |> String.init
[1, 1, 2, 3, 3].map(f.incr >>> f.square) |> Set.init


