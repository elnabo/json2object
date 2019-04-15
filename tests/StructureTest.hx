/*
Copyright (c) 2017-2018 Guillaume Desquesnes, Valentin Lemière

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package tests;

import json2object.JsonParser;
import json2object.JsonWriter;
import json2object.utils.JsonSchemaWriter;
import utest.Assert;

typedef Struct = {
	@:default(true)
	var a : Bool;
	var b : Int;
}

typedef DefaultStruct = {
	@:optional
	//~ @:default({a:true, b:0})
	@:default(auto)
	var d : Struct;
	@:optional
	@:default(new Map<String,Int>())
	var map:Map<String,Int>;
	@:optional
	var s:String;
}

typedef ReadonlyStruct = {
	var foo(default,null):Int;
}

typedef SimpleDefault = {
	@:default({a:"foo", b:3})
	var foo(default,null):{a:String, b:Int};
	@:default("test")
	var auto:String;
	@:default(auto)
	var bool:Bool;
}

typedef OuterStruct = {
	@:optional var outer:InnerStruct;
}

typedef InnerStruct = {
	@:optional var inner:Int;
}

typedef ArrayStruct = {
	var array:Array<Int>;
}

typedef MapIIStruct = {
	var map:Map<Int, Int>;
}

typedef Issue19 = {
	@:default(auto) var s:Issue19Inner;
}

typedef Issue19Inner = {
	@:optional @:default(0) var a:Int;
	@:optional var b:Int;
	@:optional @:default(0) var c:Int;
	var d:Issue19Inner;
	@:optional @:default(auto) var e:Struct;
	@:default(auto) var f:StructA;
}

class StructA {
	@:default(1) public var a:Int;
}

typedef StructB = {
	@:optional @:default(0) var a:Int;
	var b:Bool;
	@:optional @:default(0) var c:String;
}

class StructureTest implements utest.ITest {
	public function new () {}

	public function test1 () {
		var parser = new JsonParser<DefaultStruct>();
		var writer = new JsonWriter<DefaultStruct>();
		var data = parser.fromJson('{}', "test");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(data.d.a);
		Assert.equals(0, data.d.b);
		Assert.same(new Map<String,Int>(), data.map);
		Assert.isNull(data.s);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));

		data = parser.fromJson('{"d":{"a":false, "b":1}, "map":{"key1":55, "key2": 46, "key3":43}, "s":"sup"}', "test");
		Assert.equals(0, parser.errors.length);
		Assert.isFalse(data.d.a);
		Assert.equals(1, data.d.b);
		Assert.equals(46, data.map["key2"]);
		Assert.equals("sup", data.s);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test2 () {
		var parser = new JsonParser<Struct>();
		var writer = new JsonWriter<Struct>();
		var data = parser.fromJson('{ "a": true, "b": 12 }', "test");
		Assert.isTrue(data.a);
		Assert.equals(12, data.b);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test3 () {
		var parser = new JsonParser<Struct>();
		var writer = new JsonWriter<Struct>();
		var data = parser.fromJson('{ "a": 12, "b": 12 }', "test");
		Assert.isTrue(data.a);
		Assert.equals(2, parser.errors.length); // IncorrectType + UninitializedVariable
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test4 () {
		var parser = new JsonParser<ReadonlyStruct>();
		var writer = new JsonWriter<ReadonlyStruct>();
		var data = parser.fromJson('{"foo":1}', "");
		Assert.equals(1, data.foo);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test5 () {
		var parser = new JsonParser<ReadonlyStruct>();
		var writer = new JsonWriter<ReadonlyStruct>();
		var data = parser.fromJson('{"foo":1.2}', "");
		Assert.equals(parser.errors.length, 2);
		Assert.equals(0, data.foo);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test6 () {
		var parser = new JsonParser<{ var foo(default,null):Int; }>();
		var writer = new JsonWriter<{ var foo(default,null):Int; }>();
		var data = parser.fromJson('{"foo":12}', "");
		Assert.equals(12, data.foo);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test7 () {
		var parser = new JsonParser<OuterStruct>();
		var writer = new JsonWriter<OuterStruct>();
		var data = parser.fromJson('{"outer": {}}', "");
		// @:optionnal transform Int into Null<Int>
		Assert.isNull(data.outer.inner);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test8 () {
		var parser = new JsonParser<ArrayStruct>();
		var writer = new JsonWriter<ArrayStruct>();
		var data = parser.fromJson('{"array": [1,2,3.2]}', "");
		Assert.equals(1, parser.errors.length);
		Assert.same([1,2], data.array);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test9 () {
		var parser = new JsonParser<MapIIStruct>();
		var writer = new JsonWriter<MapIIStruct>();
		var data = parser.fromJson('{"map": {"1":2, "3.1": 4, "5":6, "7":8.2}}', "");
		Assert.equals(2, parser.errors.length);
		Assert.equals(2, data.map.get(1));
		Assert.equals(6, data.map.get(5));
		Assert.isFalse(data.map.exists(7));
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test10 () {
		var parser = new JsonParser<Issue19>();
		var writer = new JsonWriter<Issue19>();
		var data = parser.fromJson('{}', "");
		Assert.equals(1, parser.errors.length);
		Assert.equals(0, data.s.a);
		Assert.isNull(data.s.b);
		Assert.equals(0, data.s.c);
		Assert.isNull(data.s.d);
		Assert.isTrue(data.s.e.a);
		Assert.equals(0, data.s.e.b);
		Assert.equals(1, data.s.f.a);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test11 () {
		var parser = new JsonParser<Issue19>();
		var writer = new JsonWriter<Issue19>();
		var data = parser.fromJson('{"s":{"a":1, "b":2, "c":3, "d":null, "e":{"a":false,"b":1}, "f":{"a":2}}}', "");
		Assert.equals(0, parser.errors.length);
		Assert.equals(1, data.s.a);
		Assert.equals(2, data.s.b);
		Assert.equals(3, data.s.c);
		Assert.isNull(data.s.d);
		Assert.isFalse(data.s.e.a);
		Assert.equals(1, data.s.e.b);
		Assert.equals(2, data.s.f.a);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	#if !lua
	public function test12 () {
		var schema = new JsonSchemaWriter<SimpleDefault>().schema;
		var oracle = '{"definitions": {"{ b : Int, a : String }": {"additionalProperties": false,"properties": {"b": {"type": "integer"},"a": {"type": "string"}},"required": ["a","b"],"type": "object"},"tests.SimpleDefault": {"additionalProperties": false,"properties": {"foo": {"$$ref": "#/definitions/{ b : Int, a :String }"},"auto": {"default": "test", "type": "string"},"bool":{"default": false, "type": "boolean"}},"required": ["auto","bool","foo"],"type": "object"}},"$$ref": "#/definitions/tests.SimpleDefault","$$schema": "http://json-schema.org/draft-07/schema#"}';
		Assert.isTrue(JsonComparator.areSame(oracle, schema));
	}
	#end
}
