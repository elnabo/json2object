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
abstract Rights (Array<String>) from Array<String> to Array<String>
{
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
	}

}
