package dragonBones
{
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.display.IDisplayBridge;
	import dragonBones.objects.DisplayData;
	
	use namespace dragonBones_internal;
	
	public class Slot extends DBObject
	{
		/** @private */
		dragonBones_internal var _dislayDataList:Vector.<DisplayData>;
		/** @private */
		dragonBones_internal var _displayBridge:IDisplayBridge;
		/** @private */
		dragonBones_internal var _originZOrder:Number;
		/** @private */
		dragonBones_internal var _tweenZorder:Number;
		/** @private */
		dragonBones_internal var _isDisplayOnStage:Boolean;
		
		private var _offsetZOrder:Number;
		
		public function get zOrder():Number
		{
			return _originZOrder + _tweenZorder + _offsetZOrder;
		}
		
		public function set zOrder(value:Number):void
		{
			if(zOrder != value)
			{
				_offsetZOrder = value - _originZOrder - _tweenZorder;
				this._armature._slotsZOrderChanged = true;
			}
		}
		
		private var _displayIndex:int;
		
		public function get display():Object
		{
			var display:Object = _displayList[_displayIndex];
			if(display is Armature)
			{
				return display.display;
			}
			return display;
		}
		public function set display(value:Object):void
		{
			_displayList[_displayIndex] = value;
			_displayBridge.display = value;
		}
		
		public function get childArmature():Armature
		{
			return _displayList[_displayIndex] as Armature;
		}
		public function set childArmature(value:Armature):void
		{
			_displayList[_displayIndex] = value;
			if(value)
			{
				_displayBridge.display = value.display;
			}
		}
		
		private var _displayList:Array;
		public function get displayList():Array
		{
			return _displayList;
		}
		public function set displayList(value:Array):void
		{
			if(!value)
			{
				throw new ArgumentError();
			}
			var i:int = _displayList.length = value.length;
			while(i --)
			{
				_displayList[i] = value[i];
			}
			
			if(_displayIndex >= 0)
			{
				_displayIndex = -1;
				changeDisplay(_displayIndex);
			}
		}
		
		/** @private */
		dragonBones_internal function changeDisplay(displayIndex:int):void
		{
			if(displayIndex < 0)
			{
				if(_isDisplayOnStage)
				{
					_isDisplayOnStage = false;
					_displayBridge.removeDisplay();
					if(childArmature)
					{
						childArmature.animation.stop();
						childArmature.animation._lastAnimationState = null;
					}
				}
			}
			else
			{
				if(!_isDisplayOnStage)
				{
					_isDisplayOnStage = true;
					if(this._armature)
					{
						_displayBridge.addDisplay(this._armature.display, this._armature._slotList.indexOf(this));
						//this._armature._slotsZOrderChanged = true;
					}
				}
				
				var length:uint = _displayList.length;
				if(displayIndex >= length && length > 0)
				{
					displayIndex = length - 1;
				}
				if(_displayIndex != displayIndex)
				{
					_displayIndex = displayIndex;
					var content:Object = _displayList[_displayIndex];
					if(content is Armature)
					{
						_displayBridge.display = (content as Armature).display;
					}
					else
					{
						_displayBridge.display = content;
					}
					
					if(_dislayDataList && _displayIndex <= _dislayDataList.length)
					{
						this._origin.copy(_dislayDataList[_displayIndex].transform);
					}
				}
				
				if(childArmature)
				{
					childArmature.animation.play();
				}
			}
		}
		
		override public function set visible(value:Boolean):void
		{
			if(value != this._visible)
			{
				_displayBridge.visible = this._visible = value;
			}
		}
		
		override dragonBones_internal function setArmature(value:Armature):void
		{
			super.setArmature(value);
			if(this._armature)
			{
				this._armature._slotsZOrderChanged = true;
				_displayBridge.addDisplay(this._armature.display);
			}
			else
			{
				_displayBridge.removeDisplay();
			}
		}
		
		public function Slot(displayBrideg:IDisplayBridge)
		{
			super();
			_displayBridge = displayBrideg;
			_displayList = [];
			_displayIndex = -1;
			_scaleType = 1;
			
			_originZOrder = 0;
			_tweenZorder = 0;
			_offsetZOrder = 0;
			
			_isDisplayOnStage = false;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			_displayBridge.display = null;
			_displayList.length = 0;
			
			_displayBridge = null;
			_displayList = null;
			_dislayDataList = null;
		}
		
		override dragonBones_internal function update():void
		{
			super.update();
			
			if(_isDisplayOnStage && _displayBridge.display)
			{
				_displayBridge.updateTransform(this._globalTransformMatrix, this._global);
			}
		}
	}
}