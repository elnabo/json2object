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

typedef MapStruct = {
	var i : Int;
}

class MapTest implements utest.ITest {
	public function new () {}

	public function test1 () { // Str -> Str
		var parser = new JsonParser<Map<String, String>>();
		var writer = new JsonWriter<Map<String, String>>();
		var data = parser.fromJson('{ "key1": "value1", "key2": "value2" }', "test");
		Assert.equals("value1", data.get("key1"));
		Assert.equals("value2", data.get("key2"));
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test2 () { // Int -> Str
		var parser = new JsonParser<Map<Int, String>>();
		var writer = new JsonWriter<Map<Int, String>>();
		var data = parser.fromJson('{ "1": "value1", "2": "value2" }', "test");
		Assert.equals("value1", data.get(1));
		Assert.equals("value2", data.get(2));
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test3 () { // Str -> Object/Struct
		var parser = new JsonParser<Map<String, MapStruct>>();
		var writer = new JsonWriter<Map<String, MapStruct>>();
		var data = parser.fromJson('{ "key1": null, "key2": {"i":9}, "key3":{"i":0} }', "test");
		Assert.isNull(data.get("key1"));
		Assert.equals(9, data.get("key2").i);
		Assert.equals(0, data.get("key3").i);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test4 () { // Str -> Map<Str,Str>
		var parser = new JsonParser<Map<String, Map<String, String>>>();
		var writer = new JsonWriter<Map<String, Map<String, String>>>();
		var data = parser.fromJson('{ "key1": {}, "key2": {"i":"9"}, "key3":{"a":"0"} }', "test");
		Assert.same(new Map<String, String>(), data.get("key1"));
		Assert.equals("9", data.get("key2").get("i"));
		Assert.equals("0", data.get("key3").get("a"));
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test5 () { // Str -> Array<Str>
		var parser = new JsonParser<Map<String, Array<String>>>();
		var writer = new JsonWriter<Map<String, Array<String>>>();
		var data = parser.fromJson('{ "key1": [], "key2": ["i","9"], "key3":["a"] }', "test");
		Assert.same([], data.get("key1"));
		Assert.same(["i","9"], data.get("key2"));
		Assert.same(["a"], data.get("key3"));
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	#if !lua
	public function test6 () { // Schema writer
		var schema = new JsonSchemaWriter<Map<Int, Bool>>().schema;

		var oracle = '{"$$schema": "http://json-schema.org/draft-07/schema#","$$ref": "#/definitions/Map<Int, Bool>","definitions": {"Map<Int, Bool>": {"patternProperties": {"/^[-+]?\\d+([Ee][+-]?\\d+)?$/": {"type": "boolean"}},"type": "object"}}}';

		Assert.isTrue(JsonComparator.areSame(oracle, schema));
	}
	#end
}
