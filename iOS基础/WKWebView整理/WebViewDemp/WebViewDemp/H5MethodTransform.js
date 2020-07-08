
//H5交互方法替换
var iosApiList = ["method1", "method2", "method3", "method4", "method5", "method6", "method7"];

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
      var j = window.prompt('tshH5_' + v, s);
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
      window.prompt('tshH5_' + 'consoleLog', str);
      oriLogFunc.call(console, str);
    }
  }
)(console.log);
//警告方法替换
console.warn = (
  function (oriWarnLogFunc) {
    return function (str) {
      window.prompt('tshH5_' + 'consoleWarnLog', str);
      oriWarnLogFunc.call(console, str);
    }
  }
)(console.warn);
//错误方法替换
console.error = (
  function (oriErrorLogFunc) {
    return function (str) {
      window.prompt('tshH5_' + 'consoleErrorLog', str);
      oriErrorLogFunc.call(console, str);
    }
  }
)(console.error);
