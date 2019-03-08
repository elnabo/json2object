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

#if !macro
class DataBuilder {}
#else
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;

import json2object.utils.schema.JsonType;
using json2object.utils.schema.JsonTypeTools;
using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class DataBuilder {

	static var counter:Int = 0;
	static final definitions = new Map<String, JsonType>();

	private static function notNull(type:Type):Type {
		return switch (type) {
			case TAbstract(_.get()=>t, p):
				(t.name == "Null") ? notNull(p[0]) : type;
			case TType(_.get()=>t, p):
				(t.name == "Null") ? notNull(type.follow()) : type;
			default:
				type;
		}
	}

	private static function isNullable(type:Type) {
		if (notNull(type) != type) { return true; }
		return switch (type.followWithAbstracts()) {
			case TAbstract(_.get()=>t,_):
				!t.meta.has(":notNull");
			default:
				true;
		}
	}

	static function anyOf(t1:JsonType, t2:JsonType) {
		return switch [t1, t2] {
			case [JTAnyOf(v1), JTAnyOf(v2)]: JTAnyOf(v1.concat(v2));
			case [JTAnyOf(val), t], [t, JTAnyOf(val)]: JTAnyOf(val.concat([t]));
			default: JTAnyOf([t1, t2]);
		}
	}

	static function makeAbstractSchema(type:Type):JsonType {
		var name = type.toString();
		switch (type) {
			case TAbstract(_.get()=>t, p):
				var jt:Null<JsonType> = null;
				var from = (t.from.length == 0) ? [{t:t.type, field:null}] : t.from;
				var possiblesJT:Array<JsonType> = [];
				var i = 0;
				for(fromType in from) {
					try {
						var ft = fromType.t.followWithAbstracts();
						possiblesJT.push(makeSchema(ft));
						if (isNullable(ft)) {
							jt = JTNull;
						}
					}
					catch (_:#if (haxe_ver >= 4) Any #else Dynamic #end) {}
				}
				if (possiblesJT.length == 0) {
					throw "Abstract "+name+ " has no Json representation "+ Context.currentPos();
				}
				if (jt == null) {
					jt = possiblesJT.pop();
				}
				while (possiblesJT.length > 0) {
					jt = anyOf(jt, possiblesJT.pop());
				}
				definitions.set(name, jt);
				return JTRef(name);
			default:
				throw "Unexpected type "+name;
		}
	}
	static function makeAbstractEnumSchema(type:Type):JsonType {
		var name = type.toString();
		var addnull = isNullable(type);
		switch (type.followWithAbstracts()) {
			case TInst(_.get()=>t, _):
				if (t.module != "String") {
					throw "json2object: Unsupported abstract enum type:"+ name + " " + Context.currentPos();
				}
				name = "String";
			case TAbstract(_.get()=>t, _):
				if (t.module != "StdTypes" && (t.name != "Int" && t.name != "Bool" && t.name != "Float")) {
					throw "json2object: Unsupported abstract enum type:"+ name + " " + Context.currentPos();
				}
				name = t.name;
			default: throw "json2object: Unsupported abstract enum type:"+ name + " " + Context.currentPos();
		}
		var strValues = new Array<String>();
		var otherValues = new Array<Dynamic>();
		switch (type) {
			case TAbstract(_.get()=>t, p) :
				for (field in t.impl.get().statics.get()) {
					if (!field.meta.has(":enum") || !field.meta.has(":impl")) {
						continue;
					}
					if (field.expr() == null) { continue; }
					switch (field.expr().expr) {
						case TConst(TString(s)): strValues.push(s);
						case TConst(TNull): otherValues.push(null); addnull = false;
						case TConst(TBool(b)): otherValues.push(b);
						case TConst(TFloat(f)): otherValues.push(f);
						case TConst(TInt(i)): otherValues.push(i);
						default:
					}
				}
			default:
		}

		if (strValues.length == 0 && otherValues.length == 0) {
			throw 'json2object: Abstract enum ${name} has no supported value';
		}

		strValues = strValues.map(function (s) { return '"' + json2object.writer.StringUtils.quote(s) + '"'; });
		var jt = JTEnum(otherValues.concat(strValues));
		if (addnull) {
			jt = anyOf(JTNull, jt);
		}
		definitions.set(name, jt);
		return JTRef(name);
	}
	static function makeEnumSchema(type:Type):JsonType {
		var name = type.toString();

		var simple = [];
		var complex = [];
		switch (type) {
			case TEnum(_.get()=>t, p):
				for (n in t.names) {
					var valuename = name+".$enumvalue$"+n;
					switch (t.constructs.get(n).type) {
						case TEnum(_,_):
							simple.push(n);
						case TFun(args,_):
							var properties = new Map<String, JsonType>();
							var required = [];
							for (a in args) {
								properties.set(a.name, makeSchema(a.t));
								if (!a.opt) {
									required.push(a.name);
								}
							}
							complex.push(JTObject(properties, required));
						default:
					}
				}
			default:
		}

		var jt = JTNull;

		while (complex.length > 0) {
			jt = anyOf(jt, complex.pop());
		}

		if (simple.length > 0) {
			jt = anyOf(jt, JTPatternObject([for (s in simple) s]));
			jt = anyOf(jt, JTEnum(simple.map(function (s) { return '"' + json2object.writer.StringUtils.quote(s) + '"'; })));
		}
		definitions.set(name, jt);
		return JTRef(name);
	}

	static function makeMapSchema(keyType:Type, valueType:Type):JsonType {
		var name = "Map_" + keyType.toString() + "_" + valueType.toString();
		if (definitions.exists(name)) {
			return JTRef(name);
		}
		var onlyInt = switch (keyType) {
			case TInst(_.get()=>t, _):
				if (t.module == "String") {
					false;
				}
				else {
					throw "json2object: Only map with Int or String key can be transformed to json, got"+keyType.toString() + " " + Context.currentPos();
				}
			case TAbstract(_.get()=>t, _):
				if (t.module == "StdTypes" && t.name == "Int") {
					true;
				}
				else {
					throw "json2object: Only map with Int or String key can be transformed to json, got"+keyType.toString() + " " + Context.currentPos();
				}
			default:
				throw "json2object: Only map with Int or String key can be transformed to json, got"+keyType.toString() + " " + Context.currentPos();
		}
		definitions.set(name, anyOf(JTNull, JTMap(onlyInt, makeSchema(valueType))));
		return JTRef(name);
	}
	static function makeObjectSchema(type:Type, name:String):JsonType {
		var properties = new Map<String, JsonType>();
		var required = new Array<String>();

		var fields:Array<ClassField>;

		var tParams:Array<TypeParameter>;
		var params:Array<Type>;

		switch (type) {
			case TAnonymous(_.get()=>t):
				fields = t.fields;
				tParams = [];
				params = [];

			case TInst(_.get()=>t, p):
				fields = [];
				var s = t;
				while (s != null)
				{
					fields = fields.concat(s.fields.get());
					s = s.superClass != null ? s.superClass.t.get() : null;
				}

				tParams = t.params;
				params = p;

			case _: throw "Unexpected type "+name;
		}

		for (field in fields) {
			if (field.meta.has(":jignored")) { continue; }
			switch(field.kind) {
				case FVar(r,w):
					if (r == AccCall && w == AccCall && !field.meta.has(":isVar")) {
						continue;
					}

					if (!field.meta.has(":optional")) {
						required.push(field.name);
					}

					var f_type = field.type.applyTypeParameters(tParams, params);
					properties.set(field.name, makeSchema(f_type));
				default:
			}
		}

		definitions.set(name, anyOf(JTNull, JTObject(properties, required)));

		return JTRef(name);
	}

	static function makeSchema(type:Type, ?name:String=null) : JsonType {

		if (name == null) {
			name = type.toString();
		}

		if (definitions.exists(name)) {
			return JTRef(name);
		}

		var schema = switch (type) {
			case TInst(_.get()=>t, p):
				switch (t.module) {
					case "String":
						return anyOf(JTNull, JTSimple("string"));
					case "Array" if (p.length == 1 && p[0] != null):
						return anyOf(JTNull, JTArray(makeSchema(p[0])));
					default:
						makeObjectSchema(type, name);
				}
			case TAnonymous(_):
				makeObjectSchema(type, name);
			case TAbstract(_.get()=>t, p):
				if (t.name == "Null") {
					return anyOf(JTNull, makeSchema(p[0]));
				}
				else if (t.module == "StdTypes") {
					switch (t.name) {
						case "Int": return JTSimple("integer");
						case "Float", "Single": JTSimple("number");
						case "Bool": return JTSimple("boolean");
						default: throw "json2object: Schema of "+t.name+" can not be generated " + Context.currentPos();
					}
				}
				else if (t.module == #if (haxe_ver >= 4) "haxe.ds.Map" #else "Map" #end) {
					makeMapSchema(p[0], p[1]);
				}
				else {
					if (t.meta.has(":enum")) {
						makeAbstractEnumSchema(type.applyTypeParameters(t.params, p));
					}
					else {
						var ap = t.type.applyTypeParameters(t.params, p);
						makeAbstractSchema(ap);
					}
				}
			case TEnum(_.get()=>t,p):
				makeEnumSchema(type.applyTypeParameters(t.params, p));
			case TType(_.get()=>t, p):
				makeSchema(t.type.applyTypeParameters(t.params, p), name);
				// makeSchema(c, t.type.applyTypeParameters(t.params, p), t.module.split(".").concat([t.name]).join("."));
			case TLazy(f):
				makeSchema(f());
			default:
				throw "json2object: Json schema can not make a schema for type " + name + " " + Context.currentPos();
		}
		return schema;
	}

	static function format(schema:JsonType) : String {
		var buf = new StringBuf();
		buf.add('{\n');
		buf.add('"$$schema": "http://json-schema.org/draft-07/schema#",\n');
		var hasDef = definitions.keys().hasNext();
		if (hasDef) {
			buf.add('"definitions":{');
			var comma = false;
			for (defName in definitions.keys()) {
				if (comma) { buf.add(", "); }
				buf.add('"$defName": ${definitions.get(defName).toString()}');
				comma = true;
			}
			buf.add('},\n');
		}
		var s = schema.toString();
		buf.add(s.substring(1, s.length - 1));
		buf.add('\n}');
		return buf.toString();
	}

	static function makeSchemaWriter(c:BaseType, type:Type, base:Type=null) {
		var swriterName = c.name + "_" + (counter++);
		var schema = format(makeSchema(type));
		var schemaWriter = macro class $swriterName {
			public function new() {}
			public function generate () {
				return $v{schema};
			}
		}
		haxe.macro.Context.defineType(schemaWriter);
		return haxe.macro.Context.getType(swriterName);
	}

	public static function build() {
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeSchemaWriter(c.get(), type);
			case _:
				Context.fatalError("json2object: Json schema tools must be a class", Context.currentPos());
				return null;
		}
	}
}
#end