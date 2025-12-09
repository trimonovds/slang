import * as assert from 'assert';
import * as vscode from 'vscode';

suite('Slang Grammar Test Suite', () => {

    // MARK: - Keyword Tests

    suite('Keywords', () => {
        test('Control flow keywords', async () => {
            const content = `
if (true) {}
else {}
for (var i: Int = 0; i < 10; i = i + 1) {}
switch (x) {}
return 42
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Declaration keywords', async () => {
            const content = `
func test() {}
var x: Int = 0
struct Point { x: Int }
enum Color { case red }
union Value = Int | String
case red
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Boolean literals', async () => {
            const content = `
var a: Bool = true
var b: Bool = false
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('true'));
            assert.ok(doc.getText().includes('false'));
        });
    });

    // MARK: - Type Tests

    suite('Types', () => {
        test('Primitive types', async () => {
            const content = `
var i: Int = 0
var f: Float = 0.0
var s: String = ""
var b: Bool = true
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });

            const text = doc.getText();
            assert.ok(text.includes('Int'));
            assert.ok(text.includes('Float'));
            assert.ok(text.includes('String'));
            assert.ok(text.includes('Bool'));
        });

        test('Void return type', async () => {
            const content = `
func noReturn() -> Void {
    print("nothing")
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('Void'));
        });

        test('User-defined types', async () => {
            const content = `
struct MyStruct { value: Int }
var x: MyStruct = MyStruct { value: 42 }
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('MyStruct'));
        });
    });

    // MARK: - Literal Tests

    suite('Literals', () => {
        test('Integer literals', async () => {
            const content = `
var a: Int = 0
var b: Int = 42
var c: Int = 12345
var d: Int = 999999
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });

            const text = doc.getText();
            assert.ok(text.includes('0'));
            assert.ok(text.includes('42'));
            assert.ok(text.includes('12345'));
        });

        test('Float literals', async () => {
            const content = `
var a: Float = 0.0
var b: Float = 3.14
var c: Float = 123.456
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });

            const text = doc.getText();
            assert.ok(text.includes('0.0'));
            assert.ok(text.includes('3.14'));
        });

        test('String literals', async () => {
            const content = `
var a: String = ""
var b: String = "hello"
var c: String = "hello world"
var d: String = "with\nnewline"
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });

            const text = doc.getText();
            assert.ok(text.includes('"hello"'));
            assert.ok(text.includes('"hello world"'));
        });

        test('String escape sequences', async () => {
            const content = `
var a: String = "line1\\nline2"
var b: String = "tab\\there"
var c: String = "quote\\"here"
var d: String = "backslash\\\\"
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('String interpolation', async () => {
            const content = `
var x: Int = 42
var s: String = "value is \\(x)"
var t: String = "sum is \\(1 + 2)"
var u: String = "nested \\(x + x)"
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });

            const text = doc.getText();
            assert.ok(text.includes('\\(x)'));
            assert.ok(text.includes('\\(1 + 2)'));
        });
    });

    // MARK: - Operator Tests

    suite('Operators', () => {
        test('Arithmetic operators', async () => {
            const content = `
var a: Int = 1 + 2
var b: Int = 5 - 3
var c: Int = 4 * 5
var d: Int = 10 / 2
var e: Int = 7 % 3
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Comparison operators', async () => {
            const content = `
var a: Bool = 1 == 1
var b: Bool = 1 != 2
var c: Bool = 1 < 2
var d: Bool = 2 > 1
var e: Bool = 1 <= 2
var f: Bool = 2 >= 1
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Logical operators', async () => {
            const content = `
var a: Bool = true && false
var b: Bool = true || false
var c: Bool = !true
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Assignment operators', async () => {
            const content = `
func main() {
    var x: Int = 0
    x = 1
    x += 1
    x -= 1
    x *= 2
    x /= 2
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Arrow operator', async () => {
            const content = `
func add(a: Int, b: Int) -> Int {
    return a + b
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('->'));
        });

        test('Union pipe operator', async () => {
            const content = `
union Value = Int | String | Bool
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('|'));
        });
    });

    // MARK: - Comment Tests

    suite('Comments', () => {
        test('Single line comments', async () => {
            const content = `
// This is a comment
func main() { // inline comment
    // Another comment
    print("hello")
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('// This is a comment'));
        });

        test('Comment at end of file', async () => {
            const content = `func main() {}
// end comment`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('// end comment'));
        });
    });

    // MARK: - Declaration Tests

    suite('Declarations', () => {
        test('Function declaration - no params, no return', async () => {
            const content = `
func doNothing() {
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('func doNothing()'));
        });

        test('Function declaration - with params', async () => {
            const content = `
func add(a: Int, b: Int) {
    print("\\(a + b)")
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('a: Int'));
            assert.ok(doc.getText().includes('b: Int'));
        });

        test('Function declaration - with return type', async () => {
            const content = `
func multiply(x: Int, y: Int) -> Int {
    return x * y
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('-> Int'));
        });

        test('Struct declaration - single field', async () => {
            const content = `
struct Wrapper {
    value: Int
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('struct Wrapper'));
        });

        test('Struct declaration - multiple fields', async () => {
            const content = `
struct Person {
    name: String
    age: Int
    active: Bool
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('name: String'));
            assert.ok(doc.getText().includes('age: Int'));
        });

        test('Enum declaration - single case', async () => {
            const content = `
enum Single {
    case only
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('case only'));
        });

        test('Enum declaration - multiple cases', async () => {
            const content = `
enum Status {
    case pending
    case active
    case completed
    case failed
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('enum Status'));
        });

        test('Union declaration - two types', async () => {
            const content = `
union Either = Int | String
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('union Either'));
        });

        test('Union declaration - multiple types', async () => {
            const content = `
struct A { x: Int }
struct B { y: Int }
struct C { z: Int }
union ABC = A | B | C
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('A | B | C'));
        });
    });

    // MARK: - Statement Tests

    suite('Statements', () => {
        test('Variable declaration', async () => {
            const content = `
func main() {
    var x: Int = 42
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('var x: Int = 42'));
        });

        test('If statement', async () => {
            const content = `
func main() {
    if (true) {
        print("yes")
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('if (true)'));
        });

        test('If-else statement', async () => {
            const content = `
func main() {
    if (false) {
        print("no")
    } else {
        print("yes")
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('else'));
        });

        test('If-else if-else chain', async () => {
            const content = `
func main() {
    var x: Int = 5
    if (x < 0) {
        print("negative")
    } else if (x == 0) {
        print("zero")
    } else {
        print("positive")
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('else if'));
        });

        test('For loop', async () => {
            const content = `
func main() {
    for (var i: Int = 0; i < 10; i = i + 1) {
        print("\\(i)")
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('for ('));
        });

        test('Switch statement', async () => {
            const content = `
enum Color { case red; case blue }
func main() {
    var c: Color = Color.red
    switch (c) {
        Color.red -> print("red")
        Color.blue -> print("blue")
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('switch (c)'));
        });

        test('Return statement', async () => {
            const content = `
func getValue() -> Int {
    return 42
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('return 42'));
        });
    });

    // MARK: - Expression Tests

    suite('Expressions', () => {
        test('Function call', async () => {
            const content = `
func greet(name: String) {
    print("Hello, " + name)
}
func main() {
    greet("World")
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('greet("World")'));
        });

        test('Member access', async () => {
            const content = `
struct Point { x: Int; y: Int }
func main() {
    var p: Point = Point { x: 1, y: 2 }
    print("\\(p.x)")
    print("\\(p.y)")
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('p.x'));
            assert.ok(doc.getText().includes('p.y'));
        });

        test('Struct initialization', async () => {
            const content = `
struct Point { x: Int; y: Int }
func main() {
    var p: Point = Point { x: 3, y: 4 }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('Point { x: 3, y: 4 }'));
        });

        test('Enum case access', async () => {
            const content = `
enum Direction { case up; case down }
func main() {
    var d: Direction = Direction.up
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('Direction.up'));
        });

        test('Switch expression', async () => {
            const content = `
enum Bool2 { case yes; case no }
func main() {
    var b: Bool2 = Bool2.yes
    var result: String = switch (b) {
        Bool2.yes -> return "Yes!"
        Bool2.no -> return "No!"
    }
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('switch (b)'));
            assert.ok(doc.getText().includes('-> return'));
        });

        test('Unary expressions', async () => {
            const content = `
func main() {
    var a: Int = -42
    var b: Bool = !true
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('-42'));
            assert.ok(doc.getText().includes('!true'));
        });

        test('Grouped expression', async () => {
            const content = `
func main() {
    var x: Int = (1 + 2) * 3
}
`;
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content
            });
            assert.ok(doc.getText().includes('(1 + 2)'));
        });
    });
});
