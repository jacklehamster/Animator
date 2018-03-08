package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import by.blooddy.crypto.MD5;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import by.blooddy.crypto.image.PNG24Encoder;
	import flash.display.Stage;
	import flash.display.Shape;

	
	public class Thingy extends MovieClip {
		private var tag:String = null;
		private var bitmap:Bitmap = new Bitmap(new BitmapData(1,1));
		private var tempBitmap:BitmapData = new BitmapData(1,1);
		private var rect:Rectangle;
		private var savedHash:Object = {};
		static private var dir:File;
		private var data:Object;
		private var frame:int = 1;
		private var dim:Object = {};
		private var previousLabel:String = null;
		private var maxWidth:int=0, maxHeight:int=0;
		private var stopped:Boolean = false;
		private var shape:Shape = new Shape();
		private var hotSpot:Point = new Point();
		
		static private var globalFrame:int = 1;
		static private var globalMovie:MovieClip = null;
		static private var globalMcs:Array = [];
		static private var globalId:int = 0;
		private var id:int;
		
		public function Thingy() {
			globalId++;
			id = globalId;
			if(!dir) {
				dir = File.userDirectory.resolvePath("Sites")
					.resolvePath("dobuki.net")
					.resolvePath("dobuki.net")
					.resolvePath("public")
					.resolvePath("webgl")
					.resolvePath("animation3");
//				dir = File.documentsDirectory.resolvePath("animations");				
			}
			addEventListener(Event.ADDED_TO_STAGE, onStage);
			addEventListener(Event.REMOVED_FROM_STAGE, offStage);
			visible = false;
			if(globalMovie) {
				globalMovie = new MovieClip();
				globalMovie.addEventListener(Event.ENTER_FRAME, onGlobalFrame);
			}
			saveGlobal(this);
		}
		
		static private function saveGlobal(mc:MovieClip):void {
			var owner:MovieClip = MovieClip(mc.parent);
			var globalPoint:Point = owner.localToGlobal(new Point());
			
			globalMcs.push({
				type: mc.name,
				name: mc.name + mc.id,
				frame: globalFrame,
				position: [globalPoint.x, globalPoint.y]
			});
			
			var file:File = dir.resolvePath("globalscene.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify({
				elements: globalMcs,
				size: [mc.stage.stageWidth, mc.stage.stageHeight],
				fps: mc.stage.frameRate,
				backgroundColor: "#" + (mc.stage.color & 0xFFFFFF).toString(16)
			},null,'\t'));
			fileStream.close();			

		}
		
		static private function onGlobalFrame(e:Event):void {
			globalFrame++;
		}
		
		private function onStage(e:Event):void {
			var owner:MovieClip = MovieClip(parent);
			hotSpot = owner.localToGlobal(new Point());
			data = {
				frames:[],
				sprites:[],
				frameCount: owner.totalFrames
			}
			
			addEventListener(Event.ENTER_FRAME, onFrame);		
			refresh();
		}
		
