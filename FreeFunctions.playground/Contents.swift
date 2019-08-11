import Foundation

// Episode one - Functions
// https://www.pointfree.co/episodes/ep1-functions

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

precedencegroup EffectfulComposition {
  associativity: left
  higherThan: ForwardApplication
//  lowerThan: ForwardComposition // must not be in the same module (see below)
}

precedencegroup ForwardComposition {
  associativity: left
  higherThan: ForwardApplication, EffectfulComposition
}

// Forward compose (or right arrow) operator.
// It’s a function that’s generic over three generic parameters: A, B, and C.
// It takes two functions, one from A to B, and one from B to C,
// and glues them together by returning a new function
// that passes the value in A to the function that takes A,
// and passing the result, B, to the function that takes B.
//
// It's efficient in that with Map, for example,
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


// Chapter 2 Side Effects
// https://www.pointfree.co/episodes/ep2-side-effects

// Hidden outputs

typealias IntAndLogs = (Int, [String])

func computeAndPrint(_ x: Int) -> (Int, [String]) {
  let computation = x * x + 1
  return (computation, ["Computed \(computation)"])
}

computeAndPrint(2) // (5, ["Computed 5"])

func compose<A, B, C>(
  _ f: @escaping (A) -> (B, [String]),
  _ g: @escaping (B) -> (C, [String])
  ) -> (A) -> (C, [String]) {

  return { a in
    let (b, logs) = f(a)
    let (c, moreLogs) = g(b)
    return (c, logs + moreLogs)
  }
}

// Problems...
compose(computeAndPrint, computeAndPrint)

let (result, steps) = 2 |> compose(computeAndPrint, computeAndPrint)
result
steps

// But parentheses and two ways to compose the functions!
let (result2, steps2)  = 2 |> compose(computeAndPrint, compose(computeAndPrint, computeAndPrint))
result2
steps2
let (result3, steps3)  = 2 |> compose(compose(computeAndPrint, computeAndPrint), computeAndPrint)
result3
steps3

// So introducing...
//precedencegroup EffectfulComposition {
//  associativity: left
//  higherThan: ForwardApplication
//  lowerThan: ForwardComposition // cannot do this in the same module (see above)
//}

// Effectful Composition (the 'fish' operator)
infix operator >=>: EffectfulComposition

func >=> <A, B, C>(
  _ f: @escaping (A) -> (B, [String]),
  _ g: @escaping (B) -> (C, [String])
  ) -> (A) -> (C, [String]) {

  return { a in
    let (b, logs) = f(a)
    let (c, moreLogs) = g(b)
    return (c, logs + moreLogs)
  }
}

computeAndPrint >=> computeAndPrint >=> computeAndPrint // (Int) -> (Int, [String])

let (result4, steps4) =
2
|> computeAndPrint
>=> computeAndPrint
>=> computeAndPrint
result4
steps4


let (result5, steps5) =
2
|> computeAndPrint
    >=> (int.incr >>> computeAndPrint)
    >=> (int.square >>> computeAndPrint)
result5
steps5

2
|> computeAndPrint

(37 * 37) * (37 * 37) + 1

// But with parentheses!
// So by making ForwardComposition higher than EffectfulComposition
// we can remove them
let (result6, steps6) =
2
|> computeAndPrint
>=> int.incr
>>> computeAndPrint
>=> int.square
>>> computeAndPrint
result6
steps6

//Every line is now annotated with an operator that provides meaning. Lines prefixed with >>> are dealing with the result of a function that has no side effect, while lines prefixed with >=> are a bit fishier: they’re dealing with the result of an effectful computation.

// Optionals
func >=> <A, B, C>(
  _ f: @escaping (A) -> B?,
  _ g: @escaping (B) -> C?
  ) -> ((A) -> C?) {
    return { a in
        guard let b = f(a) else { return nil }
        return g(b)
    }
}

let even: (Int) -> Int? = { i in
    guard i % 2 == 0  else {  return nil }
    return i
}

let divisibleBy10: (Int) -> Int? = { i in
    guard i % 10 == 0 else { return nil }
    return i
}

