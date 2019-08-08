
// Episode one - Functions
// for code completion mostly
enum int {
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
// Operators
precedencegroup ForwardApplication {
  associativity: left
}

// Pipe forward.
// It’s generic over two types: A and B.
// The lefthand side is our value, of type A,
// while the righthand side is a function from A to B.
// We finally return B by applying our value to our function.

infix operator |>: ForwardApplication

func |> <A, B>(a: A, f: (A) -> B) -> B {
  return f(a)
}

3 |> int.incr |> int.square
3 |> int.square |> int.incr

// =====================================

precedencegroup ForwardComposition {
  associativity: left
  higherThan: ForwardApplication
}

// Forward compose (or right arrow) operator.
// It’s a function that’s generic over three generic parameters: A, B, and C.
// It takes two functions, one from A to B, and one from B to C,
// and glues them together by returning a new function
// that passes the value in A to the function that takes A,
// and passing the result, B, to the function that takes B.
//
// It's efficient in that with Map for example,
// it traverses the collection once - not twice.
infix operator >>>: ForwardComposition

func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> ((A) -> C) {
  return { a in
    g(f(a))
  }
}

(int.incr >>> int.square)(3)
(int.square >>> int.incr)(3)

3 |> int.incr >>> int.square
3 |> int.square >>> int.incr


[1, 2, 3]
    .map(int.incr)
    .map(int.square)

[1, 2, 3].map(int.incr >>> int.square) |> String.init
[1, 1, 2, 3, 3].map(int.incr >>> int.square) |> Set.init

// ---------
// An aside
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
// ---------



