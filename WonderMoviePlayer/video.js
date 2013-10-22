function qqbridge(){
    this.sendMsg = function (msg) {
		this.send('qqvideo://msg/' + msg);
    };
	this.send = function (dst) {
		if (window.qqbridgeInstance != undefined) {
            document.documentElement.removeChild(window.qqbridgeInstance);
   		}
        
        var bridge = document.createElement('iframe');
        bridge.setAttribute('style', 'display:none');
        bridge.setAttribute('height', '0px');
        bridge.setAttribute('width', '0px');
        bridge.setAttribute('frameloader', '0');
        document.documentElement.appendChild(bridge);
        bridge.src = dst;
        window.qqbridgeInstance = bridge;
	}
}

function qqvideo() {
    this.hook = function(v) {
        if (v.qqvideoInstance == undefined) {
            var qqv = this;
            v.qqvideoInstance = qqv;
            v.orgPlay = v.play;
            v.play = function () {
                this.qqvideoInstance.workaroundBefore(v);
                this.qqvideoInstance.newPlay(v);
                this.qqvideoInstance.workaroundAfter(v);
            };
            v.orgLoad = v.load;
            v.load = function () {
                if (this.autoplay) {
                    this.qqvideoInstance.workaroundBefore(v);
                    this.qqvideoInstance.newPlay(v);
                    this.qqvideoInstance.workaroundAfter(v);
                }
            };
            v.qqvideoInstance.workaroundInit(v);
        }
    };
    
    this.newPlay = function(v) {
        new qqbridge().send('qqvideo://play');
    };
    
    this.workaroundInit = function (v) {
        // workaround when hook the video
        
        // for youku fullscreen issue
        if (location.host.indexOf('youku.com')) {
            YKU.Player.prototype.switchFullScreen = function () {};
            playerWidth = function (){
                var a = $(window).width(), b = $(window).height();
                $(".yk-player .yk-player-inner").css({
                                                     width: a + "px",
                                                     height: 9 * a / 16 + "px"
                                                     });
            };
            autoFullscreen = function (){};
            onSwitchFullScreen = function () {
                clearInterval(window.timers), setTimeout("playerWidth()", 500), setTimeout("playerWidth()", 1E3), $("body").removeClass("fullscreen"), $("body").removeAttr("style"), $(".yk-m").removeAttr("style"), playerWidth(), tabFixed.unfixed();
            };
            onPlayerCompleteH5 = function (a) {};
            onPlayerReadyH5 = function () {};
            window.youkuCheckTimer = setInterval(
                                                 function (){
                                                 clearInterval(window.timers);
                                                 }, 500);
        }
    };
    
    this.workaroundBefore = function (v) {
        // workaround before player show
    };
    
    this.workaroundAfter = function(v) {
        // workaround after player finish
        v.readyState = 4;
        this.timeupdateRemainingCount = 10;
        
        // workaround for letv
        // need to send timeupdate more than 5 times
        var sendTimeupdate = function () {
            if (v.qqvideoInstance.timeupdateRemainingCount > 0){
                v.qqvideoInstance.timeupdateRemainingCount --;
                v.qqvideoInstance.sendEvent(v, 'timeupdate');
                setTimeout(sendTimeupdate, 1000);
            }
        }
        setTimeout(sendTimeupdate, 1000);
    }
    
    
    this.sendEvent = function (obj, type) {
        var eventObj = document.createEvent('HTMLEvents');
        eventObj.initEvent(type, false, true);
        obj.dispatchEvent(eventObj);
    }
}

var vs = document.getElementsByTagName('video');
if (vs.length > 0) {
    var v = vs[0];
    new qqvideo().hook(v);
}
/*
 function getCallStack() {
 var stack = [];
 var fun = getCallStack;
 while (fun = fun.caller) {
 stack.push(fun);
 }
 return stack
 }*/