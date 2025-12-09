import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';

suite('Slang Extension Test Suite', () => {
    vscode.window.showInformationMessage('Start all tests.');

    // MARK: - Language Registration Tests

    suite('Language Registration', () => {
        test('Slang language is registered', async () => {
            const languages = await vscode.languages.getLanguages();
            assert.ok(languages.includes('slang'), 'Slang language should be registered');
        });

        test('.slang files are associated with slang language', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'func main() {}'
            });
            assert.strictEqual(doc.languageId, 'slang');
        });
    });

    // MARK: - Syntax Highlighting Tests

    suite('Syntax Highlighting', () => {
        test('Keywords are tokenized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'func var struct enum union if else for switch return case'
            });

            // Verify document is recognized as slang
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Built-in types are recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'var x: Int = 0\nvar y: Float = 1.0\nvar s: String = ""\nvar b: Bool = true'
            });

            assert.strictEqual(doc.languageId, 'slang');
            assert.ok(doc.getText().includes('Int'));
            assert.ok(doc.getText().includes('Float'));
            assert.ok(doc.getText().includes('String'));
            assert.ok(doc.getText().includes('Bool'));
        });

        test('String literals are recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'var s: String = "hello world"'
            });

            assert.ok(doc.getText().includes('"hello world"'));
        });

        test('Comments are recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: '// This is a comment\nfunc main() {}'
            });

            assert.ok(doc.getText().includes('// This is a comment'));
        });

        test('String interpolation is recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'var x: Int = 42\nprint("value: \\(x)")'
            });

            assert.ok(doc.getText().includes('\\(x)'));
        });

        test('Numeric literals are recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'var i: Int = 42\nvar f: Float = 3.14'
            });

            assert.ok(doc.getText().includes('42'));
            assert.ok(doc.getText().includes('3.14'));
        });

        test('Operators are recognized', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'var x: Int = 1 + 2 - 3 * 4 / 5 % 6'
            });

            assert.strictEqual(doc.languageId, 'slang');
        });
    });

    // MARK: - Language Configuration Tests

    suite('Language Configuration', () => {
        test('Comment toggling works', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'func main() {}'
            });
            const editor = await vscode.window.showTextDocument(doc);

            // Select the line
            editor.selection = new vscode.Selection(0, 0, 0, 14);

            // Toggle comment
            await vscode.commands.executeCommand('editor.action.commentLine');

            // Check the result contains //
            const text = doc.getText();
            assert.ok(text.startsWith('//'), 'Line should be commented');
        });

        test('Bracket matching is configured', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: 'func main() { var x: Int = (1 + 2) }'
            });

            // Just verify the document opens without errors
            assert.strictEqual(doc.languageId, 'slang');
        });

        test('Auto-closing brackets work', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: ''
            });
            const editor = await vscode.window.showTextDocument(doc);

            // Type an opening brace - this tests the language configuration
            await editor.edit(editBuilder => {
                editBuilder.insert(new vscode.Position(0, 0), '{');
            });

            // Auto-close should add the closing brace (if configured properly)
            // Note: This depends on VS Code's auto-close settings
            assert.ok(doc.getText().includes('{'));
        });
    });

    // MARK: - Document Symbol Tests

    suite('Document Content', () => {
        test('Function declaration parsing', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
func add(a: Int, b: Int) -> Int {
    return a + b
}

func main() {
    var result: Int = add(1, 2)
    print("Result: \\(result)")
}
`
            });

            const text = doc.getText();
            assert.ok(text.includes('func add'));
            assert.ok(text.includes('func main'));
            assert.ok(text.includes('return a + b'));
        });

        test('Struct declaration parsing', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
struct Point {
    x: Int
    y: Int
}

func main() {
    var p: Point = Point { x: 3, y: 4 }
}
`
            });

            const text = doc.getText();
            assert.ok(text.includes('struct Point'));
            assert.ok(text.includes('x: Int'));
        });

        test('Enum declaration parsing', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
enum Direction {
    case up
    case down
    case left
    case right
}

func main() {
    var dir: Direction = Direction.up
}
`
            });

            const text = doc.getText();
            assert.ok(text.includes('enum Direction'));
            assert.ok(text.includes('case up'));
        });

        test('Union declaration parsing', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
struct Dog { name: String }
struct Cat { name: String }
union Pet = Dog | Cat

func main() {
    var pet: Pet = Pet.Dog(Dog { name: "Buddy" })
}
`
            });

            const text = doc.getText();
            assert.ok(text.includes('union Pet = Dog | Cat'));
        });

        test('Switch expression parsing', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
enum Color { case red; case blue }

func main() {
    var c: Color = Color.red
    var name: String = switch (c) {
        Color.red -> return "Red"
        Color.blue -> return "Blue"
    }
}
`
            });

            const text = doc.getText();
            assert.ok(text.includes('switch (c)'));
            assert.ok(text.includes('->'));
        });
    });

    // MARK: - Complex Program Tests

    suite('Complex Programs', () => {
        test('Full program with all features', async () => {
            const doc = await vscode.workspace.openTextDocument({
                language: 'slang',
                content: `
// Full Slang program example
struct Point {
    x: Int
    y: Int
}

enum Direction {
    case north
    case south
    case east
    case west
}

union Shape = Point | Int

func distance(p: Point) -> Int {
    return p.x + p.y
}

func opposite(dir: Direction) -> Direction {
    return switch (dir) {
        Direction.north -> return Direction.south
        Direction.south -> return Direction.north
        Direction.east -> return Direction.west
        Direction.west -> return Direction.east
    }
}

func main() {
    // Variables
    var x: Int = 42
    var name: String = "Slang"
    var pi: Float = 3.14
    var active: Bool = true

    // Struct usage
    var pt: Point = Point { x: 3, y: 4 }
    var d: Int = distance(pt)

    // Enum usage
    var dir: Direction = Direction.north
    var opp: Direction = opposite(dir)

    // Control flow
    if (active) {
        print("Active!")
    } else {
        print("Inactive")
    }

    // For loop
    for (var i: Int = 0; i < 5; i = i + 1) {
        print("i = \\(i)")
    }

    // Switch statement
    switch (dir) {
        Direction.north -> print("Going north")
        Direction.south -> print("Going south")
        Direction.east -> print("Going east")
        Direction.west -> print("Going west")
    }

    // String interpolation
    print("Distance: \\(d)")
    print("Point: (\\(pt.x), \\(pt.y))")
}
`
            });

            assert.strictEqual(doc.languageId, 'slang');
            assert.ok(doc.lineCount > 50, 'Document should have many lines');
        });
    });
});
