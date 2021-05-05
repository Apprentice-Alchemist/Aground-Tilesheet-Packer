import haxe.ds.Either;
import haxe.io.Bytes;

class Sheet {
	public var id:String;
	public var sheet:String;
	public var frames:Array<Frame>;
	public var width:Int = 0;
	public var height:Int = 0;
	public var offsetX:Int = 0;
	public var offsetY:Int = 0;

	public function new(id:String, ?sheet:String) {
		this.id = id;
		this.sheet = sheet.or(id);
		this.frames = [];
	}

	public static function fromXml(x:Xml) {
		var ret = new Sheet(cast x.get("id"), x.get("sheet"));
		ret.width = Std.parseInt(x.get("width")).or(0);
		ret.height = Std.parseInt(x.get("height")).or(0);
		ret.offsetX = x.get("offsetX").parseInt().or(0);
		ret.offsetY = x.get("offsetY").parseInt().or(0);
		var frames = [];
		for (f in x.elementsNamed("image")) {
			if(f.exists("equals")) {
				frames[f.get("frame").parseInt()] = Right(f.get("equals").parseInt());
				continue;
			}
			var frame:Frame = {
				id: f.get("frame").parseInt(),
				x: f.get("x").parseInt(),
				y: f.get("y").parseInt(),
				width: f.get("width").parseInt(),
				height: f.get("height").parseInt(),
				offsetX: f.get("offsetX").parseInt(),
				offsetY: f.get("offsetY").parseInt()
			};
			frames[f.get("frame").parseInt()] = Left(frame);
		}
		ret.frames = frames.map(f -> switch f {
			case Left(v): v;
			case Right(v): switch frames[v] {
				case Left(v): v;
				case _: throw "assert";
			};
		});
		return ret;
	}
}

@:structInit
class Frame {
	public var id:Int;
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
}

@:forward
abstract Tile({
	var image:Image;
	var bounds:Rectangle;
}) {
	public function new(image:Image,bounds:Rectangle){
		this = {
			image: image,
			bounds: bounds
		}
	}

	@:op(A == B) static function comp(a:Tile, b:Tile) {
		if (a.image == b.image && a.bounds == b.bounds)
			return true;
		if (a.bounds.width == b.bounds.width) {
			for (x in 0...a.bounds.width) {
				for (y in 0...a.bounds.height) {
					if (a.image.get(a.bounds.x + x, a.bounds.y + y) != b.image.get(b.bounds.x + x, b.bounds.y + y)) {
						return false;
					}
				}
			}
			return true;
		}
		return false;
	}
}

@:forward(x,y,width,height)
abstract Rectangle({
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
}) {
	public inline function new(x:Int, y:Int, width:Int, height:Int) {
		this = {
			x: x,
			y: y,
			width: width,
			height: height
		};
	}

	@:op(A == B) private static function equals(a:Rectangle, b:Rectangle):Bool {
		return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
	}

	public overload extern inline function contains(other:Rectangle) {
		return contains(other.x, other.y)
			&& contains(other.x, other.y + other.height)
			&& contains(other.x + other.width, other.y)
			&& contains(other.x + other.width, other.y + other.width);
	}

	public overload extern inline function contains(p:Point) {
		return p.x >= this.x && p.y >= this.y && p.x <= (this.x + this.width) && p.y <= (this.y + this.width);
	}

	public overload extern inline function contains(x:Int, y:Int) {
		return contains(new Point(x, y));
	}

	public function toString():String
		return '[Rectangle]{${this.x} ${this.y} ${this.width} ${this.height}}';
}

@:forward(x,y) abstract Point({
	var x:Int;
	var y:Int;
}) {
	public inline function new(x, y)
		this = {x: x, y: y};

	@:op(A == B) private inline static function equals(a:Point, b:Point)
		return a.x == b.x && a.y == b.y;

	@:from private extern static inline function fromArray(a:Array<Int>)
		return new Point(a[0], a[1]);
}

class Image {
	public var data:Bytes;
	public var bounds:Rectangle;

	public function new(w:Int, h:Int, ?d:Bytes) {
		this.data = d.or(haxe.io.Bytes.alloc(w * h * 4));
		this.bounds = new Rectangle(0, 0, w, h);
	}

	public function blit(from:Image, fromBounds:Rectangle, toBounds:Rectangle) {
		var fmis = !from.bounds.contains(fromBounds);
		var tmis = !this.bounds.contains(toBounds);
		if (fmis || tmis) {
			if (fmis)
				Sys.print("from ");
			if (tmis)
				Sys.print("to ");
			Sys.println("bounds mismatch");
			Sys.println("from.bounds : " + from.bounds.toString());
			Sys.println("fromBounds : " + fromBounds.toString());
			Sys.println("this.bounds : " + this.bounds.toString());
			Sys.println("toBounds : " + toBounds.toString());
			Sys.exit(0);
		}
		
		for (y in 0...toBounds.height) {
			data.blit(pos(toBounds.x,y),from.data,from.pos(fromBounds.x,y + fromBounds.y),toBounds.width * 4);
		}
	}

	inline function pos(x:Int,y:Int):Int {
		return (x + y * bounds.width) * 4;
	}
	public inline function get(x:Int, y:Int):Int {
		return data.getInt32((x + y * bounds.width) * 4);
	}

	public inline function set(x:Int, y:Int, v:Int) {
		var p = (x + y * bounds.width) * 4;
		data.setInt32(p, v);
		return v;
	}

	public static function fromPng(file:String) {
		if (!sys.FileSystem.exists(file)) {
			error('File "$file" does not exist.');
		}
		var fin = sys.io.File.read(file);
		var pdata = new format.png.Reader(fin).read();
		var header = format.png.Tools.getHeader(pdata);
		return new Image(header.width, header.height, format.png.Tools.extract32(pdata));
	}

	public function writePng(file:String) {
		var fout = sys.io.File.write(file);
		new format.png.Writer(fout).write(format.png.Tools.build32BGRA(bounds.width, bounds.height, data));
		fout.close();
	}
}
