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
 * Transform a hxjsonast.Position into a Position, which provides information on lines.
 */
class PosUtils {
	/** Store line information (number/start/end). */
	var linesInfo = new Array<Line>();

	public function new(content:String) {
		var s = 0;
		var e = 0;

		var i = 0;
		var lineCount = 0;
		while (i < content.length) {
			switch (content.charAt(i)) {
				case "\r":
					e = i;
					if (content.charAt(i+1) == "\n") {
						e++;
					}
					linesInfo.push({ number: lineCount, start: s, end: e });
					lineCount++;
					i = e+1;
					s = i;
				case "\n":
					e = i;
					linesInfo.push({ number: lineCount, start: s, end: e });
					lineCount++;
					i++;
					s = i;
				default:
					i++;
			}
		}
	}

	/**
	 * Convert a hxjsonast.Position into a Position who contains information on lines.
	 */
	public function convertPosition(position:hxjsonast.Position):Position {
		var file = position.file;
		var min = position.min;
		var max = position.max;

		for (line in linesInfo) {
			if (line.start <= min && line.end >= max) {
				return { file: file, line: { number: line.number, start: min-line.start, end: max-line.start }, min: min, max: max };
			}
		}
		return null;
	}
}
