package vk.wall_post
{
	//import cmodule.lua_wrapper.CLibInit;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.LoaderContext;
	import flash.text.*;
	import flash.utils.ByteArray;
	
	//import luaAlchemy.LuaAlchemy;
	
	import vk.api.DataProvider;
	import vk.api.serialization.json.JSON;
	import vk.ui.*;
	
	/**
	 * ...
	 * @author Andrew Rogozov
	 */
	public class Main extends Sprite {
		
		//private var myLuaAlchemy:LuaAlchemy;
		
		
		public static var FILE_FILTER: Array = ["Images (*.jpg, *.jpeg, *.png)", "*.jpg;*.JPG;*.jpeg;*.JPEG;*.png;*.PNG"];
		
		private var btnBrowse: VKButton;
		private var btnInstall: VKButton;
		private var uploadButtons: Sprite;
		private var file: FileReference;
		private var imagePreview: Sprite;
		private var resizedImage: Bitmap;
		private var dp: DataProvider;
		private var uploadUrl: String;
		private var wall_id: int;
		
		private var loader: Sprite;
		
		private var wrapper: Object;
		private var app: Object;
		private var params: Object;
		
		public function Main():void {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			wrapper = Object(parent.parent);
			
			if (!wrapper.application) {
				app = stage;
				wall_id = 6492;
				params = stage.loaderInfo.parameters;
				wrapper = stage;
			} else {
				app = wrapper.application;
				params = app.parameters;
				wall_id = params.user_id;
			}
			
			this.graphics.beginFill(0xFFFFFF, 1);
			this.graphics.drawRect(0, 0, app.stageWidth, app.stageHeight);
			this.graphics.endFill();
			
			
			if (params.referrer == 'wall_view_inline' || params.referrer == 'wall_view') {
				var imageLoader: Loader = new Loader();
				imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e: Event): void {
					addChild(imageLoader);
					imageLoader.x = Math.round((app.stageWidth - imageLoader.width) / 2);
					imageLoader.y = 50;
				});
			//	myLuaAlchemy = new LuaAlchemy();
				//myLuaAlchemy.setGlobal("Application", parentApplication);
				//myLuaAlchemy.setGlobal("this",this);
			/*	var code:String = ( <![CDATA[
					
					function movebox()
					this.graphics.beginFill( randomBoxLocation(),1)
					this.graphics.drawRect(0,0,607,412)
					this.graphics.endFill()
					end
					
					-- returns a random (x,y) location for the box within the canvas
					function randomBoxLocation()
					return math.random(0, 16000000)
					end
					
					
					-- start moving the box at the beginning
					movebox()
					
					-- Create and start the timer to move the box every 5 seconds
					local timer = as3.class.flash.utils.Timer.new(1000)
					timer.addEventListener(as3.class.flash.events.TimerEvent.TIMER, movebox)
					timer.start()

				 ]]>).toString();
				
				var stack:Array = myLuaAlchemy.doString(code);
				*/
				//imageLoader.load(new URLRequest("http://vk.com/images/gifts/256/173.jpg"));
				return;
			}
			
			
			if (!(params.api_settings & 512)) {
				btnInstall = new VKButton("Install App");
				btnInstall.addEventListener(MouseEvent.CLICK, onInstallClick);
				wrapper.addEventListener("onApplicationAdded", onAppAdded);
				wrapper.addEventListener("onSettingsChanged", onSettingsChanged);
				btnInstall.y = 50;
				btnInstall.x = Math.round((app.stageWidth - btnInstall.width) / 2);
				addChild(btnInstall);
			} else {
				initForm();
			}
		}
		
		private function onInstallClick(e: Event): void {
			wrapper.external.showInstallBox();
		}
		private function onAppAdded(e: Object): void {
			wrapper.external.showSettingsBox(512);
		}
		private function onSettingsChanged(e: Object): void {
			params.api_settings = parseInt(e.settings);
			if (params.api_settings & 512) {
				removeChild(btnInstall);
				initForm();
			}
		}
		
		private function initForm(): void {
			if (String(params.referrer).substr(0, 4) != 'wall') {
				var tf: TextField = new TextField();
				tf.width = 300;
				tf.height = 200;
				tf.x = Math.round((app.stageWidth - tf.width) / 2);
				tf.y = 50;
				tf.embedFonts = false;
				
				var format:TextFormat = new TextFormat();
				format.font = "Tahoma";
				format.color = 0x000000;
				format.size = 13;
				
				tf.autoSize = TextFieldAutoSize.CENTER;
				tf.defaultTextFormat = format;
				addChild(tf);
				tf.appendText("Now you can run this application from the wall posting menu.\n");
				return;
			}
			btnBrowse = new VKButton("Browse image");
			btnBrowse.y = 50;
			btnBrowse.x = Math.round((app.stageWidth - btnBrowse.width) / 2);
			addChild(btnBrowse);
			btnBrowse.addEventListener(MouseEvent.CLICK, onBrowseClick);
			
			
			var btnUpload: VKButton = new VKButton("Upload image");
			btnUpload.addEventListener(MouseEvent.CLICK, onUploadClick);
			var btnCancel: VKButton = new VKButton("Cancel", 2);
			btnCancel.x = btnUpload.x + btnUpload.width + 10;
			btnCancel.addEventListener(MouseEvent.CLICK, onCancelClick);
			
			uploadButtons = new Sprite();
			uploadButtons.addChild(btnUpload);
			uploadButtons.addChild(btnCancel);
			uploadButtons.x = Math.round((app.stageWidth - uploadButtons.width) / 2);
			uploadButtons.y = btnBrowse.y;
			uploadButtons.visible = false;
			addChild(uploadButtons);
			
			file = new FileReference();
			file.addEventListener(Event.SELECT, onFileSelected);
			
			loader = new Sprite();
			loader.graphics.beginFill( 0xF7F7F7, 0.3 );
			loader.graphics.drawRect( 0, 0, app.stageWidth, app.stageHeight );
			loader.graphics.endFill();
			//var loaderBar: LoaderBar = new LoaderBar();
			//loaderBar.x = Math.round((app.stageWidth - loaderBar.width) / 2);
			//loaderBar.y = uploadButtons.y - 25;
			//loader.addChild(loaderBar);
			
			dp = new DataProvider(params.api_url, 563059, 'secretkeyforhackday', params.viewer_id, true);
			dp.setup( { onError: function(error: String): void {
				debug("Error: " + error);   
			}});
				dp.request("wall.getPhotoUploadServer", { onComplete: function(response: Object): void {
					if (response.upload_url) {
						uploadUrl = response.upload_url;
					}
				}});
			}
					
					private function onBrowseClick(e: MouseEvent): void {
						file.browse([new FileFilter(FILE_FILTER[0], FILE_FILTER[1])]);
					}
					private function onFileSelected(e:Event): void {
						if (file.size == 0) {
							debug("File size is zero bytes");
							return;
						}
						file.addEventListener(Event.COMPLETE, onFileLoaded);
						file.load();
					}
					private function onFileLoaded(e: Event): void {
						file.removeEventListener(Event.COMPLETE, onFileLoaded);
						// Resample image
						var data: ByteArray = ByteArray(e.target.data);
						var imgLoader:Loader = new Loader();
						imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
						imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
						imgLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onImageLoadError);
						imgLoader.loadBytes(data, new LoaderContext(false));
					}
					
					public function onImageLoaded(e: Event): void {
						var source: Bitmap = Bitmap(e.target.content); 
						resizedImage = ImageHelper.resize(source, 200, 300);
						source.bitmapData.dispose();
						
						btnBrowse.visible = false;
						uploadButtons.visible = true;
						
						if (imagePreview && contains(imagePreview)) {
							removeChild(imagePreview);
							imagePreview = null;
						}
						
						imagePreview = new Sprite();
						imagePreview.addChild(resizedImage);
						imagePreview.x = Math.round((stage.stageWidth - imagePreview.width) / 2 );
						imagePreview.y = uploadButtons.y + uploadButtons.height + 20;
						addChild(imagePreview);
						
					}
					
					private function onUploadClick(e:MouseEvent): void {
						var urlRequest: URLRequest = new URLRequest();
						if (uploadUrl == "") {
							debug("Upload URL is empty");
							return;
						} else {
							debug(uploadUrl);
						}
						urlRequest.url = uploadUrl;
						urlRequest.method = URLRequestMethod.POST;
						urlRequest.requestHeaders.push(new URLRequestHeader('Cache-Control', 'no-cache'));
						
						// Configure listeners
						file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadComplete);
						file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
						file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
						try {
							file.upload(urlRequest, 'photo');
							showLoader();
						} catch (error:Error) {
							debug("Upload error");
							return;
						}
					}
					private function onCancelClick(e:MouseEvent): void {
						showBrowse();
					}
					
					
					private function onUploadComplete(e: DataEvent): void {
						debug("Upload complete");
						debug('Data: ' + e.data);
						showLoader(false);
						var data: Object = JSON.decode(e.data);
						if (data.photo) {
							data.message = 'бла бла бла';
							data.wall_id = wall_id;
							data.post_id = 'post1';
							dp.request('wall.savePost', { params: data, onComplete: function(response: Object): void {
								debug(response.post_hash);
								debug(response.photo_src);
								wrapper.external.saveWallPost(response.post_hash);
							}} );	
							}
								}
						
						private function showBrowse(): void {
							btnBrowse.visible = true;
							uploadButtons.visible = false;
							if (imagePreview && contains(imagePreview)) {
								removeChild(imagePreview);
							}
							imagePreview = null;
						}
						
						private function showLoader(show: Boolean = true): void {
							if (contains(loader) && !show) {
								removeChild(loader);
							} else if (!contains(loader) && show) {
								addChild(loader);
							}
						}
						
						private function onImageLoadError(e: Event): void {
							debug("Image loading error");
							showLoader(false);
						}
						private function onSecurityError(e: SecurityErrorEvent): void {
							debug("Security error");
							showLoader(false);
						}
						private function onIOError(e: IOErrorEvent): void {
							debug("IO error");
							showLoader(false);
						}
						private function debug(msg: *): void {
							trace(debug);
							if (wrapper.external)
								wrapper.external.debug(msg);
						}
					}
					}