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
package json2object;

import StringTools;

/**
 *  Taken from https://github.com/HaxeFoundation/haxe/blob/875ad19432abc2cec6b345cc49a880f5c7f3c98a/std/haxe/format/JsonPrinter.hx
 */
class StringUtils {
	public static function quote(s:String) : String {
		#if (neko || php || cpp)
		if( s.length != haxe.Utf8.length(s) ) {
			return quoteUtf8(s);
		}
		#end
		var buffer = new StringBuf();
		buffer.add('"');
		var i = 0;
		while( true ) {
			var c = StringTools.fastCodeAt(s, i++);
			if( StringTools.isEof(c) ) break;
			switch( c ) {
			case '"'.code: buffer.add('\\"');
			case '\\'.code: buffer.add('\\\\');
			case '\n'.code: buffer.add('\\n');
			case '\r'.code: buffer.add('\\r');
			case '\t'.code: buffer.add('\\t');
			case 8: buffer.add('\\b');
			case 12: buffer.add('\\f');
			default:
				#if flash
				if( c >= 128 ) buffer.add(String.fromCharCode(c)) else addChar(c);
				#else
				buffer.addChar(c);
				#end
			}
		}
		buffer.add('"');
		return buffer.toString();
	}

	#if (neko || php || cpp)
	static function quoteUtf8( s : String ) {
		var u = new haxe.Utf8();
		haxe.Utf8.iter(s,function(c) {
			switch( c ) {
			case '\\'.code, '"'.code: u.addChar('\\'.code); u.addChar(c);
			case '\n'.code: u.addChar('\\'.code); u.addChar('n'.code);
			case '\r'.code: u.addChar('\\'.code); u.addChar('r'.code);
			case '\t'.code: u.addChar('\\'.code); u.addChar('t'.code);
			case 8: u.addChar('\\'.code); u.addChar('b'.code);
			case 12: u.addChar('\\'.code); u.addChar('f'.code);
			default: u.addChar(c);
			}
		});
		return '"' + u.toString() + '"';
	}
	#end
}