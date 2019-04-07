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

import haxe.macro.Context;
import haxe.macro.Expr;

using json2object.writer.StringUtils;
using StringTools;

typedef AnonDecls = Map<String, {field:String, expr:Expr}>

typedef Schema = {
	@:optional
	var const: Null<String>;
	@:optional @:alias('const')
	var const_bool : Bool;
	@:optional @:alias('const')
	var const_int : Int;
	@:optional @:alias('const')
	var const_float : Float;
	@:optional
	var description: String;
	@:optional
	var type: String;
	@:optional @:alias("$schema")
	var __j2o_s_a_0: String;
	@:optional @:alias("$ref")
	var __j2o_s_a_1: String;
	@:optional
	var required: Array<String>;
	@:optional
	var properties: Map<String, Schema>;
	@:optional
	var additionalProperties: Bool;
	@:optional @:alias("additionalProperties")
	var additionalProperties_obj: Schema;
	@:optional
	var items: Schema;
	@:optional
	var patternProperties: Map<String, Schema>;
	@:optional
	var anyOf: Array<Schema>;
	@:optional
	var definitions: Map<String, Schema>;
}

class JsonTypeTools {
#if macro

	static var id = 2;
	static final prefix = '__j2o_s_a_';
	static final store = [
		"$schema" => "__j2o_s_a_0",
		"$ref" => "__j2o_s_a_1"
	];
	static final reverseStore = new Map<String, String>();
	public static function registerAlias (name:String) : String {
		if (store.exists(name)) {
			return store.get(name);
		}
		var alias = prefix+(id++);
		store.set(name, alias);
		reverseStore.set(alias, name);
		return alias;
	}

	static function unstore (alias:String) : String {
		return reverseStore.get(alias);
	}

	inline static function str2Expr (str:String) : Expr {
		return macro $v{str};
	}

	inline static function nullable (ct:ComplexType) : ComplexType {
		return TPath({name: "Null", pack:[], params:[ TPType(ct)], sub:null});
	}

	public static function toExpr(jt:JsonType) : Expr {
		return _toExpr(jt, '');
	}

	private static function fieldDeclToExpr (fields:Array<{field:String, expr:Expr}>) : Expr {
		#if haxe4
		return {
			expr: EObjectDecl(fields.map(function (f) : ObjectField {
				return {field:f.field, expr:f.expr, quotes:Quoted};
			})),
			pos: Context.currentPos()
		};
		#else
		return {expr: EObjectDecl(fields), pos: Context.currentPos()};
		#end
	}

	static inline function getBaseDecl () : AnonDecls {
		var base = new AnonDecls();
		inline function decl (name:String) {
			base.set(name, {field:name, expr: macro null});
		}
		var fields = [
			"description", "type", "properties",
			registerAlias("$ref"), "const", "required", "anyOf",
			"additionalProperties", "items", "patternProperties",
			"const_bool", "const_int", "const_float", "additionalProperties_obj"
		];
		for (f in fields) {
			decl(f);
		}
		return base;
	}

	static function declsToAnonDecl (decls:AnonDecls) : Expr {
		#if haxe4
		return {
			expr:EObjectDecl([ for (k=>v in decls) {field:k, expr:v.expr, quotes:Quoted}]),
			pos:Context.currentPos()
		};
		#else
		return {
			expr:EObjectDecl([ for (values in decls.values()) values),
			pos:Context.currentPos()
		};
		#end
	}

	static function _toExpr(jt:JsonType, descr:String) : Expr {
		var decls = getBaseDecl();

		switch (jt) {
			case JTNull:
				decls.get("type").expr = macro "null";
			case JTSimple(t):
				decls.get("type").expr = str2Expr(t);
			case JTString(s):
				decls.get("const").expr = macro $v{s};
			case JTBool(b):
				decls.get("const_bool").expr = (b) ? macro true : macro false;
			case JTFloat(f):
				decls.get("const_float").expr = macro $v{f};
			case JTInt(i):
				decls.get("const_int").expr = macro $v{i};
			case JTObject(properties, rq):
				decls.get("type").expr = macro 'object';
				var propertiesDecl = [];
				for (key in properties.keys()) {
					propertiesDecl.push({
						expr:EBinop(
							OpArrow,
							macro $v{key},
							toExpr(properties.get(key))
						),
						pos:Context.currentPos()
					});
				}
				var propertiesExpr = {expr: EArrayDecl(propertiesDecl), pos: Context.currentPos()};
				decls.get("properties").expr = propertiesExpr;
				if (rq.length > 0) {
					var requiredExpr = {expr:EArrayDecl(rq.map(str2Expr)), pos: Context.currentPos()};
					decls.get("required").expr = requiredExpr;
				}
				decls.get("additionalProperties").expr = macro false;
			case JTArray(type):
				decls.get("type").expr = macro "array";
				decls.get("items").expr = toExpr(type);
			case JTMap(onlyInt, type):
				decls.get("type").expr = macro "object";
				if (onlyInt) {
					var patternPropertiesExpr = {
						expr: EArrayDecl([
							{expr:EBinop(OpArrow, macro "/^[-+]?\\d+([Ee][+-]?\\d+)?$/", toExpr(type)), pos:Context.currentPos()}
						]),
						pos: Context.currentPos()
					}
					decls.get("patternProperties").expr = patternPropertiesExpr;
				}
				else {
					decls.get("additionalProperties_obj").expr = toExpr(type);
				}
			case JTRef(name):
				decls.get(registerAlias("$ref")).expr = str2Expr('#/definitions/'+name);
			case JTAnyOf(types):
				var anyOfExpr = {expr: EArrayDecl(types.map(toExpr)), pos:Context.currentPos()};
				decls.get("anyOf").expr = anyOfExpr;
			case JTWithDescr(type, descr):
				return _toExpr(type, descr);
		}

		if (descr != '') {
			decls.get("description").expr = str2Expr(clean(descr).quote());
		}

		return declsToAnonDecl(decls);
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
#end
}