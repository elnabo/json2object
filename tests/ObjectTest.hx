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

class ObjectTest<K,V> extends haxe.unit.TestCase {

	@:jignored
	var a:A;

	@:optional
	var objTest:ObjectTest<K,V>;

	var base:Bool;
	var map:Map<K, ObjectTest<K,V>>;
	var struct:ObjectStruct;
	var array:Array<V>;

	var array_array:Array<Array<Int>>;
	var array_map:Array<Map<String,Int>>;
	var array_obj:Array<ObjectTest<K,V>>;

	public function test () {
		// Optional/Jignored + missing
		{
			var parser = new JsonParser<ObjectTest<String, Float>>();
			var data = parser.fromJson('{ "base": true, "array": [0,2], "map":{"key":{"base":false, "array":[1], "map":{"t":null}, "struct":{"i": 9}}}, "struct":{"i":1} }', "test");
			assertEquals(data.base, true);
			assertEquals(data.array.toString(), "[0,2]");
			assertEquals(data.map.get("key").base, false);
			assertEquals(data.map.get("key").array.toString(), "[1]");
			assertEquals(data.map.get("key").map.get("t"), null);
			assertEquals(data.struct.i, 1);
			assertEquals(parser.warnings.length, 2*3);

		}
		// Optional
		{
			var parser = new JsonParser<ObjectTest<String, Float>>();
			var data = parser.fromJson('{ "base": true, "objTest":{"base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null}, "array": null, "map":{"key":null}, "struct":{"i":2}, "array_array":[[0,1], [4, -1]], "array_map":[{"a":1}, null], "array_obj":[{"base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null}] }', "test");
			assertEquals(data.base, true);
			assertEquals(data.array, null);
			assertEquals(data.map.get("key"), null);
			assertEquals(data.struct.i,2);
			assertEquals(data.objTest.base,true);
			assertEquals(data.objTest.array.toString(),"[]");
			assertEquals(data.objTest.map.toString(),"{}");
			assertEquals(parser.warnings.length, 0);
		}
	}

}
