
//H5交互方法替换
var iosApiList = ["downloadThirdapp", "getDevInfoById", "getDevList", "getStateInfo", "isNetworkConnected", "operateTvByTcast", "receiveH5Msg", "requestCityInfo", "searchDevice", "sendRemoteMessage", "setShowBackDialog", "setStateInfo", "startActivity", "startApp", "startDeviceSetActivity", "startDeviceShareActivity", "startFindDevice", "startGeneralDeviceSetActivity", "startHomeModeActivity", "stopAppGoBack", "sendLogToOC", "getPhoneAppVersion", "reLoadAirBoxIndex", "startRN", "getH5MemoryFromOC", "setH5MemoryToOC", "washBack", "reportBiData", "getPhoneAppVersion", "backToDeviceListRN"];

iosApiList.forEach (
  function (v) {
    window[v] = function () {
      var s = "";
      if (typeof(arguments) != "underfined") {
        for (var i = 0; i < arguments.length; i++) {
          s = s + arguments[i];
          s = s + '#$#@';
        }
      }
      var j = window.prompt('tclH5_' + v, s);
      if (j == "true##") {
        return true;
      } else if (j == "false##") {
        return false;
      } else {
        return j;
      }
    }
  }
)

//打印方法替换
console.log = (
  function (oriLogFunc) {
    return function (str) {
      window.prompt('tclH5_' + 'consoleLog', str);
      oriLogFunc.call(console, str);
    }
  }
)(console.log);
//警告方法替换
console.warn = (
  function (oriWarnLogFunc) {
    return function (str) {
      window.prompt('tclH5_' + 'consoleWarnLog', str);
      oriWarnLogFunc.call(console, str);
    }
  }
)(console.warn);
//错误方法替换
console.error = (
  function (oriErrorLogFunc) {
    return function (str) {
      window.prompt('tclH5_' + 'consoleErrorLog', str);
      oriErrorLogFunc.call(console, str);
    }
  }
)(console.error);
