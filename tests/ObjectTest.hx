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

enum A {
	First;
	Second;
}

typedef ObjectStruct = {
	var i : Int;
}

class ObjectTestData<K,V> {

	@:jignored
	var a:A;
	#if (haxe_ver>=4)
	final b : Int = 0;
	#end

	@:optional
	public var objTest:ObjectTestData<K,V>;

	public var base:Bool = true;
	public var map:Map<K, ObjectTestData<K,V>>;
	public var struct:ObjectStruct;
	public var array:Array<V>;

	public var array_array:Array<Array<Int>>;
	public var array_map:Array<Map<String,Int>>;
	public var array_obj:Array<ObjectTestData<K,V>>;

	public var foo(default, null) : Int;

	public function new () {}
}

class ObjectTest extends haxe.unit.TestCase {

	public function test () {
		// Optional/Jignored + missing
		{
			var parser = new JsonParser<ObjectTestData<String, Float>>();
			var data:ObjectTestData<String, Float> = parser.fromJson('{ "base": true, "array": [0,2], "map":{"key":{"base":false, "array":[1], "map":{"t":null}, "struct":{"i": 9}}}, "struct":{"i":1}, "foo": 25 }', "test");
			
			@:privateAccess {
				assertEquals(true, data.base);
				assertEquals("[0,2]",data.array.toString());
				assertEquals(false, data.map.get("key").base);
				assertEquals("[1]",data.map.get("key").array.toString());
				assertEquals(null, data.map.get("key").map.get("t"));
				assertEquals(1, data.struct.i);
				assertEquals(25, data.foo);
			}

			assertEquals(7, parser.errors.length);
		}

		// Optional
		{
			var parser = new JsonParser<ObjectTestData<String, Float>>();
			var data = parser.fromJson('{ "objTest":{"base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null, "foo":45}, "array": null, "map":{"key":null}, "struct":{"i":2}, "array_array":[[0,1], [4, -1]], "array_map":[{"a":1}, null], "array_obj":[{"base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null, "foo":46}], "foo": 63 }', "test");
			
			@:privateAccess {
				assertEquals(true, data.base);
				assertEquals(null, data.array);
				assertEquals(null, data.map.get("key"));
				assertEquals(2, data.struct.i);
				assertEquals(true, data.objTest.base);
				assertEquals("[]",data.objTest.array.toString());
				assertEquals("{}", data.objTest.map.toString());
				assertEquals(63, data.foo);
			}

			assertEquals(0, parser.errors.length);
		}
	}

}
