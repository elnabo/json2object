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

typedef MapStruct = {
	var i : Int;
}


class MapTest extends haxe.unit.TestCase {

	public function test () {
		// Str -> Str
		{
			var data = new JsonParser<Map<String, String>>().fromJson('{ "key1": "value1", "key2": "value2" }', "test");
			assertEquals(data.get("key1"), "value1");
			assertEquals(data.get("key2"), "value2");
		}

		// Int -> Str
		{
			var data = new JsonParser<Map<Int, String>>().fromJson('{ "1": "value1", "2": "value2" }', "test");
			assertEquals(data.get(1), "value1");
			assertEquals(data.get(2), "value2");
		}

		// Str -> Object/Struct
		{
			var data = new JsonParser<Map<String, MapStruct>>().fromJson('{ "key1": null, "key2": {"i":9}, "key3":{"i":0} }', "test");
			assertEquals(data.get("key1"), null);
			assertEquals(data.get("key2").i, 9);
			assertEquals(data.get("key3").i, 0);
		}

		// Str -> Map<Str,Str>
		{
			var data = new JsonParser<Map<String, Map<String,String>>>().fromJson('{ "key1": {}, "key2": {"i":"9"}, "key3":{"a":"0"} }', "test");
			assertEquals(data.get("key1").toString(), "{}");
			assertEquals(data.get("key2").get("i"), "9");
			assertEquals(data.get("key3").get("a"), "0");
		}

		// Str -> Array<Str>
		{
			var data = new JsonParser<Map<String, Array<String>>>().fromJson('{ "key1": [], "key2": ["i","9"], "key3":["a"] }', "test");
			assertEquals(data.get("key1").toString(), "[]");
			assertEquals(data.get("key2").toString(), '[i,9]');
			assertEquals(data.get("key3").toString(), '[a]');
		}
	}

}
