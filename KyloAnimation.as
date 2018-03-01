package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;
	
	
	public class KyloAnimation extends MovieClip {
		
		
		public function KyloAnimation() {
			deepFreeze();
			addEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		function deepFreeze():void {
			stop();
			for(var i=0; i<numChildren; i++) {
				if(!(getChildAt(i) is Thingy)) {
					(getChildAt(i) as MovieClip).stop();
				}				
			}
		}
		
		function deepMove():void {
			var changeLabel:Boolean = false;
			for(var i=0; i<numChildren; i++) {
				if(!(getChildAt(i) is Thingy)) {
					var mc:MovieClip = getChildAt(i) as MovieClip;
					if(mc) {
						if(mc.currentFrame===mc.totalFrames) {
							changeLabel = true;
						} else {
							mc.gotoAndStop(mc.currentFrame+1);							
						}
					} else {
						changeLabel = true;
					}
				}
			}			
			if(changeLabel) {
				for(i=0; i<this.currentLabels.length; i++) {
					var label:FrameLabel = this.currentLabels[i];
					if(label.name === this.currentLabel) {
						if(i<this.currentLabels.length-1) {
							gotoAndStop(this.currentLabels[i+1].name);
						} else {
							gotoAndStop(totalFrames);
						}
						break;
					}
				}
			}
		}
		
		function onFrame(e:Event):void {
			deepMove();
		}
		
		public function doneTransition():void {
			
		}
	}
	
}
