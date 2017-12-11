package darkside;

import haxe.Timer;
import js.Error;
import js.html.ArrayBuffer;
import js.html.Uint8Array;
import js.node.Buffer;
import js.npm.SerialPort;
import js.npm.SerialPort;
import om.color.space.RGB;

class Controller {

    public var port(default,null) : String;
    public var baudRate(default,null) : BaudRate;
    public var connected(default,null) : Bool;
    public var isSending(default,null) : Bool;

    public var color(get,null) : RGB;
    inline function get_color() : RGB
        return lastSentColor;
        //return (sendBuffer.length > 0) ? sendBuffer.last() : lastSentColor;

    var serial : SerialPort;
    var lastSentColor : RGB;
    //var sendBuffer : Array<RGB>;
    //var maxSendBufferSize : Int; //TODO
    //var colorToSet : RGB;

    public function new( port : String, baudRate : BaudRate ) {
        this.port = port;
        this.baudRate = baudRate;
        connected = false;
        isSending = false;
    }

	public function connect( callback : Error->Void, firstByteDelay = 1000 ) {
        serial = new SerialPort( port, { baudRate: baudRate, autoOpen: true } );
		serial.on( 'error', callback );
        serial.on( 'disconnect', function(e) trace(e) );
        serial.on( 'data', function(buf) {
            /*
            trace( buf.toString() );
            var c = Std.parseInt( buf.toString() );
            trace(c,colorToSet);
            if( c == colorToSet ) {
                isSending = false;
                if( sendBuffer.length > 0 ) {
                    var c = sendBuffer.shift();
                    setColorRGB( c[0], c[1], c[2] );
                }
            }
            */
        });
        serial.on( 'open', function() {
            connected = true;
            //sendBuffer = [];
            if( firstByteDelay == null || firstByteDelay == 0 )
                callback( null );
            else {
                Timer.delay( function() callback( null ), firstByteDelay );
            }
        });
	}

	public function disconnect( ?callback : ?Error->Void ) {
		if( connected ) {
            connected = false;
            //sendBuffer = [];
			serial.close( callback );
		} else {
            callback();
        }
	}

    public function setColor( color : RGB, ?callback : ?Error->Void ) {
        var buf = new ArrayBuffer( 3 );
        var view = new Uint8Array( buf );
        view.set( color );
        serial.write( new Buffer( buf ), function(e){
            if( e != null ) {
                if( callback != null ) callback( e );
            } else {
                serial.flush( function(e){
                    if( e != null ) {
                        if( callback != null ) callback( e );
                    } else {
                        //serial.drain(function(e){
                        isSending = false;
                        lastSentColor = color;
                        /*
                        if( sendBuffer.length > 0 ) {
                            setColor( sendBuffer.shift());
                        }
                        */
                    }
                });
            }
        });
    }

    public static function searchDevices( ?allowedDevices : Array<String>, callback : Error->Array<SerialPortInfo>->Void ) {
        SerialPort.list( function(e,infos) {
            if( e != null ) {
                callback( e, null );
            } else {
                var devices = new Array<SerialPortInfo>();
                for( dev in infos ) {
                    if( allowedDevices != null ) {
                        var allowed = false;
                        for( allowedDevice in allowedDevices ) {
                            if( dev.serialNumber == allowedDevice ) {
                                allowed = true;
                                break;
                            }
                        }
                        if( allowed ) devices.push( dev );
                    }
                }
                callback( null, devices );
            }
        });
    }

}
