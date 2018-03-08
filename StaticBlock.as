package  {
	
	import flash.display.MovieClip;
	import nape.phys.BodyType;
	
	
	public class StaticBlock extends ForceElement {
		
		override protected function getBodyType():BodyType {
			return BodyType.STATIC;
		}
		
	}
	
}
