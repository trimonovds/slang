// v0.1.2 - Union types example

struct Dog { name: String }
struct Cat { name: String }
union Pet = Dog | Cat

union Value = Int | String

func describePet(pet: Pet) -> String {
    return switch (pet) {
        Pet.Dog -> return "dog"
        Pet.Cat -> return "cat"
    }
}

func getPetName(pet: Pet) -> String {
    // Pattern binding: 'dog' and 'cat' are automatically bound
    // to the underlying value in each case
    return switch (pet) {
        Pet.Dog -> return dog.name
        Pet.Cat -> return cat.name
    }
}

func main() {
    // Create a union with a struct
    var myDog: Dog = Dog { name: "Buddy" }
    var pet: Pet = Pet.Dog(myDog)
    print("Pet is: \(describePet(pet))")

    // Pattern binding: access the underlying Dog value via 'dog'
    switch (pet) {
        Pet.Dog -> print("It's a dog named \(dog.name)!")
        Pet.Cat -> print("It's a cat named \(cat.name)!")
    }

    // Union with primitives - 'int' and 'string' are bound
    var val: Value = Value.Int(42)
    switch (val) {
        Value.Int -> print("integer: \(int)")
        Value.String -> print("string: \(string)")
    }

    // Create another union value and use pattern binding in function
    var myCat: Cat = Cat { name: "Whiskers" }
    var pet2: Pet = Pet.Cat(myCat)
    print("Pet 2 name: \(getPetName(pet2))")
}
