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
    // Type narrowing: 'pet' is narrowed to Dog or Cat in each case
    return switch (pet) {
        Pet.Dog -> return pet.name
        Pet.Cat -> return pet.name
    }
}

func main() {
    // Create a union with a struct
    var myDog: Dog = Dog { name: "Buddy" }
    var pet: Pet = Pet.Dog(myDog)
    print("Pet is: \(describePet(pet))")

    // Type narrowing: 'pet' is narrowed to Dog in this case
    switch (pet) {
        Pet.Dog -> print("It's a dog named \(pet.name)!")
        Pet.Cat -> print("It's a cat named \(pet.name)!")
    }

    // Union with primitives - 'v' is narrowed to Int or String
    var v: Value = Value.Int(42)
    switch (v) {
        Value.Int -> print("integer: \(v)")
        Value.String -> print("string: \(v)")
    }

    // Create another union value and use type narrowing in function
    var myCat: Cat = Cat { name: "Whiskers" }
    var pet2: Pet = Pet.Cat(myCat)
    print("Pet 2 name: \(getPetName(pet2))")
}
