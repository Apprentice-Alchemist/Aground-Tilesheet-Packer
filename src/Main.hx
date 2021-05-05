import sys.FileSystem;

function main() {
	var args = Sys.args();
	switch args.shift() {
		case "pack":
			var sheets:Array<{
				var width:Int;
				var height:Int;
				var files:Array<String>;
			}> = [];
			var out:String = "";
			while (true) {
				switch args.shift() {
					case "-i":
						if (args.length < 3)
							error("-i should be followed by width height and a list of tiles");
						var s = {
							width: parseInt(args.shift()),
							height: parseInt(args.shift()),
							files: {
								var files = [];
								while (true) {
									var arg = args[0];
									if (arg != "-i" && arg != "-o" && arg != null) {
										args.shift();
										var f = arg;
										if (FileSystem.exists(f)) {
											if (FileSystem.isDirectory(f)) {
												for (s in FileSystem.readDirectory(f)) {
													if (!FileSystem.isDirectory(s))
														files.push(s);
												}
											} else {
												files.push(f);
											}
										}
									}
								}
								files;
							}
						};
						if (s.width == null || s.height == null)
							error("sheet width and height should be valid integers");
						sheets.push(s);
					case "-o":
						out = args.shift().sure("-o expects an argument");
					case _: break;
				}
			}
			pack(sheets, out);
		case "unpack":
			var file = args.shift();
			var out = null;
			var id = null;
			if (file == null)
				throw "missing file argument";
			while (true) {
				switch args.shift() {
					case "-id": id = args.shift();
					case "-o": out = args.shift();
					case _: break;
				}
			}
			unpack(file, if(out == null) Path.withExtension(Path.withoutDirectory(file),null) else out, id);
		case _:
			Sys.println("Usage : \n\t atp pack -i w h ...files -o out.png\n\tatp unpack file -id id -o out");
	}
}

function pack(sheets:Array<{
	var width:Int;
	var height:Int;
	var files:Array<String>;
}>, out:String) {
	if(out == null || out == "") out = "out.png";
	var xml_sheets = new Array<Sheet>();
	var tiles = new Array<Tile>();

	for (idx => s in sheets) {
		var xs = sheets.length > 0 ? new Sheet(Path.withExtension(out,
			"png")) : new Sheet(Path.withExtension(out, "") + (idx + 1), Path.withExtension(out, "png"));
		xs.offsetX = xs.offsetY = 0;
		xs.width = s.width;
		xs.height = s.height;
		for (file in s.files) {
			var img = Image.fromPng(file);
			for (x in 0...Std.int(img.bounds.width / xs.width)) {
				var tile = new Tile(img,new Rectangle(x * xs.width,0,xs.width,xs.height));

				tiles.push(tile);
			}
		}
	}
}

function unpack(file:String, out:String, ?id:String) {
	var image = Image.fromPng(Path.withExtension(file, "png"));
	function unpackSheet(s:Sheet, outpath:String) {
		if (s == null)
			throw "unpackSheet: sheet is null.";
		var r = new Rectangle(0, 0, s.width, s.height);
		for (f in s.frames) {
			if (f.offsetX + f.width > r.width)
				r.width = f.offsetX + f.width;
			if (f.offsetY + f.height > r.height)
				r.height = f.offsetY + f.height;
		}
		var out = new Image(r.width * s.frames.length, r.height);
		for (i => f in s.frames)
			out.blit(image, new Rectangle(f.x, f.y, f.width, f.height), new Rectangle(i * s.width + f.offsetX, f.offsetY, f.width, f.height));
		out.writePng(outpath);
	}
	if (!sys.FileSystem.exists(file)) {
		error('File "${file}" does not exist.');
	}

	var fcontent = sys.io.File.getContent(file);
	var xml = Xml.parse(fcontent).firstElement();
	var sheets = new Array<Sheet>();
	if (xml.nodeName == "sheets") {
		for (c in xml.elementsNamed("tilesheet")) {
			sheets.push(Sheet.fromXml(c));
		}
	} else {
		assert(xml.nodeName == "tilesheet");
		sheets.push(Sheet.fromXml(xml));
	}
	if (id != null) {
		var sheet = sheets.find(s -> s.id == id);
		if (sheet == null)
			throw "no sheet width id " + id;
	} else {
		for (s in sheets) {
			var path = out == null ? s.id + ".png" : Path.normalize(Path.join([out, s.id + ".png"]));
			unpackSheet(s, path);
		}
	}
}
