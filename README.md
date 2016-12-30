[![Build Status](https://travis-ci.org/elnabo/json2object.svg?branch=master)](https://travis-ci.org/elnabo/json2object)

# json2object - intialized object directly from json

This library uses macro and a typed position aware JSON parsing (hxjsonast : <https://github.com/nadako/hxjsonast/>) to create a initializer from json to every annoted object.

Incorrect json files or mismatched between the object and the json will yield warnings or exceptions, with information on the position of the problematic parts.

Errors yielded during the initialization are stored in an array `warnings:Array<Error>` for that reason no `warnings` variable can be defined in a object tagged with the `@:build` meta.

Some variables can be ignored by using the `@:jignore` metadata.

## Installation

```
haxelib install json2object
```

## Usage
```haxe
class Main {
	static function main() {
		var data = Data.fromJson('{"a": "a", "b": {"c": "c"}, "e": [ { "c": "1" }, { "c": "2" } ], "f": [], "g": [ true ] }', "file.json");
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

		for (w in data.warnings) {
			switch(w) {
				case IncorrectType(variable, expected, pos):
				case UninitializedVariable(variable, pos):
				case UnknownVariable(variable, pos):
				default:
			}
		}
	}
}

@:build(json2object.DataBuild.loadJson())
class Data {
	public var a:String;
	public var b:SubData;
	public var d:Array<Int>;
	public var e:Array<SubData>;
	public var f:Array<Float>;
	public var g:Array<Bool>;
	@:jignored
	public var h:Math;

	public function new() {
	}
}

@:build(json2object.DataBuild.loadJson())
class SubData {
	public var c:String;

	public function new() {
	}
}
```

## Notes

Only `Int`, `Float`, `Bool`, `String`, `Array`, `Map<String, ?>` and object prefixed by the `@:build` meta can be parsed into, `Array` is the only generic type supported.

Typedef are supported as long as they refer to a supported type. Abstract are only supported if they refer to a supported type and use the `from` implicit cast.

Anonymous object are not supported.
