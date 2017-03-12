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

class ArrayTest extends haxe.unit.TestCase {

	public function test () {
		{
			var parser = new json2object.JsonParser<Array<Int>>();
			var data = parser.fromJson('[0,1,4,3]', "");
			var oracle = [0,1,4,3];
			for (i in 0...data.length) {
				assertEquals(oracle[i],data[i]);
			}
			assertEquals(0, parser.warnings.length);

			data = parser.fromJson('[0,1,4.4,3]', "");
			assertEquals(1, parser.warnings.length);
			oracle = [0,1,3];
			for (i in 0...data.length) {
				assertEquals(oracle[i],data[i]);
			}
		}
	}

}
