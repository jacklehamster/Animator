package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	
	public class KyloMulti extends MovieClip {
		static public var instance:KyloMulti;
		static public var born:Date = new Date();
		
		
		public function doneSuperTransition():void {
			switch(currentLabel) {
				case "LEARN":
					gotoAndStop("LIGHT");
					break;
			}
		}
	}	
}
