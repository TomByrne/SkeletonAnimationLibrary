package dragonBones.display
{
	
	/**
	 * Based on Jonathan Hart's Pixelmask extension for starling.
	 * http://wiki.starling-framework.org/extensions/pixelmask
	 * 
	 */
	import flash.display3D.Context3DBlendFactor;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.RenderTexture;
	
	public class StarlingMask extends DisplayObjectContainer
	{
		private static const MASK_MODE_NORMAL:String = "mask";
		private static const MASK_MODE_INVERTED:String = "maskinverted";
		
		private static const MASK_GUTTER:int = 1; // adds padding to avoid cropping issue
		
		private var _mask:DisplayObject;
		private var _renderTexture:RenderTexture;
		private var _maskRenderTexture:RenderTexture;
		
		private var _image:Image;
		private var _maskImage:Image;
		
		private var _superRenderFlag:Boolean = false;
		private var _inverted:Boolean = false;
		private var _scaleFactor:Number;
		private var _isAnimated:Boolean = true;
		private var _maskRendered:Boolean = false;
		private var _invalid:Boolean = true;
		
		public function StarlingMask(scaleFactor:Number=-1, isAnimated:Boolean=true, autoInvalidate:Number = 1)
		{
			super();			
			
			_isAnimated = isAnimated;
			_scaleFactor = scaleFactor;
			
			BlendMode.register(MASK_MODE_NORMAL, Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA);
			BlendMode.register(MASK_MODE_INVERTED, Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			
			// Handle lost context. By using the conventional event, we can make a weak listener.  
			// This avoids memory leaks when people forget to call "dispose" on the object.
			Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
				onContextCreated, false, 0, true);
				
			addEventListener(Event.CHANGE, onInvalidateEvent);
			addEventListener(Event.ADDED, onInvalidateEvent);
			addEventListener(Event.REMOVED, onInvalidateEvent);
			
			if (!isNaN(autoInvalidate) && autoInvalidate>0) {
				var invalidateTimer:Timer = new Timer(autoInvalidate * 1000);
				invalidateTimer.addEventListener(TimerEvent.TIMER, onInvalidateEvent);
				invalidateTimer.start();
			}
		}
		
		private function onInvalidateEvent(e:*):void 
		{
			_invalid = true;
		}
		
		public function get isAnimated():Boolean
		{
			return _isAnimated;
		}

		public function set isAnimated(value:Boolean):void
		{
			_isAnimated = value;
		}

		override public function dispose():void
		{
			clearRenderTextures();
			Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			super.dispose();
		}
		
		private function onContextCreated(event:Object):void
		{
			refreshRenderTextures();
		}

		public function get inverted():Boolean
		{
			return _inverted;
		}

		public function set inverted(value:Boolean):void
		{
			_inverted = value;
			refreshRenderTextures(null);
		}

		public function set mask(mask:DisplayObject) : void
		{
			
			// clean up existing mask if there is one
			if (_mask) {
				_mask = null;
			}
			
			if (mask) {
				_mask = mask;				
				
				if (_mask.width==0 || _mask.height==0) {
					throw new Error ("Mask must have dimensions. Current dimensions are " + _mask.width + "x" + _mask.height + ".");
				}
				
				refreshRenderTextures(null);
			} else {
				clearRenderTextures();
			}
		}
		
		private function clearRenderTextures() : void
		{
			// clean up old render textures and images
			if (_maskRenderTexture) {
				_maskRenderTexture.dispose();
			}
			
			if (_renderTexture) {
				_renderTexture.dispose();
			}
			
			if (_image) {
				_image.dispose();
			}
			
			if (_maskImage) {
				_maskImage.dispose();
			}
		}
		
		private function refreshRenderTextures(e:Event=null) : void
		{
			if (_mask) {
				clearRenderTextures();
				
				var width:int = Math.ceil(_mask.width * _mask.transformationMatrix.a);
				var height:int = Math.ceil(_mask.height * _mask.transformationMatrix.d);
				
				_maskRenderTexture = new RenderTexture(width+MASK_GUTTER, height+MASK_GUTTER, false, _scaleFactor); // adding 1 fixes an edge issue
				_renderTexture = new RenderTexture(width, height, false, _scaleFactor);
				
				// create image with the new render texture
				_image = new Image(_renderTexture);
				
				// create image to blit the mask onto
				_maskImage = new Image(_maskRenderTexture);
			
				// set the blending mode to MASK (ZERO, SRC_ALPHA)
				if (_inverted) {
					_maskImage.blendMode = MASK_MODE_INVERTED;
				} else {
					_maskImage.blendMode = MASK_MODE_NORMAL;
				}
			}
			_maskRendered = false;
		}
		
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (_superRenderFlag || !_mask) {
				super.render(support, parentAlpha);
			} else {
				if (!_maskRendered || (_isAnimated && _invalid)) {
					_invalid = false;
					
					var width:int = Math.ceil(_mask.width * _mask.transformationMatrix.a);
					var height:int = Math.ceil(_mask.height * _mask.transformationMatrix.d);
					
					if (_maskRenderTexture.width != width+MASK_GUTTER || _maskRenderTexture.height != height+MASK_GUTTER) {
						refreshRenderTextures();
					}
					
					var matrix:Matrix = _mask.transformationMatrix.clone();
					matrix.tx = 0;
					matrix.ty = 0;
					_maskRenderTexture.draw(_mask, matrix);
					_renderTexture.drawBundled(drawRenderTextures);				
					_image.render(support, parentAlpha);
					_maskRendered = true;
					
				} else {
					_image.render(support, parentAlpha);
				}
			}
		}
		
		public function invalidate():void 
		{
			_invalid = true;
		}
		
		private function drawRenderTextures() : void
		{
			// undo scaling and positioning temporarily because its already applied in this execution stack
			
			var matrix:Matrix = this.transformationMatrix.clone();
			
			this.transformationMatrix = new Matrix();
			this.transformationMatrix.tx = -_mask.transformationMatrix.tx;
			this.transformationMatrix.ty = -_mask.transformationMatrix.ty;
			_superRenderFlag = true;
			_renderTexture.draw(this, this.transformationMatrix);
			_superRenderFlag = false;
			
			this.transformationMatrix = matrix;
			_renderTexture.draw(_maskImage);
			this.transformationMatrix.tx = _mask.transformationMatrix.tx;
			this.transformationMatrix.ty = _mask.transformationMatrix.ty;
		}
	}
}