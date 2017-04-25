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
			assertEquals(parser.warnings.length, 0);
			assertEquals(data.d.a, true);
			assertEquals(data.d.b, 0);
			assertEquals(data.map.toString(), "{}");
			assertEquals(data.s, null);

			data = parser.fromJson('{"d":{"a":false, "b":1}, "map":{"key1":55, "key2": 46, "key3":43}, "s":"sup"}', "test");
			assertEquals(parser.warnings.length, 0);
			assertEquals(data.d.a, false);
			assertEquals(data.d.b, 1);
			assertEquals(data.map["key2"], 46);
			assertEquals(data.s, "sup");
		}

		{
			var parser = new JsonParser<Struct>();
			var data = parser.fromJson('{ "a": true, "b": 12 }', "test");
			assertEquals(data.a, true);
			assertEquals(data.b, 12);
		}

		{
			var parser = new JsonParser<Struct>();
			var data = parser.fromJson('{ "a": 12, "b": 12 }', "test");
			assertEquals(data.a,true);
			assertEquals(parser.warnings.length, 2); // IncorrectType + UninitializedVariable
		}

		{
			var parser = new json2object.JsonParser<ReadonlyStruct>();
			var data = parser.fromJson('{"foo":1}', "");
			assertEquals(data.foo, 1);
		}

		{
			var parser = new json2object.JsonParser<ReadonlyStruct>();
			var data = parser.fromJson('{"foo":1.2}', "");
			assertEquals(parser.warnings.length, 2);
			#if (cpp || cs || java || flash || hl)
			assertEquals(0, data.foo);
			#else
			assertEquals(null, data.foo);
			#end
		}

		{
			var parser = new json2object.JsonParser<{ var foo(default,null):Int; }>();
			var data = parser.fromJson('{"foo":12}', "");
			assertEquals(data.foo, 12);
		}

		{
			var parser = new json2object.JsonParser<OuterStruct>();
			var data = parser.fromJson('{"outer": {}}', "");
			#if (cpp || cs || java || flash || hl)
			assertEquals(0, data.outer.inner);
			#else
			assertEquals(null, data.outer.inner);
			#end
		}

		{
			var parser = new json2object.JsonParser<ArrayStruct>();
			var data = parser.fromJson('{"array": [1,2,3.2]}', "");
			assertEquals(parser.warnings.length, 1);
			assertEquals(data.array.toString(), "[1,2]");
		}
		{
			var parser = new json2object.JsonParser<MapIIStruct>();
			var data = parser.fromJson('{"map": {"1":2, "3.1": 4, "5":6, "7":8.2}}', "");
			assertEquals(parser.warnings.length, 2);
			assertEquals(data.map.get(1),2);
			assertEquals(data.map.get(5),6);
			assertEquals(data.map.exists(7),false);
		}
	}

}
