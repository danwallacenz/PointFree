import UIKit

func greet(at date: Date, name: String) -> String {
  let seconds = Int(date.timeIntervalSince1970) % 60
  return "Hello \(name)! It's \(seconds) seconds past the minute."
}

greet(at:name:)

func greet(at date: Date) -> (String) -> String {
  return { name in
    let seconds = Int(date.timeIntervalSince1970) % 60
    return "Hello \(name)! It's \(seconds) seconds past the minute."
  }
}

greet(at:)

// Currying

func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
  return { a in { b in f(a, b) } }
}

greet(at:Date())("Dan")

let greetAtTime = curry(greet(at:name:))

greetAtTime(Date())("Dan")

let greetNow = greetAtTime(Date())

greetNow("Dan")


/* Standard Library */

// 1. Initializers (free functions)

String.init(data:encoding:)
// (__shared Foundation.Data, (extension in Foundation):String.Encoding) -> Optional<String>

curry(String.init(data:encoding:))
// (Foundation.Data) -> ((extension in Foundation):String.Encoding) -> Optional<String>

curry(String.init(data:encoding:)) // (Data) -> (String.Encoding) -> String?
>>> { $0(.utf8) }

// (Foundation.Data) -> Optional<String>

// Flipping
func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
  return { b in { a in f(a)(b) } }
}
// ((extension in Foundation):String.Encoding) -> (Foundation.Data) -> Optional<String>

let stringWithEncoding = flip(curry(String.init(data:encoding:)))
// ((extension in Foundation):String.Encoding) -> (Foundation.Data) -> Optional<String>

let data = "Dan".data(using: .utf8)!

stringWithEncoding(.utf8)(data)

let utf8String = stringWithEncoding(.utf8)
let result = utf8String(data)
type(of: result)

data |> utf8String

// 2. Methods

"dan".uppercased(with: Locale(identifier: "en"))

String.uppercased(with:)

String.uppercased(with:)("dan")

String.uppercased(with:)("dan")(Locale.init(identifier: "en"))

flip(String.uppercased(with:))

let uppercasedWithLocale = flip(String.uppercased(with:))

let uppercasedWithEn = uppercasedWithLocale(Locale(identifier: "en"))

uppercasedWithEn("dan")

"dan" |> uppercasedWithEn


// But...

String.uppercased
// (String) -> () -> String

flip(String.uppercased)
// (Optional<Foundation.Locale>) -> (String) -> String !!!???
// Where did Locale come from?

// Define flip in a way that works with zero argument methods.

func flip<A, C>(_ f: @escaping (A) -> () -> C) -> () -> (A) -> C {
  return { { a in f(a)() } }
}

flip(String.uppercased)
// () -> (String) -> String

flip(String.uppercased)()

let uppercased = flip(String.uppercased)() // parentheses!

"dan" |> uppercased

/// Zero-argument curry
func zurry<A>(_ f: () -> A) -> A {
  return f()
}

zurry(flip(String.uppercased))

"dan" |> zurry(flip(String.uppercased)) // no parens!

let uppercasedNoParens = zurry(flip(String.uppercased))

"dan" |> uppercasedNoParens

// Higher Order

// Map (and throwing)
[1, 2, 3]
.map(incr)
.map(square)


func map<A, B>(_ f: @escaping (A) -> B) -> ([A]) -> [B] {
  return { $0.map(f) }
}

map(incr)
map(square)
map(incr) >>> map(square)
map(incr) >>> map(square) >>> map(String.init)

[1, 2, 3] |> map(incr) >>> map(square) >>> map(decr) >>> map(String.init)

// Filter

Array(1...10)
.filter { $0 > 5 }

func filter<A>(_ p: @escaping (A) -> Bool) -> ([A]) -> [A] {
  return { $0.filter(p) }
}

let filtered = Array(1...10) |> filter { $0 <= 5 }
filtered

let filteredAndIncremented = Array(-2...10) |> filter { $0 < 4 } >>> map(incr)
filteredAndIncremented

let filteredAndIncrementedAndSquared = Array(-2...10) |> filter { $0 > 7 }
>>> map(incr >>> square)
filteredAndIncrementedAndSquared
