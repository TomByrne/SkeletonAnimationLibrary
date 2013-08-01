package dragonBones.display
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0
	* @langversion 3.0
	* @version 2.0
	*/

	
	import dragonBones.objects.BoneTransform;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import starling.display.MovieClip;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Image;
	
	/**
	 * The StarlingDisplayBridge class is an implementation of the IDisplayBridge interface for starling.display.DisplayObject.
	 *
	 */
	public class StarlingDisplayBridge implements IDisplayBridge
	{
		/**
		 * @private
		 */
		protected var _display:DisplayObject;
		
		/**
		 * @private
		 */
		protected var _mask:DisplayObject;
		
		/**
		 * @private
		 */
		protected var _addedDisplay:Object;
		
		/**
		 * @private
		 */
		protected var _maskWrapper:PixelMaskDisplayObject;
		
		/**
		 * @private
		 */
		protected var _container:Object;
		
		/**
		 * @private
		 */
		protected var _addIndex:int;
		
		/**
		 * @inheritDoc
		 */
		public function get display():Object
		{
			return _display;
		}
		/**
		 * @private
		 */
		public function set display(value:Object):void
		{
			if (_display == value)
			{
				return;
			}
			
			//Thanks Jian
			//bug replace image.texture will lost displayList[0].texture
			/*if (_display is Image && value is Image)
			{
				var from:Image = _display as Image;
				var to:Image = value as Image;
				if (from.texture == to.texture)
				{
					return;
				}
				
				from.texture = to.texture;
				//update pivot
				from.pivotX = to.pivotX;
				from.pivotY = to.pivotY;
				from.readjustSize();
				return;
			}*/
			
			/*if (_display)
			{
				var parent:* = _display.parent;
				if (parent)
				{
					var index:int = _display.parent.getChildIndex(_display);
				}
				removeDisplay();
			}*/
			if (_mask && _display) {
				_maskWrapper.removeChild(_display);
			}
			_display = value as DisplayObject;
			/*addDisplay(parent, index);
			if (!_mask) {
				_realDisplay = _display;
			}*/
			if(_display){
				if (_mask) {
					_maskWrapper.addChild(_display);
				}else {
					assessDisplay();
				}
			}
		}
		/**
		 * @inheritDoc
		 */
		public function get mask():Object
		{
			return _mask;
		}
		/**
		 * @private
		 */
		public function set mask(value:Object):void
		{
			if (_mask == value)
			{
				return;
			}
			
			_mask = value as DisplayObject;
			
			if (_mask)
			{
				if (!_maskWrapper)_maskWrapper = new PixelMaskDisplayObject();
				
				if (_mask.parent) {
					_mask.parent.removeChild(_mask);
				}
			}
			if (_maskWrapper) _maskWrapper.mask = _mask;
			
			assessDisplay();
			if (_mask && _display)
			{
				_maskWrapper.addChild(_display);
			}
		}
		
		/**
		 * Creates a new StarlingDisplayBridge instance.
		 */
		public function StarlingDisplayBridge()
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function update(matrix:Matrix, node:BoneTransform, colorTransform:ColorTransform, visible:Boolean):void
		{
			var pivotX:Number = node.pivotX + _display.pivotX;
			var pivotY:Number = node.pivotY + _display.pivotY;
			matrix.tx -= matrix.a * pivotX + matrix.c * pivotY;
			matrix.ty -= matrix.b * pivotX + matrix.d * pivotY;
			
			//if(updateStarlingDisplay)
			//{
			//_display.transformationMatrix = matrix;
			//}
			//else
			//{
			_display.transformationMatrix.copyFrom(matrix);
			//}
			
			if (colorTransform && _display is Quad)
			{
				(_display as Quad).alpha = colorTransform.alphaMultiplier;
				(_display as Quad).color = (uint(colorTransform.redMultiplier * 0xff) << 16) + (uint(colorTransform.greenMultiplier * 0xff) << 8) + uint(colorTransform.blueMultiplier * 0xff);
			}
			//
			_display.visible = visible;
			
			if(_mask)_mask.visible = false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function addDisplay(container:Object, index:int = -1):void
		{
			_container = container;
			_addIndex = index;
			assessDisplay();
		}
		
		private function assessDisplay():void {
			if (_container) {
				var display:Object;
				if (_mask) {
					display = _maskWrapper;
				}else {
					display = _display;
				}
				if (_addedDisplay == display) return;
				
				var index:int = _addIndex;
				if (_addedDisplay) {
					index = _addedDisplay.parent.getChildIndex(_addedDisplay);
					_addedDisplay.parent.removeChild(_addedDisplay);
				}
				if (display) {
					if (index == -1) {
						_container.addChild(display);
					}else{
						_container.addChildAt(display, index);
					}
					_addedDisplay = display;
				}
				
			}else if (_addedDisplay) {
				_addedDisplay.parent.removeChild(_addedDisplay);
				_addedDisplay = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeDisplay():void
		{
			if (_addedDisplay && _addedDisplay.parent)
			{
				_addedDisplay.parent.removeChild(_addedDisplay);
			}
		}
	}
}
