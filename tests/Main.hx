/*
Copyright (c) 2017 Guillaume Desquesnes, Valentin Lemière

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
		var allOk = true;
		var r = new utest.Runner();
		
		r.addCase(new AliasTest());
		r.addCase(new AbstractTest());
		r.addCase(new ArrayTest());
		r.addCase(new EnumTest());
		r.addCase(new InheritanceTest());
		r.addCase(new MapTest());
		r.addCase(new ObjectTest());
		r.addCase(new StructureTest());

		r.onProgress.add(function (result) {
			allOk = allOk && result.result.allOk();
		});

		utest.ui.Report.create(r, ShowSuccessResultsWithNoErrors, AlwaysShowHeader);
		r.run();

		#if sys
		Sys.exit(allOk ? 0 : 1);
		#end
	}
}
