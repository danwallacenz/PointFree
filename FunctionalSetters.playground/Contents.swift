// https://www.pointfree.co/episodes/ep6-functional-setters

let pair = (42, "Swift")


// Manipulating the first value

(incr(pair.0), pair.1)

func incrFirst<A>(_ pair: (Int, A)) -> (Int, A) {
  return (incr(pair.0), pair.1)
}

incrFirst(pair)


func first<A, B, C>(_ f: @escaping (A) -> C) -> ((A, B)) -> (C, B) {
  return { pair in
    return (f(pair.0), pair.1)
  }
}
incr
//type(of: first) ?
//first ?
first(incr)(pair)
//first(incr) ?
first(square)(pair)
first(incr)((2, "Dan"))

// chaining
first(incr)(first(incr)(pair))
// ==
pair
|> first(incr)
|> first(incr)

// or even
pair
|> first(incr)
|> first(String.init)


// Manipulating the second value

func second<A, B, C>(_ f: @escaping (B) -> C) -> ((A, B)) -> (A, C) {
  return { pair in
    return (pair.0, f(pair.1))
  }
}

pair
|> first(incr)
|> first(String.init)
|> second { $0 + "!" }


pair
|> first(incr)
|> first(String.init)
|> second { $0.uppercased() }


pair
|> first(incr)
|> first(String.init)
|> second(zurry(flip(String.uppercased)))

first(incr)
>>> first(String.init)
>>> second(zurry(flip(String.uppercased)))

String.uppercased
String.uppercased("a")
String.uppercased("a")()

flip(String.uppercased)
flip(String.uppercased)()
flip(String.uppercased)()("b")

zurry(flip(String.uppercased))
zurry(flip(String.uppercased))("c")

pair |>
first(incr)
>>> first(String.init)
>>> second(zurry(flip(String.uppercased)))

let incr1Cap2 =
first(incr)
>>> first(String.init)
>>> second(zurry(flip(String.uppercased)))

pair |> incr1Cap2

// Regular mutation
var copyPair = pair
copyPair.0 += 1
copyPair

copyPair.1 = copyPair.1.uppercased()
copyPair

// Cannot assign value of type 'String' to type 'Int'
//copyPair.0 = String(copyPair.0)

// ====

pair |>
first(incr)
>>> first(String.init)
// ==
pair
|> first(incr >>> String.init)

// !!!: The composition of the firsts is the firsts of the composition! This is the second time we have seen this shape. The first was with map, in which we said the composition of maps is the map of the composition. We will see this shape over and over, and soon we will give it a proper name!

incr >>> String.init


// Nested tuples

let nested = ((1, true), "Swift")

// negate the Bool
nested
|> first { pair in pair |> second { !$0 } }

// or
nested
|> first { $0 |> second { !$0 } }

// There’s mostly only two things you can do with functions: apply to a value, and compose them!

// If we try...
//nested
//|> (first >>> second) { !$0 } // it does not compile

// But if we flip them...
nested
|> (second >>> first) { !$0 } // It works!

// Introducing <<<

precedencegroup BackwardsComposition {
  associativity: left
}

infix operator <<<: BackwardsComposition

func <<< <A, B, C>(g: @escaping (B) -> C, f: @escaping (A) -> B) -> (A) -> C {
  return { x in
    g(f(x))
  }
}

nested
|> (first <<< second) { !$0 }

// Setters compose backwards!

nested
|> (first <<< first)(incr)

nested
|> (first <<< first) { $0 + 1 }
|> (first <<< second) { !$0 }
|> second { $0 + "!" }

// When the shape doesn’t change, we can use <> to denote the fact that we’re dealing with a single type.
let transformation = (first <<< second) { !$0 }
<> (first <<< first) { $0 + 1 }
<> second { $0 + "!" }

nested |> transformation

//So far all of our setter functions have had this shape:
//
// ((A) -> B) -> (S) -> T
//
// In words, we are LIFTING a transformation on parts (A) -> B up to a transformation on wholes (S) -> T.

//For example, first and second had these shapes:
//
// ((A) -> B) -> ((A, C)) -> (B, C) // first
// ((A) -> B) -> ((C, A)) -> (C, B) // second
//
//That is telling us that a transformation on the first component of a tuple can be lifted to a transformation on the whole tuple.

// Arrays

// ((A) -> B) -> ([A]) -> [B]

func map<A, B>(_ f: @escaping (A) -> B) -> ([A]) -> [B] {
  return { xs in xs.map(f) }
}

(42, ["Swift", "Objective-C"])
|> (second <<< map) { $0 + "!" }

// In an array...
print(
    [(42, ["Swift", "Objective-C"]), (1729, ["Haskell", "PureScript"])]
    |> (map <<< second <<< map) { $0 + "!" }
)

let data = [
  (42, ["Swift", "Objective-C"]),
  (1729, ["Haskell", "PureScript"])
]

// Imperitive.  messy!
data.map { ($0.0, $0.1.map { $0 + "!" }) }
