package format;

import format.Document;

using StringTools;

typedef Input = {
	fname:String,
	bpath:String,
	buf:String,
	pos:Int,
	lino:Int
}

class Parser {
	var input:Input;

	function makePos():Pos
		return { fileName : input.fname, lineNumber : input.lino };

	function makeExpr<Def>(expr:Def, ?pos:Pos)
		return { expr : expr, pos : pos != null ? pos : makePos() };

	function peek(?offset=0)
	{
		var i = input.pos + offset;
		return i < input.buf.length ? input.buf.charAt(i) : null;
	}

	function parseHorizontal():Expr<HDef>
	{
		var pos = makePos();
		var buf = new StringBuf();
		while (true) {
			switch peek() {
			case null:
				return null;
			case " ", "\t":
				input.pos++;
				if (peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
			case "\n":
				input.pos++;
				input.lino++;
				if (StringTools.trim(buf.toString()) == "")
					return null;
				if (peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
				break;
			case c:
				input.pos++;
				buf.add(c);
			}
		}
		return makeExpr(HText(buf.toString()), pos);
	}

	function parseVertical():Expr<VDef>
	{
		var list = [];
		while (true) {
			switch peek() {
			case null:
				break;
			case "\n":
				input.pos++;
				input.lino++;
			case _:
				var par = [];
				while (true) {
					var h = parseHorizontal();
					if (h == null)
						break;
					par.push(h);
				}
				if (par.length == 0)
					continue;
				var text = switch par.length {
				case 1: par[0];
				case _: makeExpr(HList(par), par[0].pos);
				}
				list.push(makeExpr(VPar(text), text.pos));
			}
		}
		return switch list.length {
		case 0: null;
		case 1: list[0];
		case _: makeExpr(VList(list), list[0].pos);
		}
	}

	function parseDocument():Document
		return parseVertical();

	public function parseStream(stream:haxe.io.Input, ?basePath=".")
	{
		var _input = input;

		input = {
			fname : "stdin",
			bpath : basePath,
			buf : stream.readAll().toString(),
			pos : 0,
			lino : 1
		};
		trace("reading from the standard input");
		var ast = parseDocument();

		input = _input;
		return ast;
	}

	public function parseFile(path:String)
	{
		var _input = input;

		input = {
			fname : path,
			bpath : path,
			buf : sys.io.File.getContent(path),
			pos : 0,
			lino : 1
		};
		trace('Reading from $path');
		var ast = parseDocument();

		input = _input;
		return ast;
	}

	public function new() {}
}

