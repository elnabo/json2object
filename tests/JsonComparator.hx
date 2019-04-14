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

using StringTools;

class JsonComparator {

	static function splitArray(arr:String) : Array<String> {
		var result = [];
		arr = arr.substr(1);
		var length = arr.length;

		var inObjDepth = 0;
		var inArrayDepth = 0;

		var i = 0;
		while (i < length) {
			var next = i;
			while (next < length) {
				var c = arr.charAt(next);
				switch (c) {
					case '[': inArrayDepth++;
					case ']': inArrayDepth--;
					case '{': inObjDepth++;
					case '}': inObjDepth--;
					case ',' if (inObjDepth == 0 && inArrayDepth == 0): break;
				}
				next++;
			}
			result.push(arr.substring(i, next));
			i = next + 1;
		}
		return result;
	}

	static function splitObject (obj:String) : Map<String,String> {
		var result = new Map<String, String>();
		obj = obj.substr(1);
		var length = obj.length;
		var key = '';

		var inObjDepth = 0;
		var inArrayDepth = 0;

		var valueStart = 0;

		var i = 0;
		while (i < length) {
			var next = obj.indexOf(':', i);
			key = obj.substr(i, next).trim();

			next++;
			var valueStart = next;

			while (next < length) {
				var c = obj.charAt(next);
				switch (c) {
					case '[': inArrayDepth++;
					case ']': inArrayDepth--;
					case '{': inObjDepth++;
					case '}': inObjDepth--;
					case ',' if (inObjDepth == 0 && inArrayDepth == 0): break;
				}
				next++;
			}
			result.set(key, obj.substring(valueStart, next));
			i = next + 1;
		}
		return result;
	}

	public static function areSame (a:String, b:String) : Bool {
		if (a == b) {
			return true;
		}

		var length = a.length;
		if (b.length != length) {
			return false;
		}

		var firstA = a.charAt(0);
		var firstB = b.charAt(0);

		if (firstA == '{' && firstB == '{') {
			var propsA = splitObject(a);
			var propsB = splitObject(a);

			for (key in propsA.keys()) {
				if (!propsB.exists(key)) {
					return false;
				}
				if (!areSame(propsA.get(key), propsB.get(key))) {
					return false;
				}
			}

			return true;
		}

		if (firstA == '[' && firstB == '[') {
			var valuesA = splitArray(a);
			var valuesB = splitArray(b);

			for (s1 in valuesA) {
				var found = false;
				for (s2 in valuesB) {
					if (areSame(s1, s2)) {
						found = true;
						break;
					}
				}
				if (!found) {
					return false;
				}
			}
			return true;
		}

		return false;
	}
}