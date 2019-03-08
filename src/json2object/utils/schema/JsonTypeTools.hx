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

class JsonTypeTools {
	public static function toString(jt:JsonType) : String {
		return switch (jt) {
			case JTNull: '{"type":"null"}';
			case JTSimple(t): '{"type":"${t}"}';
			case JTObject(properties, rq):
				var str = new StringBuf();
				str.add('{"type":"object", "properties":{');
				var comma = false;
				var required = (rq.length > 0) ? '"required":["${rq.join('", "')}"]': "";
				for (key in properties.keys()) {
					if(comma) { str.add(", "); }
					str.add('"${key}": ${properties.get(key).toString()}');
					comma = true;
				}
				str.add('}, "additionalProperties": false, ${required}}');
				str.toString();
			case JTPatternObject(patterns):
				var p = "^" + patterns.join('|') + "$";
				'{"type":"object", "propertyNames":{"pattern":"${p}"}}';
			case JTArray(type): '{"type":"array", "items": [${type.toString()}]}';
			case JTMap(onlyInt, type):
				if (onlyInt) {
					'{"type":"object", "patternProperties": {"/^[-+]?\\d+([Ee][+-]?\\d+)?$/"} : ${type.toString()}}}';
				}
				else {
					'{"type": "object", "additionalProperties":${type.toString()}}';
				}
			case JTRef(name): '{"$$ref": "#/definitions/${name}"}';
			case JTAnyOf(values): '{"anyOf": [${values.map(toString).join(',')}]}';
			case JTEnum(values): '{"enum": [${values.join(',')}]}';
		}
	}
}