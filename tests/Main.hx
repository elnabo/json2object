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

class Main
{
	public static function main ()
	{
		printTarget();

		var allOk = true;
		var r = new utest.Runner();

		r.addCase(new AbstractTest());
		r.addCase(new AliasTest());
		r.addCase(new ArrayTest());
		r.addCase(new CustomTest());
		r.addCase(new EnumTest());
		#if haxe4
		r.addCase(new FinalTest());
		#end
		r.addCase(new GetSetTest());
		r.addCase(new InheritanceTest());
		r.addCase(new MapTest());
		r.addCase(new ObjectTest());
		r.addCase(new StructureTest());
		r.addCase(new UIntTest());

		utest.ui.Report.create(r, NeverShowSuccessResults, AlwaysShowHeader);
		r.run();
	}

	static function printTarget()
	{
		#if (cpp && !cppia)
		trace("cpp");
		#elseif cppia
		trace("cppia");
		#elseif cs
		trace("cs");
		#elseif flash
		trace("flash");
		#elseif hl
		trace("hl");
		#elseif interp
		trace("interp");
		#elseif java
		trace("java");
		#elseif js
		trace("js");
		#elseif lua
		trace("lua");
		#elseif neko
		trace("neko");
		#elseif php
		trace("php");
		#elseif python
		trace("python");
		#else
		trace("unknown");
		#end
	}
}
