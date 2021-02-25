import haxe.xml.Access;
import haxe.io.Bytes;

// @:nullSafety
class Sheet {
	public var id:String;
	public var sheet:String;
	public var frames:Array<Frame>;
	public var width:Int;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	
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
		for (f in x.elementsNamed("image")) {
			var frame = new Frame();
			frame.id = f.get("frame").parseInt().or(0);
			frame.x = f.get("x").parseInt().or(0);
			frame.y = f.get("y").parseInt().or(0);
			frame.width = f.get("width").parseInt().or(0);
			frame.height = f.get("height").parseInt().or(0);
			frame.offsetX = f.get("offsetX").parseInt().or(0);
			frame.offsetY = f.get("offsetY").parseInt().or(0);
			ret.frames.push(frame);
		}
		return ret;
	}
}

class Frame {
	public var id:Int;
	public var x:Int;
	public var y:Int;
	public var width:Null<Int>;
	public var height:Null<Int>;
	public var offsetX:Null<Int>;
	public var offsetY:Null<Int>;
	public var equ:Null<Int>;

	public function new() {}

	public function p() {
		Sys.print('x : $x ');
		Sys.print('y : $y ');
		Sys.print('width : $width ');
		Sys.print('height : $height ');
		Sys.print('offsetX : $offsetX ');
		Sys.print('offsetY : $offsetY ');
		Sys.println("");
	}
}

@:forward
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

	public function add(r:Rectangle) {
		inline function reshape(x,y,w,h) {
			this.x = x;
			this.y = y;
			this.width = w;
			this.height = h;
		}
		var tx2 = this.width;
        var ty2 = this.height;
        if ((tx2 | ty2) < 0) {
            reshape(r.x, r.y, r.width, r.height);
        }
        var rx2 = r.width;
        var ry2 = r.height;
        if ((rx2 | ry2) < 0) {
            return;
        }
        var tx1 = this.x;
        var ty1 = this.y;
        tx2 += tx1;
        ty2 += ty1;
        var rx1 = r.x;
        var ry1 = r.y;
        rx2 += rx1;
        ry2 += ry1;
        if (tx1 > rx1) tx1 = rx1;
        if (ty1 > ry1) ty1 = ry1;
        if (tx2 < rx2) tx2 = rx2;
        if (ty2 < ry2) ty2 = ry2;
        tx2 -= tx1;
        ty2 -= ty1;
        // tx2,ty2 will never underflow since both original
        // rectangles were non-empty
        // they might overflow, though...
        // if (tx2 > Integer.MAX_VALUE) tx2 = Integer.MAX_VALUE;
        // if (ty2 > Integer.MAX_VALUE) ty2 = Integer.MAX_VALUE;
        reshape(tx1, ty1, tx2, ty2);
	}

	public function toString():String
		return '[Rectangle]{${this.x} ${this.y} ${this.width} ${this.height}}';
}

@:forward abstract Point({
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
		// var fmis = !from.bounds.contains(fromBounds);
		// var tmis = !this.bounds.contains(toBounds);
		// if (fmis || tmis){
		// 	if(fmis) Sys.print("from ");
		// 	if(tmis) Sys.print("to ");
		// 	Sys.println("bounds mismatch");
		// 	Sys.println("from.bounds : " + from.bounds.toString());
		// 	Sys.println("fromBounds : " + fromBounds.toString());
		// 	Sys.println("this.bounds : " + this.bounds.toString());
		// 	Sys.println("toBounds : " + toBounds.toString());
		// 	Sys.exit(0);
		// }
		// for(y in 0...toBounds.height){
		// 	this.data.blit()
		// }
		for (x in 0...toBounds.width) {
			for (y in 0...toBounds.height) {
				this.set(toBounds.x + x, toBounds.y + y, from.get(fromBounds.x + x, fromBounds.y + y));
			}
		}
	}

	public function get(x:Int, y:Int):Int {
		return data.getInt32((x + y * bounds.width) * 4);
	}

	public function set(x:Int, y:Int, v:Int) {
		var p = (x + y * bounds.width) * 4;
		try data.setInt32(p, v) catch(_){};
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
		new format.png.Writer(fout).write(format.png.Tools.build32BGRA(bounds.width,bounds.height,data));
		fout.close();
	}
}