10 |> even >=> divisibleBy10
10 |> divisibleBy10 >=> even

8 |> even >=> divisibleBy10
8 |> divisibleBy10 >=> even

7 |> even >=> divisibleBy10
7 |> divisibleBy10 >=> even

30 |> even >=> divisibleBy10
30 |> divisibleBy10 >=> even

// Arrays
func >=> <A, B, C>(
  _ f: @escaping (A) -> [B],
  _ g: @escaping (B) -> [C]
  ) -> ((A) -> [C]) {

    return { a in
        let b = f(a)

        let c = b.flatMap {
            g($0)
        }
        return c
    }
}

//--------------------------------

func toArray(_ s: String) -> [String] {
    Array(s).map {
        String($0)
    }
}
toArray("234")

func toInt(_ s: String) -> [Int] {
    Array(s).compactMap {
        Int(String($0))
    }
}
toInt("456")

"a234" |> toArray >=> toInt

//--------------------------------
let append6: (String) -> [String] = { s in
    return s.map {
        String($0) + "6"
    }
}

let append7: (String) -> [String] = { s in
    return s.map {
        String($0) + "7"
    }
}
"ABC" |> append6
"ABC" |> append6 >=> append7
"abc" |> append7 >=> append6


// Hidden inputs

func uppercased(_ string: String) -> String {
  return string.uppercased()
}

// returns a function
// There’s a bit of a trick we can do to pull the Date out of that signature: we can rewrite greet to take a Date as input, but return a brand new function from (String) -> String that handles the actual greeting logic:

func greet(at date: Date = Date()) -> (String) -> String {
  return { name in
    let s = Int(date.timeIntervalSince1970) % 60
    return "Hello \(name)! It's \(s) seconds past the minute."
  }
}

"Blob" |> uppercased >>> greet(at: Date())
"Blob" |> greet(at: Date()) >>> uppercased

// helper
func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T) -> String {
    return lhs == rhs ?  "✅" : "❌"
}

assertEqual(
  "Hello Blob! It's 37 seconds past the minute.",
  "Blob" |> greet(at: Date(timeIntervalSince1970: 37))
)


// Mutation

func toInout<A>(
  _ f: @escaping (A) -> A
  ) -> ((inout A) -> Void) {

  return { a in
    a = f(a)
  }
}

func fromInout<A>(
  _ f: @escaping (inout A) -> Void
  ) -> ((A) -> A) {

  return { a in
    var copy = a
    f(&copy)
    return copy
  }
}

// Composition that deals with a single type
precedencegroup SingleTypeComposition {
  associativity: left
  higherThan: ForwardApplication
}

infix operator <>: SingleTypeComposition

func <> <A>(
  f: @escaping (A) -> A,
  g: @escaping (A) -> A)
  -> ((A) -> A) {

  return f >>> g
}

// returning functions - inputs/outputs a single type
func lowercased(_ s: String) -> String {
    return s.lowercased()
}

func capitalize(_ s: String) -> String {
    return s.capitalized
}

"AbC" |> uppercased <> lowercased <> capitalize

// inout functions - mutates a single type
func formLowercased(_ s: inout String) {
    s = s.lowercased()
}

func formCapitalized(_ s: inout String) {
    s = s.capitalized
}

func <> <A>(
  f: @escaping (inout A) -> Void,
  g: @escaping (inout A) -> Void)
  -> ((inout A) -> Void) {

  return { a in
    f(&a)
    g(&a)
  }
}

// Pipe forward - inout functions
func |> <A>(a: inout A, f: (inout A) -> Void) -> Void {
  f(&a)
}

var mutableString = "AbC"

// inout functions
mutableString |> formLowercased <> formCapitalized

formLowercased |> fromInout
lowercased |> toInout

formCapitalized |> fromInout
capitalize |> toInout

fromInout(formLowercased)

// parentheses!
mutableString |> (lowercased |> toInout) <> formCapitalized
mutableString |> (lowercased |> toInout) <> (capitalize |> toInout)

mutableString |> (formLowercased |> fromInout) <> (formCapitalized |> fromInout)
