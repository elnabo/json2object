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
abstract EnumAbstractString(String) {
	var SA = "Z";
	var SB = "Y";
	var SZ = "A";
}

typedef EnumAbstractStringStruct = {
	val:EnumAbstractString
}

class AbstractTest extends haxe.unit.TestCase {

	public function test () {
		{
			var parser = new JsonParser<{ username:Username }>();
			var data = parser.fromJson('{ "username": "Administrator" }', "test");
			assertEquals(data.username, "Administrator");
			assertEquals(data.username.get_id(), "administrator");
		}

		{
			var parser = new JsonParser<{ rights:Rights }>();
			var data = parser.fromJson('{ "rights": ["Full", "Write", "Read", "None"] }', "test");
			assertEquals(data.rights.length, 4);
			assertEquals(data.rights[1], "Write");
		}

		{
			var parser = new JsonParser<{ t:Templated<Int> }>();
			var data = parser.fromJson('{ "t": [2, 1, 0] }', "test");
			assertEquals(data.t.length, 3);
			assertEquals(data.t[2], 0);
		}

		{
			var parser = new JsonParser<B>();
			var data = parser.fromJson('{ "t": [[0,1], [1,0]] }', "test");
			assertEquals(data.t.length, 2);
			assertEquals(data.t[1].length, 2);
			assertEquals(data.t[0][1], 1);
		}

		{
			var parser = new json2object.JsonParser<AbstractStruct>();
			var data = parser.fromJson('{}', 'test');
			assertEquals(data.a.length, 0);
			assertEquals(parser.warnings.length, 0);

			data = parser.fromJson('{"a":[1,1,2,3]}', 'test');
			assertEquals(data.a.toString(), "[1,1,2,3]");
			assertEquals(parser.warnings.length, 0);
		}

		{
			var parser = new json2object.JsonParser<EnumAbstractIntStruct>();
			var data = parser.fromJson('{"val":1}','');
			assertEquals(A, data.val);
			assertEquals(0, parser.warnings.length);

			data = parser.fromJson('{"val":26}','');
			assertEquals(Z, data.val);
			assertEquals(0, parser.warnings.length);

			data = parser.fromJson('{"val":16}','');
			assertEquals(A, data.val);
			assertEquals(2, parser.warnings.length);

			data = parser.fromJson('{"val":26.2}','');
			assertEquals(A, data.val);
			assertEquals(4, parser.warnings.length);
		}

		{
			var parser = new json2object.JsonParser<EnumAbstractStringStruct>();
			var data = parser.fromJson('{"val":"Z"}','');
			assertEquals(SA, data.val);
			assertEquals(0, parser.warnings.length);

			data = parser.fromJson('{"val":"A"}','');
			assertEquals(SZ, data.val);
			assertEquals(0, parser.warnings.length);

			data = parser.fromJson('{"val":"B"}','');
			assertEquals(SA, data.val);
			assertEquals(2, parser.warnings.length);

			data = parser.fromJson('{"val":26.2}','');
			assertEquals(SA, data.val);
			assertEquals(4, parser.warnings.length);
		}
	}

}
