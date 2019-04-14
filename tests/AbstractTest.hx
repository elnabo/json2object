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
import utest.Assert;

abstract Username (String) from String to String
{
	public function get_id () return this.toLowerCase();
}

@:forward(length)
abstract Rights (Array<String>) to Array<String>
{
}

@:forward(length)
abstract Templated<T> (Array<T>) to Array<T>
{
}

typedef B = {
	t : Templated<Templated<Int>>
}


typedef AbstractStruct = {
	@:optional @:default([])
	var a:ReadonlyArray<Int>;
}

@:forward(length, toString)
abstract ReadonlyArray<T>(Array<T>) from Array<T> {}

@:enum
abstract EnumAbstractInt(Int) {
	var A = 1;
	var B = 2;
	var Z = 26;
}

typedef EnumAbstractIntStruct = {
	val:EnumAbstractInt
}

@:enum
abstract EnumAbstractString(Null<String>) {
	var SA = "Z";
	var SB = "Y";
	var SZ = "A";
}

typedef EnumAbstractStringStruct = {
	@optional var val:EnumAbstractString;
}

@:enum
abstract TernaryValue(Null<Bool>) {
	var BA = true;
	var BB = false;
	var BC = null;
}

typedef TernaryStruct = {
	var val:TernaryValue;
}

@:enum
abstract FloatValue(Float) {
	var PI = 3.14;
	var ZERO = 0.0;
}

typedef FloatStruct = {
	var val:FloatValue;
}

abstract MultiFrom (String) from String to String
{
	inline function new(i:String) {
		this = i;
	}

	@:from
	static public function fromInt(s:Int) {
		return new MultiFrom(Std.string(s));
	}

}

abstract OnClass (OnClassData)
{
}

class OnClassData
{
	public var x:Int;
}

class AbstractTest implements utest.ITest
{
	public function new () {}

	public function test1 ()
	{
		var parser = new JsonParser<{ username:Username }>();
		var writer = new JsonWriter<{ username:Username }>();
		var data = parser.fromJson('{ "username": "Administrator" }', "test");
		Assert.equals("Administrator", data.username);
		Assert.equals("administrator", data.username.get_id());
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test2 ()
	{
		var parser = new JsonParser<{ rights:Rights }>();
		var writer = new JsonWriter<{ rights:Rights }>();
		var data = parser.fromJson('{ "rights": ["Full", "Write", "Read", "None"] }', "test");
		Assert.equals(4, data.rights.length);
		Assert.equals("Write", data.rights[1]);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test3 ()
	{
		var parser = new JsonParser<{ t:Templated<Int> }>();
		var writer = new JsonWriter<{ t:Templated<Int> }>();
		var data = parser.fromJson('{ "t": [2, 1, 0] }', "test");
		Assert.equals(3, data.t.length);
		Assert.equals(0, data.t[2]);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test4 ()
	{
		var parser = new JsonParser<B>();
		var writer = new JsonWriter<B>();
		var data = parser.fromJson('{ "t": [[0,1], [1,0]] }', "test");
		Assert.equals(2, data.t.length);
		Assert.equals(2, data.t[1].length);
		Assert.equals(1, data.t[0][1]);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test5 ()
	{
		var parser = new JsonParser<AbstractStruct>();
		var writer = new JsonWriter<AbstractStruct>();
		var data = parser.fromJson('{}', 'test');
		Assert.equals(0, data.a.length);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"a":[1,1,2,3]}', 'test');
		Assert.same([1,1,2,3], data.a);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test6 ()
	{
		var parser = new JsonParser<MultiFrom>();
		var writer = new JsonWriter<MultiFrom>();
		var data = parser.fromJson('"test"', 'test');
		Assert.equals("test", data);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		var data = parser.fromJson('555', 'test');
		Assert.equals("555", data);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test7 ()
	{
		var parser = new JsonParser<EnumAbstractIntStruct>();
		var writer = new JsonWriter<EnumAbstractIntStruct>();
		var data = parser.fromJson('{"val":1}','');
		Assert.equals(A, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":26}','');
		Assert.equals(Z, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":16}','');
		Assert.equals(A, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":26.2}','');
		Assert.equals(A, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test8 ()
	{
		var parser = new JsonParser<EnumAbstractStringStruct>();
		var writer = new JsonWriter<EnumAbstractStringStruct>();
		var data = parser.fromJson('{"val":"Z"}','');
		Assert.equals(SA, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":"A"}','');
		Assert.equals(SZ, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":"B"}','');
		Assert.equals(SA, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":26.2}','');
		Assert.equals(SA, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test9 ()
	{
		var parser = new JsonParser<TernaryStruct>();
		var writer = new JsonWriter<TernaryStruct>();
		var data = parser.fromJson('{"val":true}','');
		Assert.equals(BA, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":null}','');
		Assert.equals(BC, data.val);
		Assert.equals(0, parser.errors.length);
		data = parser.fromJson('{"val":"B"}','');
		Assert.equals(BA, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test10 ()
	{
		var parser = new json2object.JsonParser<FloatStruct>();
		var writer = new json2object.JsonWriter<FloatStruct>();
		var data = parser.fromJson('{"val":3.14}','');
		Assert.equals(PI, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":0.0}','');
		Assert.equals(ZERO, data.val);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"val":1}','');
		Assert.equals(PI, data.val);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test11 ()
	{
		var parser = new json2object.JsonParser<OnClass>();
		parser.fromJson('{"x":1}', "");
		Assert.isTrue(true); // Just check that it compiles
	}

	#if !(cs || java || hl)
	public function test12 ()
	{
		var parser = new json2object.JsonParser<OtherAbstract>();
		var data = parser.fromJson('{"hello":"world"}', "");
		Assert.same(data.hello, "world");

		//var writer = new json2object.JsonWriter<OtherAbstract>();
		//Assert.same(data, parser.fromJson(writer.write(data), ""));
	}
	#end

	#if !lua
	public function test13 () {
		var schema = new json2object.utils.JsonSchemaWriter<TernaryValue>().schema;
		var oracle = '{"$$schema": "http://json-schema.org/draft-07/schema#","$$ref": "#/definitions/tests.TernaryValue","definitions": {"tests.TernaryValue": {"anyOf": [{"const": true},{"const": false},{"const": null}]}}}';
		Assert.isTrue(JsonComparator.areSame(oracle, schema));
	}
	#end
}
