package {
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.system.LoaderContext;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.net.URLRequest;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.external.ExternalInterface;

import com.adobe.images.PNGEncoder;
import Base64;
import flash.utils.ByteArray;

import com.adobe.net.URI;

public class LoadImage extends MovieClip {
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

    public function LoadImage():void {
        if (ExternalInterface.available) {
            ExternalInterface.addCallback("loadImage", loadImage);
            ExternalInterface.call("loadComplete");
        }
    }


}
}
