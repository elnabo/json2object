# json2object - intialized object directly from json

This library uses macro and a typed position aware JSON parsing (hxjsonast : <https://github.com/nadako/hxjsonast/>) to create a initializer from json to every annoted object.

Incorrect json files or mismatched between the object and the json will yield warnings or exceptions, with information on the position of the problematic parts.

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

Only `Int`, `Float`, `Bool`, `String`, `Array` and object prefixed by the `@:build` meta can be parsed into, `Array` is the only generic type supported.

Typedef are supported as long as they refer to a supported type.

Anonymous object are not supported.
