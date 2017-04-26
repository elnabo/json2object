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

class AbstractTest extends haxe.unit.TestCase {

	public function test () {

		{
			var parser = new JsonParser<{ username:Username }>();
			var data = parser.fromJson('{ "username": "Administrator" }', "test");
			assertEquals("Administrator", data.username);
			assertEquals("administrator", data.username.get_id());
		}

		{
			var parser = new JsonParser<{ rights:Rights }>();
			var data = parser.fromJson('{ "rights": ["Full", "Write", "Read", "None"] }', "test");
			assertEquals(4, data.rights.length);
			assertEquals("Write", data.rights[1]);
		}

		{
			var parser = new JsonParser<{ t:Templated<Int> }>();
			var data = parser.fromJson('{ "t": [2, 1, 0] }', "test");
			assertEquals(3, data.t.length);
			assertEquals(0, data.t[2]);
		}

		{
			var parser = new JsonParser<B>();
			var data = parser.fromJson('{ "t": [[0,1], [1,0]] }', "test");
			assertEquals(2, data.t.length);
			assertEquals(2, data.t[1].length);
			assertEquals(1, data.t[0][1]);
		}

		{
			var parser = new json2object.JsonParser<AbstractStruct>();
			var data = parser.fromJson('{}', 'test');
			assertEquals(0, data.a.length);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"a":[1,1,2,3]}', 'test');
			assertEquals("[1,1,2,3]", data.a.toString());
			assertEquals(0, parser.errors.length);
		}

		{
			var parser = new json2object.JsonParser<MultiFrom>();
			var data = parser.fromJson('"test"', 'test');
			assertEquals("test", data);
			assertEquals(0, parser.errors.length);

			var data = parser.fromJson('555', 'test');
			assertEquals("555", data);
			assertEquals(0, parser.errors.length);
		}

		{
			var parser = new json2object.JsonParser<EnumAbstractIntStruct>();
			var data = parser.fromJson('{"val":1}','');
			assertEquals(A, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":26}','');
			assertEquals(Z, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":16}','');
			assertEquals(A, data.val);
			assertEquals(2, parser.errors.length);

			data = parser.fromJson('{"val":26.2}','');
			assertEquals(A, data.val);
			assertEquals(2, parser.errors.length);
		}

		{
			var parser = new json2object.JsonParser<EnumAbstractStringStruct>();
			var data = parser.fromJson('{"val":"Z"}','');
			assertEquals(SA, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":"A"}','');
			assertEquals(SZ, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":"B"}','');
			assertEquals(SA, data.val);
			assertEquals(2, parser.errors.length);

			data = parser.fromJson('{"val":26.2}','');
			assertEquals(SA, data.val);
			assertEquals(2, parser.errors.length);
		}

		{
			var parser = new json2object.JsonParser<TernaryStruct>();
			var data = parser.fromJson('{"val":true}','');
			assertEquals(BA, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":null}','');
			assertEquals(BC, data.val);
			assertEquals(0, parser.errors.length);
			data = parser.fromJson('{"val":"B"}','');
			assertEquals(BA, data.val);
			assertEquals(2, parser.errors.length);
		}

		{
			var parser = new json2object.JsonParser<FloatStruct>();
			var data = parser.fromJson('{"val":3.14}','');
			assertEquals(PI, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":0.0}','');
			assertEquals(ZERO, data.val);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"val":1}','');
			assertEquals(PI, data.val);
			assertEquals(2, parser.errors.length);
		}
	}

}
