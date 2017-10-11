/*
Copyright (c) 2017 Guillaume Desquesnes, Valentin Lemière

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
	public var a = 1;
	public function new(){}
}

class StructureTest
{
	public function new () {}

	public function test1 ()
	{
		var parser = new JsonParser<DefaultStruct>();
		var data = parser.fromJson('{}', "test");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(data.d.a);
		Assert.equals(0, data.d.b);
		Assert.same(new Map<String,Int>(), data.map);
		Assert.isNull(data.s);

		data = parser.fromJson('{"d":{"a":false, "b":1}, "map":{"key1":55, "key2": 46, "key3":43}, "s":"sup"}', "test");
		Assert.equals(0, parser.errors.length);
		Assert.isFalse(data.d.a);
		Assert.equals(1, data.d.b);
		Assert.equals(46, data.map["key2"]);
		Assert.equals("sup", data.s);
	}

	public function test2 ()
	{
		var parser = new JsonParser<Struct>();
		var data = parser.fromJson('{ "a": true, "b": 12 }', "test");
		Assert.isTrue(data.a);
		Assert.equals(12, data.b);
	}

	public function test3 ()
	{
		var parser = new JsonParser<Struct>();
		var data = parser.fromJson('{ "a": 12, "b": 12 }', "test");
		Assert.isTrue(data.a);
		Assert.equals(2, parser.errors.length); // IncorrectType + UninitializedVariable
	}

	public function test4 ()
	{
		var parser = new json2object.JsonParser<ReadonlyStruct>();
		var data = parser.fromJson('{"foo":1}', "");
		Assert.equals(1, data.foo);
	}

	public function test5 ()
	{
		var parser = new json2object.JsonParser<ReadonlyStruct>();
		var data = parser.fromJson('{"foo":1.2}', "");
		Assert.equals(parser.errors.length, 2);
		Assert.equals(0, data.foo);
	}

	public function test6 ()
	{
		var parser = new json2object.JsonParser<{ var foo(default,null):Int; }>();
		var data = parser.fromJson('{"foo":12}', "");
		Assert.equals(12, data.foo);
	}

	public function test7 ()
	{
		var parser = new json2object.JsonParser<OuterStruct>();
		var data = parser.fromJson('{"outer": {}}', "");
		// @:optionnal transform Int into Null<Int>
		Assert.isNull(data.outer.inner);
	}

	public function test8 ()
	{
		var parser = new json2object.JsonParser<ArrayStruct>();
		var data = parser.fromJson('{"array": [1,2,3.2]}', "");
		Assert.equals(1, parser.errors.length);
		Assert.same([1,2], data.array);
	}

	public function test9 ()
	{
		var parser = new json2object.JsonParser<MapIIStruct>();
		var data = parser.fromJson('{"map": {"1":2, "3.1": 4, "5":6, "7":8.2}}', "");
		Assert.equals(2, parser.errors.length);
		Assert.equals(2, data.map.get(1));
		Assert.equals(6, data.map.get(5));
		Assert.isFalse(data.map.exists(7));
	}

	public function test10 ()
	{
		var parser = new json2object.JsonParser<Issue19>();
		var data = parser.fromJson('{}', "");
		Assert.equals(1, parser.errors.length);
		Assert.equals(0, data.s.a);
		Assert.isNull(data.s.b);
		Assert.equals(0, data.s.c);
		Assert.isNull(data.s.d);
		Assert.isTrue(data.s.e.a);
		Assert.equals(0, data.s.e.b);
		Assert.equals(1, data.s.f.a);
	}

	public function test11 ()
	{
		var parser = new json2object.JsonParser<Issue19>();
		var data = parser.fromJson('{"s":{"a":1, "b":2, "c":3, "d":null, "e":{"a":false,"b":1}, "f":{"a":2}}}', "");
		Assert.equals(0, parser.errors.length);
		Assert.equals(1, data.s.a);
		Assert.equals(2, data.s.b);
		Assert.equals(3, data.s.c);
		Assert.isNull(data.s.d);
		Assert.isFalse(data.s.e.a);
		Assert.equals(1, data.s.e.b);
		Assert.equals(2, data.s.f.a);
	}
}
