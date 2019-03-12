/*
Copyright (c) 2019 Guillaume Desquesnes, Valentin Lemière

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

package json2object.utils.schema;

using json2object.utils.schema.JsonTypeTools;
using json2object.writer.StringUtils;
using StringTools;

class JsonTypeTools {
	public static function toString(jt:JsonType) : String {
		return _toString(jt);
	}

	static function _toString(jt:JsonType, descr:String="}") : String {
		var end = descr;
		return switch (jt) {
			case JTNull: '{"type":"null"${end}';
			case JTSimple(t): '{"type":"${t}"${end}';
			case JTConst(v): '{"const":${v}$end';
			case JTObject(properties, rq):
				var str = new StringBuf();
				str.add('{"type":"object", "properties":{');
				var comma = false;
				var required = (rq.length > 0) ? ', "required":["${rq.join('", "')}"]': "";
				for (key in properties.keys()) {
					if(comma) { str.add(", "); }
					str.add('"${key}": ${properties.get(key).toString()}');
					comma = true;
				}
				str.add('}, "additionalProperties": false${required}${end}');
				str.toString();
			case JTArray(type): '{"type":"array", "items": ${type.toString()}${end}';
			case JTMap(onlyInt, type):
				if (onlyInt) {
					'{"type":"object", "patternProperties": {"/^[-+]?\\d+([Ee][+-]?\\d+)?$/"} : ${type.toString()}${end}';
				}
				else {
					'{"type": "object", "additionalProperties":${type._toString()}${end}';
				}
			case JTRef(name): '{"$$ref": "#/definitions/${name}"${end}';
			case JTAnyOf(types): '{"anyOf": [${types.map(toString).join(', ')}]${end}';
			case JTWithDescr(type, descr): _toString(type, ', "description": ${clean(descr).quote()}}');
		}
	}

	/**
	 * Clean the doc
	 * 2 new line => 1 new line
	 * 1 new line => 0 new line
	 * all line first non whitespace char is * then remove all first *
	 */
	static function clean (doc:String) : String {
		var lines = [];
		var hasStar = true;
		var start = 0;
		var cursor = 0;
		while (cursor < doc.length) {
			switch (doc.charAt(cursor)) {
				case "\r":
					if (doc.charAt(cursor+1) == "\n") {
						cursor++;
					}
					var line = doc.substring(start, cursor).trim();
					lines.push(line);
					start = cursor + 1;
					if (line.length > 0) {
						hasStar = hasStar && (line.charAt(0) == '*');
					}
				case "\n":
					var line = doc.substring(start, cursor).trim();
					lines.push(line);
					start = cursor + 1;
					if (line.length > 0) {
						hasStar = hasStar && (line.charAt(0) == '*');
					}
				default:
			}
			cursor++;
		}

		var consecutiveNewLine = 0;
		var result = [""];
		var i = -1;
		for (line in lines) {
			if (line.length == 0) {
				if (i == -1) {
					continue;
				}
				consecutiveNewLine++;
			}
			else {
				var next = (hasStar) ? line.substr(1) : line;
				if (i == -1) { i = 0; }
				else {
					var curr = result[i];
					if (curr != "" && curr.charAt(curr.length - 1) != " " && next.charAt(0) != " ") {
						next = " " + next;
					}
				}
				result[i] += next;
				consecutiveNewLine++;
			}
			if (consecutiveNewLine > 1) {
				result.push('');
				i++;
				consecutiveNewLine = 0;
			}
		}
		return result.join("\n");
	}
}