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
 * Error raised during an initialization by JSON.
 */
enum Error {
	/**
	 * Mismatch between instance type and json type.
	 *
	 * @param variable Variable affected.
	 * @param expected Expected type.
	 * @param pos Position in the JSON file.
	 */
	IncorrectType(variable:String, expected:String, pos:Position);

	/**
	 * Variable has not been initialized.
	 *
	 * @param variable Variable affected.
	 * @param pos Position in the JSON file.
	 */
	UninitializedVariable(variable:String, pos:Position);

	/**
	 * No instance variable corresponding to this JSON variable.
	 *
	 * @param variable Variable affected.
	 * @param pos Position in the JSON file.
	 */
	UnknownVariable(variable:String, pos:Position);

	/**
	 * Incorrect JSON file formating.
	 *
	 * @param message Message raised.
	 * @param pos Position in the JSON file.
	 */
	ParserError(message:String, pos:Position);
}