//		static private function saveGlobalScene():void {
//			
//		}
		
		private function offStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onStage);
			removeEventListener(Event.REMOVED_FROM_STAGE, offStage);
			removeEventListener(Event.ENTER_FRAME, onFrame);
			if(bitmap.parent) {
				bitmap.stage.removeChild(bitmap);				
			}
		}
		
		private function onFrame(e:Event):void {
			if(stopped) {
				return;
			}
			frame++;
			refresh();
			if(MovieClip(parent).currentFrame===MovieClip(parent).totalFrames) {
				trace("DONE");
				if(bitmap.parent)
					bitmap.parent.removeChild(bitmap);
				if(shape.parent)
					shape.parent.removeChild(shape);
				stopped = true;
			}
		}
		
		private function reduceBitmap(scale:Number):void {
			var found:Boolean = false;
			var topLine:int = 0;
			var x:int, y:int;
			for(y=0;y<bitmap.bitmapData.height && !found;y++) {
				for(x=0;x<bitmap.bitmapData.width;x++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						topLine = y;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var bottomLine:int = bitmap.bitmapData.height-1;
			for(y=bitmap.bitmapData.height-1;y>=0 && !found;y--) {
				for(x=0;x<bitmap.bitmapData.width;x++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						bottomLine = y;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var leftLine:int = 0;
			for(x=0;x<bitmap.bitmapData.width && !found;x++) {
				for(y=0;y<bitmap.bitmapData.height;y++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						leftLine = x;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var rightLine:int = 0;
			for(x=bitmap.bitmapData.width-1; x>=0 && !found;x--) {
				for(y=0;y<bitmap.bitmapData.height;y++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						rightLine = x;
						found = true;
						break;
					}
				}
			}
				
			if(topLine >0 || bottomLine < bitmap.bitmapData.height-1 
					|| leftLine >0 || rightLine < bitmap.bitmapData.width-1) {
				var bitmapData2:BitmapData = new BitmapData(
					rightLine-leftLine+1,
					bottomLine-topLine+1,
					true,
					0
				);
				bitmapData2.copyPixels(bitmap.bitmapData,
					new Rectangle(leftLine,topLine,rightLine-leftLine+1,bottomLine-topLine+1),
					new Point()
				);
				bitmap.bitmapData = bitmapData2;
				
				var owner:MovieClip = MovieClip(parent);
				rect = owner.getRect(owner);
				var shift:Point = rect.topLeft;
				rect.left = leftLine/scale + shift.x;
				rect.top = topLine/scale + shift.y;
				rect.right = rightLine/scale + shift.x;
				rect.bottom = bottomLine/scale + shift.y;
			}
		}
		
		private function findTag(tag:String, data:Object) {
			for(var i=0;i<data.sprites.length;i++) {
				if(tag===data.sprites[i][0]) {
					return i;
				}
			}
			return -1;
		}
		
		private function checkTag() {
			var bytes:ByteArray = bitmap.bitmapData.getPixels(bitmap.bitmapData.rect);
			var md5:String = MD5.hashBytes(bytes); //MD5.hashBytes(bytes);
			
			if(tag !== md5) {
				tag = md5;
				if(!savedHash[tag]) {
					//trace(name, tag);
					saveBytes(tag, bitmap.bitmapData);
					savedHash[tag] = true;
					data.sprites.push([
						tag, 0, 0, bitmap.bitmapData.width, bitmap.bitmapData.height
					]);
				}
			}
			
			var dimdim:Object = {
				frame: frame,
				tag: findTag(md5, data),
				rect: getStageDimension(rect)
			};
			var didChange:Boolean = false;
			if(dimdim.tag !== dim.tag 
				|| JSON.stringify(dimdim.rect) !== JSON.stringify(dim.rect)
				|| MovieClip(parent).currentLabel !== previousLabel
			) {
				if(MovieClip(parent).currentLabel !== previousLabel) {
					dimdim.label = MovieClip(parent).currentLabel;
					previousLabel = dimdim.label;
				}
				
				if(dim.rect) {
					shape.graphics.lineStyle(1,0xFF0000);
					shape.graphics.moveTo(dim.rect[0][0]+hotSpot.x,dim.rect[0][1]+hotSpot.y);
					shape.graphics.lineTo(dim.rect[1][0]+hotSpot.x,dim.rect[1][1]+hotSpot.y);
					shape.graphics.lineTo(dim.rect[2][0]+hotSpot.x,dim.rect[2][1]+hotSpot.y);
					shape.graphics.lineTo(dim.rect[3][0]+hotSpot.x,dim.rect[3][1]+hotSpot.y);
					shape.graphics.lineTo(dim.rect[0][0]+hotSpot.x,dim.rect[0][1]+hotSpot.y);
				}
				stage.addChild(shape);
					
				dim = dimdim;
				addDimension(dimdim);
				
				didChange = true;
			}
			if(frame > data.frameCount) {
				data.frameCount = frame;
				didChange = true;
			}
			if(didChange) {
				save();
			}
			
		}
		
		private function addDimension(newDim:Object):void {
			data.frames.push(newDim);
			save();
		}
		
		private function save():void {
			var file:File = dir.resolvePath("json").resolvePath(name + id + ".json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(data,null,'\t'));
			fileStream.close();			
		}
		
		private function saveBytes(md5:String, bitmapData:BitmapData):void {
			var file:File = dir.resolvePath("assets").resolvePath(md5+".png");
			if(file.exists) {
				return;
			}
			var bytes:ByteArray = PNG24Encoder.encode(bitmapData);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(bytes);
			fileStream.close();
		}
		
		private function getStageDimension(rect:Rectangle):Object {
			var r:Rectangle = rect;
			var owner:MovieClip = MovieClip(parent);
			var topLeft:Point = owner.localToGlobal(r.topLeft).subtract(hotSpot);
			var topRight:Point = owner.localToGlobal(new Point(r.right,r.top)).subtract(hotSpot);
			var bottomLeft:Point = owner.localToGlobal(new Point(r.left,r.bottom)).subtract(hotSpot);
			var bottomRight:Point = owner.localToGlobal(r.bottomRight).subtract(hotSpot);
			return [
				[bottomLeft.x,bottomLeft.y],
				[bottomRight.x,bottomRight.y],
				[topRight.x,topRight.y],
				[topLeft.x,topLeft.y]
			];
		}
		
		private function refresh():void {
			var owner:MovieClip = MovieClip(parent);
			rect = owner.getBounds(owner);
			var stageRect:Rectangle = owner.getBounds(stage);
			var scale:Number = Math.max(
				stageRect.width/rect.width*2,
				stageRect.height/rect.height*2
			);
			if(rect.width * scale != tempBitmap.width || rect.height * scale != tempBitmap.height) {
				tempBitmap = new BitmapData(rect.width * scale,rect.height * scale,true);
			}
			tempBitmap.fillRect(tempBitmap.rect,0);
			bitmap.bitmapData = tempBitmap;
			bitmap.bitmapData.draw(
				owner,
				new Matrix(scale,0,0,scale,-rect.left*scale,-rect.top*scale),
				null,
				null,
				null,
				true);
			reduceBitmap(scale);
			checkTag();
			bitmap.alpha = .5;
			bitmap.scaleX = bitmap.scaleY = .5;
			stage.addChild(bitmap);
		}
	}
	
}
