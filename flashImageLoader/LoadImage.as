package {
import com.adobe.images.PNGEncoder;

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.system.LoaderContext;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.net.*;
import flash.events.*;
import flash.external.ExternalInterface;

import com.adobe.images.PNGEncoder;

import Base64;
import UploadPostHelper;
import flash.utils.ByteArray;

import com.adobe.net.URI;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;

import vk.ui.VKButton;
[SWF(width="200", height="100", backgroundColor="#FFFFFF", frameRate="30")]

public class LoadImage extends Sprite {
    public function loadImage(url:String):void {
        var l:Loader = new Loader();
        var r:URLRequest = new URLRequest(url);
        var context:LoaderContext = new LoaderContext(true);

        l.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
        l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        l.load(r, context);

        function onLoadError(e:IOErrorEvent):void {
            ExternalInterface.call("console.log", "Couldn't load image!");

            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        }

        function onLoadComplete(e:Event):void {
            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
            try {
                var bitmapData:BitmapData = e.target.content.bitmapData;
            }
            catch (myError:Error) {

                ExternalInterface.call("console.log", "error" + myError);
            }

            // Encode
            var ba:ByteArray = PNGEncoder.encode(bitmapData);
            var encoded:String = Base64.encodeByteArray(ba);
            ExternalInterface.call("setImage", String(encoded));
        }
    }


    public function postImage(postUrl:String, imageData:String):void {
        ExternalInterface.call("console.log", "postImage");
        var ba:ByteArray = Base64.decodeToByteArray(imageData);
        var pd:ByteArray = UploadPostHelper.getPostData('file1', ba);

        ExternalInterface.call("console.log", "postImage2");
        var l:URLLoader = new URLLoader();

        var r:URLRequest = new URLRequest();
        r.url = postUrl;
        r.contentType = 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary();
        r.method = URLRequestMethod.POST;
        r.data = UploadPostHelper.getPostData('file1', pd);
        r.requestHeaders.push(new URLRequestHeader('Cache-Control', 'no-cache'));
        ExternalInterface.call("console.log", "postImage3");
        l.dataFormat = URLLoaderDataFormat.BINARY;

        //var context:LoaderContext = new LoaderContext(true);

        l.addEventListener(Event.COMPLETE, onLoadComplete);
        l.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);

        ExternalInterface.call("console.log", "postImage4");
        try {
            l.load(r);
        } catch (e:Error) {
            ExternalInterface.call("console.log", "error" + e);
        }
        ExternalInterface.call("console.log", "postImage5");
        function onLoadError(e:IOErrorEvent):void {
            ExternalInterface.call("console.log", "Couldn't upload image!");

            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        }

        function onLoadComplete(e:Event):void {
            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

            ExternalInterface.call("console.log", "Image uploaded!");
        }
    }


    public function DataUpload(postUrl:String, imageData:String):void {
        ExternalInterface.call("console.log", "postImage1");
        var ba:ByteArray = Base64.decodeToByteArray(imageData);


        var l:URLLoader = new URLLoader();
        l.dataFormat = URLLoaderDataFormat.BINARY;

        l.addEventListener(Event.COMPLETE, onLoadComplete);
        l.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
        ExternalInterface.call("console.log", "postImage2");
        var r:URLRequest = new URLRequest(postUrl);
        r.method = URLRequestMethod.POST;
        r.contentType = "multipart/form-data boundary=" + UploadPostHelper.getBoundary();
        ExternalInterface.call("console.log", "postImage3");
        r.data = UploadPostHelper.getPostData('image.png', ba, "file1");
        r.requestHeaders.push(new URLRequestHeader('Cache-Control', 'no-cache'));

        ExternalInterface.call("console.log", "postImage4");
        try {
            l.load(r);
        } catch (e:Error) {
            ExternalInterface.call("console.log", "error" + e);
        }
        ExternalInterface.call("console.log", "postImage5");
        function onLoadError(e:IOErrorEvent):void {
            ExternalInterface.call("console.log", "Couldn't upload image!");

            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        }

        function onLoadComplete(e:Event):void {
            e.target.removeEventListener(Event.COMPLETE, onLoadComplete);
            e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

            ExternalInterface.call("console.log", "Image uploaded!");
            ExternalInterface.call("saveProfileImage", String(e.target.data));
        }

    }


    public function LoadImage():void {
        if (ExternalInterface.available) {
            ExternalInterface.addCallback("loadImage", loadImage);
            ExternalInterface.addCallback("postImage", postImage);
            ExternalInterface.addCallback("DataUpload", DataUpload);
            ExternalInterface.call("loadComplete");

            var button:SimpleButton = new VKButton("Сохранить изобаржение");
            button.x = 0;
            button.y = 0;
            button.addEventListener(MouseEvent.CLICK, dataUploadClick);
            addChild(button);


            function dataUploadClick(e:Event):void {
                ExternalInterface.call("console.log", "flash click");
                DataUpload(ExternalInterface.call("getUploadURL"), ExternalInterface.call("getImageData"));
                ExternalInterface.call("console.log", "URL: " + ExternalInterface.call("getUploadURL").length);
                ExternalInterface.call("console.log", "URL:" + ExternalInterface.call("getImageData").length);
            }
        }



    }

}
}
