function iOSExec() {
    var service, action, actionArgs, splitCommand;
    var callbackId;
    service = arguments[0];
    action = arguments[1];
    actionArgs = arguments[2];
    callbackId = 'INVALID';
    
    var command = [callbackId, service, action, actionArgs];
    var execXhr = new XMLHttpRequest();
    execXhr.open('HEAD', '/!qq_exec?' + (+new Date()), true);
    execXhr.setRequestHeader('cmds', JSON.stringify(command));
    execXhr.setRequestHeader('rc', '' + (+new Date()));
    execXhr.send(null);
}
var v = document.getElementsByTagName('video')[0];
if (v.orgPlay == undefined) {
    v.orgPlay = v.play;
    var src = v.currentSrc;
    if (src == undefined || src == '') {
        src = v.src;
    }
    if (src != undefined && src != '') {
        v.play = function () {
            alert('setted');
            iOSExec('qqvideo', 'play', [src]);
        }
    }
    else {
        alert('no src');
    }

}