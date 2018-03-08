package  {
	
	import flash.display.MovieClip;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.display.Loader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import by.blooddy.crypto.MD5;
	import flash.geom.Rectangle;
	import by.blooddy.crypto.image.PNGEncoder;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	
	
	public class Combinator extends MovieClip {
		
		private var dir:File;
		private var tags:Object = {};
		private var pendingFile:Object = {};
		private var loaders:Object = {};
		private var bitmapDatas:Object = {};
		private var spriteMap:Object = {};
		private var subFiles:Object = {};
		private var globalObj:Object = {};
		private var preservedFiles:Object = {};
		
		public function Combinator() {
			dir = File.userDirectory.resolvePath("Sites")
				.resolvePath("dobuki.net")
				.resolvePath("dobuki.net")
				.resolvePath("public")
				.resolvePath("webgl")
				.resolvePath("animation3");
			var globalscene:File = dir.resolvePath("globalscene.json");
			startLoad(globalscene, function(obj:Object):void {
				globalObj = obj;
				obj.elements.forEach(loadElement);
			});
		}
		
		private function startLoad(file:File, callback:Function):void {
			pendingFile[file.nativePath] = file;
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var obj:Object = JSON.parse(file.data.toString());
				callback(obj);
				completeLoad(file.nativePath);
			});
			file.load();
		}
		
		private function completeLoad(path:String):void {
			delete pendingFile[path];
			checkCompletion();
		}
		
		private function checkCompletion():void {
			for(var i in pendingFile) {
				return;
			}
			for(var tag in tags) {
				combineTag(tag, tags[tag]);
			}
		}
		
		private function combineTag(tag:String, sprites:Array):void {
			var assets:File = dir.resolvePath("assets");
			sprites.forEach(function(sprite:Array, index, array):void {
				var imgFile:File = assets.resolvePath(sprite[0] + ".png");
				loadImage(imgFile, function(bitmapData:BitmapData):void {
					bitmapDatas[imgFile.name] = bitmapData;
				});
			});
		}
		
		private function loadImage(file:File, callback:Function):void {
			if(!pendingFile[file.nativePath]) {
				pendingFile[file.nativePath] = file;
				file.addEventListener(Event.COMPLETE, function(e:Event):void {
					var bytes:ByteArray = file.data;
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
						loaders[file.name] = loader;
						var bitmap:Bitmap = loader.content as Bitmap;
						callback(bitmap.bitmapData);
						completeLoadImage(file.nativePath);
					});
					loader.loadBytes(bytes);
				});
				file.load();
			}
		}
		
		private function completeLoadImage(path:String):void {			
			delete pendingFile[path];
			checkImageCompletion();
		}
		
		private function checkImageCompletion():void {
			for(var i in pendingFile) {
				return;
			}

			for(var s in bitmapDatas) {
				trace(s, bitmapDatas[s]);
			}
			
			trace("DONE LOADING IMAGES");

			for(var t in tags) {
				compileSprites(t, tags[t]);
			}

			trace("COMPILED SPRITES");
			
//			trace(JSON.stringify(tags));
			
			for(var f in subFiles) {
//				trace(JSON.stringify(subFiles[f]));
				updateSubfile(f, subFiles[f]);
				saveSubfile(f, subFiles[f]);
			}
			
//			trace(JSON.stringify(subFiles, null, '\t'));
			trace("SAVED NEW SPRITES");
			
			saveGlobalSprites(subFiles);
			
			cleanupFiles();
		}
		
		private function cleanupFiles():void {
//			trace(JSON.stringify(preservedFiles,null,'\t'));
			dir.resolvePath("json").getDirectoryListing().forEach(function(file:File,index,array):void {
				if(!preservedFiles[file.nativePath]) {
					file.deleteFile();
					trace(file.name, "deleted");
				}
			});
			dir.resolvePath("assets").getDirectoryListing().forEach(function(file:File,index,array):void {
				if(!preservedFiles[file.nativePath]) {
					file.deleteFile();
					trace(file.name, "deleted");
				}
			});
		}
		
		private function saveGlobalSprites(subFiles:Object):void {
			globalObj.sprites = subFiles;
			var file:File = dir.resolvePath("compiled-globalscene.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(globalObj,null,'\t'));
			fileStream.close();
		}
		
		private function updateSubfile(name:String, subFile:Object):void {
//			trace(JSON.stringify(subFile));
			subFile.sprites = subFile.sprites.map(function(sprite:Array, index, array):Array {
				return spriteMap[sprite.join(",")];
			});
		}
		
		private function saveSubfile(name:String, subFile:Object):void {
			var file:File = dir.resolvePath("json").resolvePath(name+".json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(subFile,null,'\t'));
			fileStream.close();
			preservedFiles[file.nativePath] = true;
		}
		
		private function getDimension(sprites:Array, width:Number):Array {
			var x:Number = 0;
			var y:Number = 0;
			var maxX:Number = 0;
			var maxY:Number = 0;
			sprites.forEach(function(sprite:Array, index, array) {
				var w:Number = sprite[3];
				var h:Number = sprite[4];
				if(x + w > width) {
					x = 0;
					y = maxY;
				}
				x += w;				
				maxY = Math.max(y + h, maxY); 	
				maxX = Math.max(x + w, maxX);
			});
			return [maxX, maxY];
		}
		
		private function compileSprites(name:String, sprites:Array):void {
			var width:Number = 0;
			var bestDim:Array = null;
			var bestLength:Number = Number.MAX_VALUE;
			sprites.forEach(function(sprite:Array, index, array):void {
				var w:Number = sprite[3];
				width += w;
				var dim:Array = getDimension(sprites, width);
				if(bestLength > Math.max(dim[0],dim[1])) {
					bestLength = Math.max(dim[0],dim[1]);
					bestDim = dim;
				}
			});
			trace(bestDim);
			
			var spriteSheet:BitmapData = new BitmapData(bestDim[0], bestDim[1], true, 0);
			
			fillSpriteSheet(name, spriteSheet, sprites);
			var bmp:Bitmap = new Bitmap(spriteSheet,"auto",true);
			bmp.scaleX = bmp.scaleY = .2;
			MovieClip(root).addChild(bmp);
			
			saveSpritesheet(name, spriteSheet);
		}
		
		private function saveSpritesheet(name:String, sheet:BitmapData):void {
			var assets:File = dir.resolvePath("assets");
			var bytes:ByteArray = PNGEncoder.encode(sheet);
			var file:File = assets.resolvePath(name + ".png");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(bytes);
			fileStream.close();
			preservedFiles[file.nativePath] = true;
		}
		
		
		function fillSpriteSheet(name:String, spriteSheet:BitmapData, sprites:Array):void {
			var x:Number = 0;
			var y:Number = 0;
			var maxY:Number = 0;
			sprites.forEach(function(sprite:Array, index, array) {
				var tag:String = sprite[0];
				var px:Number = sprite[1];
				var py:Number = sprite[2];
				var w:Number = sprite[3];
				var h:Number = sprite[4];
				if(x + w > spriteSheet.width) {
					x = 0;
					y = maxY;
				}
				var bitmap:BitmapData = bitmapDatas[tag + ".png"];
				spriteSheet.copyPixels(
					bitmap, new Rectangle(px,py,w,h), new Point(x,y)
				);
				spriteMap[sprite.join(",")]
					= [name, x, y, w, h];
				x += w;
				maxY = Math.max(y + h, maxY); 	
			});
//			trace(sprites);
//			return newMD5;
		}
		
		
		private function loadElement(element:Object, index:int, array:Array):void {
			var file:File = dir.resolvePath("json").resolvePath(element.name + ".json");
			if(!tags[element.type]) {
				tags[element.type] = [];
			}
			startLoad(file, function(obj:Object):void {
				subFiles[element.name] = obj;	
				obj.sprites.forEach(function(sprite:Array, index:int, array:Array) {
					tags[element.type].push(sprite);
				});
			});
		}
	}
	
}
