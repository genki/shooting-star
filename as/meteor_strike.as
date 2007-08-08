class MeteorStrike{
  var host:String;
  var port:Number;
  var interval:Number;
  var heartbeat:Number;
  var channel:String;
  var uid:String;
  var tag:String;
  var sig:String;
  var baseUri:String;

  private var mc:MovieClip;
  private var socket:XMLSocket;
  private var connected:Boolean;
  private var heartbeatId:Number;

  function MeteorStrike(mc:MovieClip){
    var host_port = mc.server.split(':');
    host = host_port[0];
    port = new Number(host_port[1]);
    interval = mc.interval;
    heartbeat = new Number(mc.heartbeat || 0);
    channel = mc.channel;
    uid = mc.uid;
    tag = mc.tag;
    sig = mc.sig;
    baseUri = mc.base_uri
    connected = false;
    heartbeatId = null;
  }

  function establishConnection(){
    var self = this;
    socket = new XMLSocket();
    socket.onConnect = function(success:Boolean){
      self.log(["onConnect: ",  success].join(''));
      if(success){
        self.connected = true;
        self.startCommunication();
        self.setHeartbeat();
      }else self.socket.close();
    };
    socket.onClose = function(){
      self.log(["onClose: "].join(''));
      self.connected = false;
      fscommand("event", "close");
      _global.setTimeout(self, 'makeConnection', 1000);
    };
    socket.onData = function(data:String){
      self.log(["onData: ", data.length, ' byte(s)'].join(''));
      self.setHeartbeat();
      fscommand("execute", data);
    };
    makeConnection();
  }

  function makeConnection(){
    if(connected) return;
    log(["makeConnection: ", host, ':', port].join(''));
    socket.connect(host, port);
    _global.setTimeout(this, 'makeConnection', interval || 3000);
  };

  function startCommunication(){
    var content = [
      "__t__=f",
      "&uid=", escape(uid),
      "&tag=", escape(tag),
      "&sig=", escape(sig),
      "&execute=", baseUri, "/meteor/strike"
    ].join("");
    socket.send([
      ["POST /", escape(channel), " HTTP/1.1"].join(''),
      "Host: localhost:8080",
      ["Content-length: ", content.length].join(''),
      "", content
    ].join("\n"));
    fscommand("event", "connect");
  }

  function setHeartbeat(){
    if(heartbeat == 0) return;
    if(heartbeatId) clearInterval(heartbeatId);
    heartbeatId = setInterval(this, 'sendHeartbeat', heartbeat * 1000);
  }

  function sendHeartbeat(){
    socket.send('');
  }

  function log(message:String){
    if(_root.debug){
      var logs = _root.log.text.split("\r").concat(message);
      _root.log.text = logs.slice(-10).join("\n");
    }
  } 

  static function main(){
    System.security.loadPolicyFile(["xmlsocket://", _root.server].join(""));
    if(_root.debug = (_root.debug == 'true')){
      _root.createTextField("log", _root.getNextHighestDepth(), 0, 0, 300, 20);
      _root.log.multiline = true;
      _root.log.wordWrap = true;
      _root.log.autoSize = 'left';
      _root.log.text = "DEBIG MODE:";
    }
    (new MeteorStrike(_root)).establishConnection();
  }
}

// vim: ft=javascript
