/*
Copyright (c) 2016 Guillaume Desquesnes, Valentin Lemière

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

package json2object;

/**
 * Allow the print of error in the same format as the haxe compiler.
 */
class ErrorUtils {
	public static function convertError (e:Error) : String {
		var pos = switch (e) {
			case IncorrectType(_, _, pos) | IncorrectEnumValue(_, _, pos) | InvalidEnumConstructor(_, _, pos) | UninitializedVariable(_, pos) | UnknownVariable(_, pos) | ParserError(_, pos): pos;
		}

		var res = pos != null ? '${pos.file}:${pos.line.number}: characters ${pos.line.start}-${pos.line.end} : ' : "";

		switch (e)
		{
			case IncorrectType(variable, expected, _):
				res += 'variable \'${variable}\' should have been of type \'${expected}\'';

			case IncorrectEnumValue(variable, expected, _):
				res += 'identifier \'${variable}\' is not a part of type \'${expected}\'';

			case InvalidEnumConstructor(variable, expected, _):
				res += '\'${variable}\' is used with an invalid number of arguments for type \'${expected}\'';

			case UnknownVariable(variable, _):
				res += 'variable \'${variable}\' isn\'t in the schema';

			case UninitializedVariable(variable, _):
				res += 'variable \'${variable}\' isn\'t in the json';

			case ParserError(message, _):
				res += 'parser eror: ${message}';
		}

		return res;
	}

	public static function convertErrorArray (e:Array<Error>) : String {
		return e.map(convertError).join("\n");
	}
}
