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

typedef Struct = {
	@:default(true)
	var a : Bool;
	var b : Int;
}

typedef DefaultStruct = {
	@:optional
	@:default({a:true, b:0})
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

class StructureTest extends haxe.unit.TestCase {

	public  function makeMap(?i:Int=0):Map<Int,String> {
		return new Map<Int,String>();
	}

	public function test () {
		{
			var parser = new JsonParser<DefaultStruct>();
			var data = parser.fromJson('{}', "test");
			assertEquals(0, parser.errors.length);
			assertEquals(true, data.d.a);
			assertEquals(0, data.d.b);
			assertEquals("{}", data.map.toString());
			assertEquals(null, data.s);

			data = parser.fromJson('{"d":{"a":false, "b":1}, "map":{"key1":55, "key2": 46, "key3":43}, "s":"sup"}', "test");
			assertEquals(0, parser.errors.length);
			assertEquals(false, data.d.a);
			assertEquals(1, data.d.b);
			assertEquals(46, data.map["key2"]);
			assertEquals("sup", data.s);
		}

		{
			var parser = new JsonParser<Struct>();
			var data = parser.fromJson('{ "a": true, "b": 12 }', "test");
			assertEquals(true, data.a);
			assertEquals(12, data.b);
		}

		{
			var parser = new JsonParser<Struct>();
			var data = parser.fromJson('{ "a": 12, "b": 12 }', "test");
			assertEquals(true, data.a);
			assertEquals(2, parser.errors.length); // IncorrectType + UninitializedVariable
		}

		{
			var parser = new json2object.JsonParser<ReadonlyStruct>();
			var data = parser.fromJson('{"foo":1}', "");
			assertEquals(1, data.foo);
		}

		{
			var parser = new json2object.JsonParser<ReadonlyStruct>();
			var data = parser.fromJson('{"foo":1.2}', "");
			assertEquals(parser.errors.length, 2);
			assertEquals(0, data.foo);
		}

		{
			var parser = new json2object.JsonParser<{ var foo(default,null):Int; }>();
			var data = parser.fromJson('{"foo":12}', "");
			assertEquals(12, data.foo);
		}

		{
			var parser = new json2object.JsonParser<OuterStruct>();
			var data = parser.fromJson('{"outer": {}}', "");
			// @:optionnal transform Int into Null<Int>
			assertEquals(null, data.outer.inner);
		}

		{
			var parser = new json2object.JsonParser<ArrayStruct>();
			var data = parser.fromJson('{"array": [1,2,3.2]}', "");
			assertEquals(1, parser.errors.length);
			assertEquals("[1,2]", data.array.toString());
		}

		{
			var parser = new json2object.JsonParser<MapIIStruct>();
			var data = parser.fromJson('{"map": {"1":2, "3.1": 4, "5":6, "7":8.2}}', "");
			assertEquals(2, parser.errors.length);
			assertEquals(2, data.map.get(1));
			assertEquals(6, data.map.get(5));
			assertEquals(false, data.map.exists(7));
		}
	}

}
