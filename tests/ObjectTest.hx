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
	@:default(0)final b : Int = 0;
	#else
	var b(default, never):Int = 0;
	#end

	@:optional
	public var objTest:ObjectTestData<K,V>;

	@:default(true) public var base:Bool;
	public var map:Map<K, ObjectTestData<K,V>>;
	public var struct:ObjectStruct;
	var array:Array<V>;

	public var array_array:Array<Array<Int>>;
	public var array_map:Array<Map<String,Int>>;
	public var array_obj:Array<ObjectTestData<K,V>>;

	public var foo(default, null) : Int;
}

class ObjectTest implements utest.ITest {
	public function new () {}

	public function test1 () { // Optional/Jignored + missing
		var parser = new JsonParser<ObjectTestData<String, Float>>();
		var writer = new JsonWriter<ObjectTestData<String, Float>>();
		var data:ObjectTestData<String, Float> = parser.fromJson('{ "base": true, "array": [0,2], "map":{"key":{"base":false, "array":[1], "map":{"t":null}, "struct":{"i": 9}}}, "struct":{"i":1}, "foo": 25 }', "test");

		Assert.isTrue(data.base);
		Assert.same([0,2], @:privateAccess data.array);
		Assert.isFalse(data.map.get("key").base);
		Assert.same([1], @:privateAccess data.map.get("key").array);
		Assert.isNull(data.map.get("key").map.get("t"));
		Assert.equals(1, data.struct.i);
		Assert.equals(25, data.foo);

		for (error in parser.errors) {
			switch (error) {
				case UninitializedVariable(v, pos):
					Assert.same({file:"test", lines:[{start:pos.min, end:pos.min, number:1}], min:pos.min, max:pos.min}, pos);
					switch (pos.min) {
						case 110:
							Assert.isTrue(["array_array", "array_map", "array_obj", "b", "foo"].lastIndexOf(v) != -1);
						case 142:
							Assert.isTrue(["array_array", "array_map", "array_obj", "b"].lastIndexOf(v) != -1);
						default:
							Assert.isTrue(false);
					}
				default:
					Assert.isTrue(false);
			}
		}
		Assert.equals(9, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test2 () { // Optional
		var parser = new JsonParser<ObjectTestData<String, Float>>();
		var writer = new JsonWriter<ObjectTestData<String, Float>>();
		var data = parser.fromJson('{ "objTest":{"b": 2, "base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null, "foo":45}, "array": null, "map":{"key":null}, "struct":{"i":2}, "array_array":[[0,1], [4, -1]], "array_map":[{"a":1}, null], "array_obj":[{"base":true, "array":[], "map":{}, "struct":{"i":10}, "array_array":null, "array_map":null, "array_obj":null, "foo":46}], "foo": 63 }', "test");
		Assert.isTrue(data.base);
		Assert.isNull(@:privateAccess data.array);
		Assert.isNull(data.map.get("key"));
		Assert.equals(2, data.struct.i);
		Assert.isTrue(data.objTest.base);
		Assert.same([], @:privateAccess data.objTest.array);
		Assert.same(new Map<String, ObjectTestData<String, Float>>(), data.objTest.map);
		Assert.equals(63, data.foo);
		#if (haxe_ver>=4)
		@:privateAccess {
			Assert.equals(2, data.objTest.b);
		}
		#end

		for (error in parser.errors) {
			switch (error) {
				case UninitializedVariable(v, pos):
					Assert.same({file:"test", lines:[{start:pos.min, end:pos.min, number:1}], min:pos.min, max:pos.min}, pos);
					switch (pos.min) {
						case 390:
							Assert.equals("b", v);
						case 404:
							Assert.isTrue(v == "b" || v == "base");
						default:
							Assert.isTrue(false);
					}
				default:
					Assert.isTrue(false);
			}
		}

		Assert.equals(3, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}
}
