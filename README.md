[![Build Status](https://travis-ci.org/elnabo/json2object.svg?branch=master)](https://travis-ci.org/elnabo/json2object)

# json2object - intialized object directly from json

This library uses macro and a typed position aware JSON parsing (hxjsonast : <https://github.com/nadako/hxjsonast/>) to create a parser from json to every supportable object.

Incorrect json files or mismatched between the object and the json will yield warnings or exceptions, with information on the position of the problematic parts.

## Installation

```
haxelib install json2object
```

## Usage

### Using the parser
```haxe
var parser = new json2object.JsonParser<Cls>(); // Creating a parser for Cls class
parser.fromJson(jsonString, filename); // Parsing a string. A filename is specified for errors management
var data:Cls = parser.data; // Access the parsed class
var warnings:Array<json2object.Error> = parser.warnings; // Access the potential warnings
```

It is also possible to populate an existing Array with the warnings
```haxe
var warnings = new Array<json2object.Error>();
var data:Cls = new json2object.JsonParser<Cls>(warnings).fromJson(jsonString, filename);
```

### Constraints in the parsing

- Variables defined with the `@:jignored` metadata will be ignored by the parser.
- Variables defined with the `@:optional` metadata wont trigger warnings if missing.
- Private variables are ignored.

### Supported types

- Basic types (`Int`, `Float`, `Bool`, `String`)
- `Null` and `Array`
- `Map` with `Int` or `String` keys
- class object (generics are supported)
- typedef of supported types (only type aliases, no structures)

Anonymous types and abstracts are not supported unless explicitly specified.

## Example
```haxe
import json2object.JsonParser;

class Main {
	static function main() {
		var parser = new JsonParser<Data>();
		var data = parser.fromJson('{"a": "a", "b": {"c": "c"}, "e": [ { "c": "1" }, { "c": "2" } ], "f": [], "g": [ true ] }', "file.json");
		var warnings = parser.warnings;

		trace(data.a);
		trace(data.b.c);

		for (e in data.e) {
			trace(e.c);
		}

		trace(data.e[0].c);
		trace(data.f.length);

		for (g in data.g) {
			trace(data.g.length);
		}

		for (w in warnings) {
			switch(w) {
				case IncorrectType(variable, expected, pos):
				case UninitializedVariable(variable, pos):
				case UnknownVariable(variable, pos):
				default:
			}
		}
	}
}

class Data {
	public var a:String;
	public var b:SubData;
	public var d:Array<Int>;
	public var e:Array<Map<String, String>>;
	public var f:Array<Float>;
	public var g:Array<Bool>;
	@:jignored
	public var h:Math;

	public function new() {
	}
}

class SubData {
	public var c:String;

	public function new() {
	}
}
```
