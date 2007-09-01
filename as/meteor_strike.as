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
  var index:Number;

  private var mc:MovieClip;
  private var socket:XMLSocket;
  private var connected:Boolean;
  private var heartbeatId:Number;
  private var phase:String;
  private var connectorId:Number;

  function MeteorStrike(mc:MovieClip){
    var host_port = mc.server.split(':');
    host = host_port[0];
    port = new Number(host_port[1] || 80);
    interval = mc.interval;
    heartbeat = new Number(mc.heartbeat || 0);
    channel = mc.channel;
    uid = mc.uid;
    tag = mc.tag;
    sig = mc.sig;
    baseUri = mc.base_uri
    connected = false;
    heartbeatId = null;
    phase = 'connect';
    index = mc.meteor_strike_id;
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
      self.execute("event", "close");
      self.resetConnector();
      self.connectorId = setInterval(self, 'makeConnection', 1000);
    };
    socket.onData = function(data:String){
      self.log(["onData: ", data.slice(0, 40)].join(''));
      self.setHeartbeat();
      self.execute("execute", data);
    };
    makeConnection();
  }

  function makeConnection(){
    resetConnector();
    if(connected) return;
    log(["makeConnection: ", host, ':', port].join(''));
    if(!socket.connect(host, port)){
      connectorId = setInterval(this, 'makeConnection', interval || 3000);
    }
  }

  function startCommunication(){
    var content = [
      "__t__=flash&__p__=", phase,
      "&uid=", escape(uid),
      "&tag=", escape(tag),
      "&sig=", escape(sig),
      "&execute=", baseUri, "/meteor/strike"
    ].join("");
    if(phase == 'connect'){
      execute("event", "connect");
      phase = 'reconnect';
    }
    socket.send([
      ["POST /", escape(channel), " HTTP/1.1"].join(''),
      ["Host: ", host, ':', port].join(''),
      ["Content-length: ", content.length].join(''),
      "", content
    ].join("\n"));
  }

  function resetConnector(){
    if(!connectorId) return;
    clearInterval(connectorId);
    connectorId = null;
  }

  function execute(command:String, args:String){
    log(['FSCommand:', command].join(''));
    getURL(['FSCommand:', command].join(''), escape(args));
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
      _root.log.text = logs.slice(-20).join("\n");
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
