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
package json2object.writer;

#if !macro
class DataBuilder {}
#else
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class DataBuilder {

	private static var counter = 0;
	private static var writers = new Map<String, Type>();

	private static function notNull (type:Type) : Type {
		return switch (type) {
			case TAbstract(_.get()=>t, p):
				(t.name == "Null") ? notNull(p[0]) : type;
			case TType(_.get()=>t, p):
				(t.name == "Null") ? notNull(type.follow()) : type;
			default:
				type;
		}
	}

	private static function isNullable (type:Type) : Bool {
		if (notNull(type) != type) { return true; }
		return switch (type.followWithAbstracts()) {
			case TAbstract(_.get()=>t,_):
				!t.meta.has(":notNull");
			default:
				true;
		}
	}

	private static function makeStringWriter () : Expr {
		return macro return (o == null) ? "null" : json2object.writer.StringUtils.quote(cast o);
	}

	private static function makeBasicWriter (type:Type) : Expr {
		return isNullable(type)
			? macro return (o == null) ? "null" : o+""
			: macro return o+"";
	}

	private static function makeArrayWriter (subType:Type, baseParser:BaseType) : Expr {
		var cls = { name:baseParser.name, pack:baseParser.pack, params:[TPType(subType.toComplexType())]};
		return macro {
			if (o == null) { return "null"; }
			var valueWriter = new $cls();
			var json = "[";
			var values =  [for (element in o) valueWriter.write(element)];
			json += values.join(",");
			json += "]";
			return json;
		};
	}

	private static function makeMapWriter (keyType:Type, valueType:Type,  baseParser:BaseType) : Expr {
		var clsValue = { name:baseParser.name, pack:baseParser.pack, params:[TPType(valueType.toComplexType())]};

		var keyMacro = switch (keyType.followWithAbstracts()) {
			case TInst(_.get()=>t, _):
				if (t.module == "String") {
					macro json2object.writer.StringUtils.quote(key);
				}
				else {
					Context.fatalError("json2object: Only map with Int or String key are writable, got"+keyType.toString(), Context.currentPos());
				}
			case TAbstract(_.get()=>t, _):
				if (t.module == "StdTypes" && t.name == "Int") {
					macro key;
				}
				else {
					Context.fatalError("json2object: Only map with Int or String key are writable, got"+keyType.toString(), Context.currentPos());
				}
			default: Context.fatalError("json2object: Only map with Int or String key are writable, got"+keyType.toString(), Context.currentPos());
		}

		return macro {
			if (o == null) { return "null"; }
			var valueWriter = new $clsValue();

			var json = "{";
			var values =  [for (key in o.keys()) '"'+key+'": '+valueWriter.write(o.get(key))];
			json += values.join(",");
			json += "}";
			return json;
		};
	}

	private static function makeObjectOrAnonWriter (type:Type, baseParser:BaseType) : Expr {
		var isAnon = false;
		var fields:Array<ClassField>;

		var tParams:Array<TypeParameter>;
		var params:Array<Type>;

		switch (type) {
			case TAnonymous(_.get()=>t):
				isAnon = true;
				fields = t.fields;
				tParams = [];
				params = [];

			case TInst(_.get()=>t, p):
				if (t.isPrivate)
				{
					t = TypeUtils.copyType(t);
					trace(t);
				}

				fields = [];
				var s = t;
				while (s != null)
				{
					fields = fields.concat(s.fields.get());
					s = s.superClass != null ? s.superClass.t.get() : null;
				}

				tParams = t.params;
				params = p;

				var pack = t.module.split(".");
				pack.push(t.name);

			case _: return macro return null;
		}

		var assignations:Array<Expr> = [];
		for (field in fields) {
			if (field.meta.has(":jignored")) { continue; }
			switch(field.kind) {
				case FVar(r,w):
					if (r == AccCall && w == AccCall && !field.meta.has(":isVar")) {
						continue;
					}

					var f_a = (r == AccCall || r == AccNever || r == AccNo) ? macro Reflect.field(o, $v{field.name}) : { expr: EField(macro o, field.name), pos: Context.currentPos() };
					var f_type = field.type.applyTypeParameters(tParams, params);
					var f_cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(f_type.toComplexType())]};

					var name = field.name;
					for (m in field.meta.get()) {
						if (m.name == ":alias" && m.params.length == 1) {
							switch (m.params[0].expr) {
								case EConst(CString(s)):
									name = s;
								default:
							}
						}
					}
					name = '"' + name + '": ';
					assignations.push(macro $v{name} + new $f_cls().write(cast $f_a));

				default:
			}
		}
		var array = {expr:EArrayDecl(assignations), pos:Context.currentPos()};

		return macro {
			if (o == null) { return "null"; }
			var json = "{";
			@:privateAccess{
				json += ${array}.join(", ");
			}
			json += "}";
			return json;
		};
	}

	private static function makeEnumWriter (type:Type, baseParser:BaseType) : Expr {
		var tParams:Array<TypeParameter>;
		var params:Array<Type>;

		var cases = [];
		switch (type) {
			case TEnum(_.get()=>t, p):
				tParams = t.params;
				params = p;
				for (n in t.names) {
					switch (t.constructs.get(n).type) {
						case TEnum(_,_):
							var value = '"'+n+'"';
							cases.push({expr: macro $v{value}, guard: null, values: [macro $i{n}]});
						case TFun(args, _):
							var constructor = [];
							var assignations:Array<Expr> = [];
							for (a in args) {
								constructor.push(macro $i{a.name});

								var a_type = a.t.applyTypeParameters(tParams, params);
								var a_cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(a_type.toComplexType())]};

								assignations.push(macro '"'+$v{a.name} +'": '+ new $a_cls().write($i{a.name}));
							}


							var call = {expr:ECall(macro $i{n}, constructor), pos:Context.currentPos()};
							var array = {expr:EArrayDecl(assignations), pos:Context.currentPos()};
							var jsonExpr = macro {
								var json = '{"'+$v{n}+'": {';
								json += ${array}.join(", ");
								json += '}}';
							}
							cases.push({expr: jsonExpr, guard: null, values: [call]});

						default:
					}
				}
			default:
		}
		var switchExpr = {expr:ESwitch(macro o, cases, null), pos:Context.currentPos()};
		return macro {
			if (o == null) { return null; }
			return $switchExpr;
		};
	}

	private static function makeAbstractEnumWriter (type:Type) : Expr {
		switch (type.followWithAbstracts()) {
			case TInst(_.get()=>t, _):
				if (t.module != "String") {
					Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
				}
				else {
					return makeStringWriter();
				}
			case TAbstract(_.get()=>t, _):
				if (t.module != "StdTypes" && (t.name != "Int" && t.name != "Bool" && t.name != "Float")) {
					Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
				}
				else {
					return makeBasicWriter(type);
				}
			default: Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
		}
		return null;
	}

	public static function makeWriter (c:BaseType, type:Type, base:Type) {

		if (base == null) { base = type; }

		var writerMapName = base.toString();
		if (writers.exists(writerMapName)) {
			return writers.get(writerMapName);
		}

		var writerName = c.name + "_" + (counter++);
		var writerClass = macro class $writerName {
			public function new () {}
		};

		var writeExpr = switch (type) {
			case TInst(_.get()=>t, p) :
				switch(t.module) {
					case "String":
						makeStringWriter();
					case "Array":
						if (p.length == 1 && p[0] != null) {
							makeArrayWriter(p[0], c);
						}
						else {
							macro return null;
						}
					case _:
						switch (t.kind) {
							case KTypeParameter(_):
								Context.fatalError("json2object: Type parameters are not writable: " + t.name, Context.currentPos());

							default:
								macro return null;
						}
						makeObjectOrAnonWriter(type, c);
				}
			case TAnonymous(_.get()=>t):
				makeObjectOrAnonWriter(type, c);
			case TAbstract(_.get()=>t, p):
				if (t.name == "Null") {
					return makeWriter(c, p[0], type);
				}
				else if (t.module == "StdTypes") {
					switch (t.name) {
						case "Int", "Float", "Singe", "Bool":
							makeBasicWriter(base);
						default: Context.fatalError("json2object: Parser of "+t.name+" are not generated", Context.currentPos());
					}
				}
				else if (t.module == #if (haxe_ver >= 4) "haxe.ds.Map" #else "Map" #end) {
					makeMapWriter(p[0], p[1], c);
				}
				else {
					if (t.meta.has(":enum")) {
						makeAbstractEnumWriter(type.applyTypeParameters(t.params, p));
					}
					else {
						var ap = t.type.applyTypeParameters(t.params, p);
						return makeWriter(c, ap, ap);
					}
				}
			case TEnum(_.get()=>t, p):
				makeEnumWriter(type.applyTypeParameters(t.params, p), c);
			case TType(_.get()=>t, p) :
				return makeWriter(c, t.type.applyTypeParameters(t.params, p), type);
			case TLazy(f):
				return makeWriter(c, f(), f());
			default: Context.fatalError("json2object: Writer for "+type.toString()+" are not generated", Context.currentPos());
		}

		var write:Field = {
			doc: null,
			kind: FFun({args:[{name:"o", meta:null, opt:false, type:base.toComplexType(),value:null}], expr:writeExpr, params:null, ret:null}),
			access: [APublic],
			name: "write",
			pos:Context.currentPos(),
			meta: null
		}
		writerClass.fields.push(write);

		haxe.macro.Context.defineType(writerClass);

		var constructedType = haxe.macro.Context.getType(writerName);
		writers.set(writerMapName, constructedType);
		return constructedType;

	}

	public static function build() {
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeWriter(c.get(), type, type);
			case _:
				Context.fatalError("json2object: Writing tools must be a class", Context.currentPos());
				return null;
		}
	}
}
#end
