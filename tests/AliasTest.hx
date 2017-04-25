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

typedef Aliased = {
	@:alias("public") var isPublic : Bool;
}

typedef MultiAliased = {
	@:alias("first") @:alias("public") var isPublic : Bool;
}

class AliasedClass {
	@:alias("public") public var isPublic : Bool;
	public function new () {}
}

class MultiAliasedClass {
	@:alias("first") @:alias("public") public var isPublic : Bool;
	public function new () {}
}

class AliasTest extends haxe.unit.TestCase {

	public function test () {

		{
			var parser = new JsonParser<Aliased>();
			var data = parser.fromJson('{ "public": true }', "test");
			assertEquals(true, data.isPublic);
		}

		{
			var parser = new JsonParser<MultiAliased>();
			var data = parser.fromJson('{ "public": true }', "test");
			assertEquals(true, data.isPublic);
		}

		{
			var parser = new JsonParser<AliasedClass>();
			var data = parser.fromJson('{ "public": true }', "test");
			assertEquals(true, data.isPublic);
		}

		{
			var parser = new JsonParser<MultiAliasedClass>();
			var data = parser.fromJson('{ "public": true }', "test");
			assertEquals(true, data.isPublic);
		}

	}

}
