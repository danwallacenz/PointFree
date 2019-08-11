// https://www.pointfree.co/episodes/ep5-higher-order-functions

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
[1, 2, 3] |> map(incr >>> square >>> decr >>> String.init) // !!	

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

// An aside (Optional map)
let i: Int? = 2
i.map {
    $0 + 23
}

let n: Int? = nil
n.map {
    $0 + 23
}
//
//Write curry for functions that take 3 arguments.
//
//Solution

func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in { b in { c in f(a, b, c) } } }
}

func add3(_ a: Int, _ b: Int, _ c: Int) -> Int {
    return a + b + c
}

add3(1, 2, 3)

curry(add3)
curry(add3)(1)
curry(add3)(1)(2)
curry(add3)(1)(2)(3)

//Explore functions and methods in the Swift standard library, Foundation, and other third party code, and convert them to free functions that compose using curry, zurry, flip, or by hand.
//

//Int.init(<#T##text: StringProtocol##StringProtocol#>, radix: <#T##Int#>)

func hexValue(_ s: String) -> Int? {
    flip(curry(Int.init(_:radix:)))(16)(s)
}
hexValue("B")
"B" |> hexValue

func binaryValue(_ s: String) -> Int? {
    flip(curry(Int.init(_:radix:)))(2)(s)
}
let bv = binaryValue("1011")
type(of: bv)
"1011" |> binaryValue

//Explore the associativity of function arrow ->. Is it fully associative, i.e. is ((A) -> B) -> C equivalent to (A) -> ((B) -> C), or does it associate to only one side? Where does it parenthesize as you build deeper, curried functions?

//func equivalence<A, B, C>( _ f: @escaping (A) -> ((B) -> C)) -> ((A) -> B) -> C {
//  return { f in
//    // How to return something in C in here???
//  }
//}
//
//However, it is not possible to implement this function.
//
//It turns out, the function arrow -> only associates to the right. So if we were to write:

// f: (A) -> (B) -> (C) -> D
//what that really means is:

//f: (A) -> ((B) -> ((C) -> D))

//
//Solution
//Write a function, uncurry, that takes a curried function and returns a function that takes two arguments. When might it be useful to un-curry a function?
//


//Write reduce as a curried, free function. What is the configuration vs. the data?
//
//Solution
//In programming languages that lack sum/enum types one is tempted to approximate them with pairs of optionals. Do this by defining a type struct PseudoEither<A, B> of a pair of optionals, and prevent the creation of invalid values by providing initializers.
//
//This is “type safe” in the sense that you are not allowed to construct invalid values, but not “type safe” in the sense that the compiler is proving it to you. You must prove it to yourself.
//
//Solution
//Explore how the free map function composes with itself in order to transform a nested array. More specifically, if you have a doubly nested array [[A]], then map could mean either the transformation on the inner array or the outer array. Can you make sense of doing map >>> map?


// Result (an aside)

enum MyError: Error {
    case notEven(Int)
    case notMultipleOf10(Int)
    case wrongType
}

let v = Result<Int, MyError>.success(1)

let v2: Result<Int, MyError> = v.flatMap { i in
    guard i % 2 == 0 else {
        return Result.failure(MyError.notEven(i))
    }
    return .success(i)
}
v2


let v3 = v.map { i in
    return i
}
v3

let v4 = v.map { i in
    return Result<Any, MyError>.failure(MyError.notEven(i))
}
v4 // ??
