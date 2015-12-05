var AVAILABLE_CONSOLES_METHODS, Console, EventEmitter, Lagoon, _, colors, dateFormat, defaultConsole, events, fs, mkdirp, path,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

events = require('events');

path = require('path');

fs = require('fs');

Console = require('console').Console;

colors = require('colors');

dateFormat = require('dateformat');

mkdirp = require('mkdirp');

_ = require('lodash');

AVAILABLE_CONSOLES_METHODS = ["log", "error", "info", "warn"];

EventEmitter = events.EventEmitter;

defaultConsole = new Console(process.stdout, process.stderr);

Lagoon = (function(superClass) {
  var _getData, _getFilename;

  extend(Lagoon, superClass);

  function Lagoon(opts) {
    if (opts == null) {
      opts = {};
    }
    this.options = {};

    /**
     * Стиль логов
     * @type {Object}
     */
    this.options.settings = {
      log: {
        use: true,
        colors: "yellow",
        background: false,
        text: "log",
        trace: false
      },
      info: {
        use: true,
        colors: "gray",
        background: false,
        text: "info",
        trace: false
      },
      warn: {
        use: true,
        colors: "cyan",
        background: false,
        text: "warn",
        trace: false
      },
      error: {
        use: true,
        colors: "red",
        background: false,
        text: "error",
        trace: false
      },
      fatal: {
        use: true,
        colors: "white",
        background: "bgRed",
        text: "fatal",
        trace: true
      },
      debug: {
        use: true,
        colors: "magenta",
        background: false,
        text: "debug",
        trace: false
      },
      time: {
        use: true,
        colors: "grey",
        background: false,
        text: "time",
        trace: false
      }
    };

    /**
     * Транспорты
     * @type {Object}
     */
    this.options.transports = {
      console: {
        use: true
      },
      file: {
        use: false,
        path: "./logs/"
      }
    };
    this.options = _.merge(this.options, opts);
    this.$getOffset();
    this.timers = {};
    this.isDirectory = false;
  }

  Lagoon.prototype.$getOffset = function() {
    var i, key, len, maxLen, offset, ref, ref1, ref2, results, value;
    maxLen = 0;
    ref = this.options.settings;
    for (key in ref) {
      value = ref[key];
      if (value.text != null) {
        len = value.text.length;
        maxLen = Math.max(maxLen, len);
      }
    }
    ref1 = this.options.settings;
    results = [];
    for (key in ref1) {
      value = ref1[key];
      if (value.text != null) {
        offset = "";
        len = value.text.length;
        for (i = 0, ref2 = maxLen - len; 0 <= ref2 ? i < ref2 : i > ref2; 0 <= ref2 ? i++ : i--) {
          offset += " ";
        }
        results.push(this.options.settings[key].$$offset = offset);
      } else {
        results.push(void 0);
      }
    }
    return results;
  };


  /**
   * Стандартные логи
   */

  Lagoon.prototype.log = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("log", args);
  };

  Lagoon.prototype.info = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("info", args);
  };

  Lagoon.prototype.warn = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("warn", args);
  };

  Lagoon.prototype.error = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("error", args);
  };

  Lagoon.prototype.fatal = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("fatal", args);
  };

  Lagoon.prototype.debug = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return this._transportsSend("debug", args);
  };


  /**
   * Время
   */

  Lagoon.prototype.time = function(label) {
    if (label) {
      this.timers[label] = {};
      return this.timers[label].start = Date.now();
    }
  };

  Lagoon.prototype.timeEnd = function(label, show) {
    var args, delta;
    if (show == null) {
      show = true;
    }
    if (label && this.timers[label]) {
      this.timers[label].end = Date.now();
      delta = this.timers[label].end - this.timers[label].start;
      delete this.timers[label];
      if (show) {
        args = [];
        args.push((colors["cyan"](label)) + ":");
        args.push((colors["green"](delta)) + "ms");
        return this._transportsSend("time", args, [label, delta]);
      } else {
        return delta;
      }
    }
  };


  /**
   * Default
   */

  Lagoon.prototype.assert = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return defaultConsole.assert.apply(this, args);
  };

  Lagoon.prototype.dir = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return defaultConsole.dir.apply(this, args);
  };

  Lagoon.prototype.trace = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return defaultConsole.trace.apply(this, args);
  };


  /**
   * Загрузка лога
   * @param  {Number}   timestamp - Таймстамп файла
   * @param  {Function} callback
   */

  Lagoon.prototype.loadLogs = function(timestamp, callback) {
    var date, e, error1, filename, parhToLog, pathToFolder;
    if (typeof timestamp === 'function') {
      callback = timestamp;
      timestamp = new Date().getTime();
    }
    pathToFolder = this._getPathToLogs();
    filename = _getFilename();
    date = _getData("timestamp", timestamp);
    parhToLog = path.join(pathToFolder, filename);
    try {
      return fs.readFile(parhToLog, 'utf8', function(err, data) {
        var error, error1, log, logs, reg;
        if (err) {
          return callback(err, null);
        }
        reg = /({.*})(?:\r|\n|$)/gi;
        data = data.toString();
        logs = [];
        while ((log = reg.exec(data)) !== null) {
          try {
            logs.push(JSON.parse(log[0]));
          } catch (error1) {
            error = error1;
            this.emit('error', error);
          }
        }
        return callback(null, logs);
      });
    } catch (error1) {
      e = error1;
      return this.emit('error', e);
    }
  };

  _getData = function(format, timestamp) {
    var form, formated, now;
    if (format == null) {
      format = "console";
    }
    if (timestamp == null) {
      timestamp = null;
    }
    if (timestamp) {
      now = new Date(timestamp);
    } else {
      now = new Date();
    }
    switch (format) {
      case "console":
        form = "HH:MM:ss";
        formated = dateFormat(now, form);
        break;
      case "file":
        form = "yyyy.mm.dd";
        formated = dateFormat(now, form);
        break;
      case "timestamp":
        formated = parseInt(now.getTime());
        break;
      default:
        form = format;
        formated = dateFormat(now, form);
    }
    return {
      now: now,
      formated: formated,
      form: form
    };
  };

  _getFilename = function() {
    var date, filename;
    date = _getData("file");
    filename = "logger-" + date.formated + ".log";
    return filename;
  };

  Lagoon.prototype._getPathToLogs = function() {
    return this.options.transports.file.path;
  };

  Lagoon.prototype._transportsSend = function(level, args, unformatedArgs) {
    var ref;
    if (level == null) {
      level = "log";
    }
    if ((ref = this.options.settings[level]) != null ? ref.use : void 0) {
      if (this.options.transports.console.use) {
        this._transportsConsole(level, args);
      }
      if (this.options.transports.file.use) {
        if (unformatedArgs) {
          this._transportsFile(level, unformatedArgs);
        } else {
          this._transportsFile(level, args);
        }
      }
      if (unformatedArgs) {
        this.emit("logger", level, unformatedArgs);
        return this.emit("logger:" + level, unformatedArgs);
      } else {
        this.emit("logger", level, args);
        return this.emit("logger:" + level, args);
      }
    }
  };


  /**
   * Вывод отформатированного лога на экран
   * @param  {String} level       - уровень вывода
   * @param  {Array} args         - аргументы лога
   */

  Lagoon.prototype._transportsConsole = function(level, args) {
    var date, logColor, logSettings, logs, method;
    if (level == null) {
      level = "log";
    }
    logs = [];
    date = _getData("console");
    logs.push("[" + (colors["grey"](date.formated)) + "]");
    logSettings = this.options.settings[level];
    logColor = colors;
    if (logSettings.colors) {
      logColor = logColor[logSettings.colors];
    }
    if (logSettings.background) {
      logColor = logColor[logSettings.background];
    }
    logs.push("[" + (logColor(logSettings.text)) + "]" + logSettings.$$offset);
    logs = logs.concat(args);
    if (logSettings.use) {
      method = "log";
      if (indexOf.call(AVAILABLE_CONSOLES_METHODS, level) >= 0) {
        method = level;
      }
      defaultConsole[method].apply(this, logs);
    }
    if (logSettings.trace) {
      defaultConsole.trace();
    }
    return this.emit('transports:console', {
      level: level,
      message: args,
      timestamp: date.now.getTime()
    });
  };


  /**
   * Запись логов в файл
   * @param  {String} level       - уровень вывода
   * @param  {Object} args        - аргументы лога
   */

  Lagoon.prototype._transportsFile = function(level, args) {
    var date, e, error1, error2, filename, jsonLog, parhToLog, pathToFolder;
    if (level == null) {
      level = "log";
    }
    pathToFolder = this._getPathToLogs();
    if (!this.isDirectory) {
      try {
        if (!fs.lstatSync(pathToFolder).isDirectory()) {
          mkdirp(pathToFolder);
        }
      } catch (error1) {
        e = error1;
        mkdirp(pathToFolder);
      }
    }
    this.isDirectory = true;
    filename = _getFilename();
    date = _getData("timestamp");
    parhToLog = path.join(pathToFolder, filename);
    try {
      jsonLog = JSON.stringify({
        level: level,
        message: args,
        timestamp: date.formated
      });
      fs.appendFile(parhToLog, jsonLog + "\r\n");
    } catch (error2) {
      e = error2;
      this.emit('error', e);
    }
    return this.emit('transports:file', {
      level: level,
      message: args,
      timestamp: date.now.getTime()
    });
  };

  return Lagoon;

})(EventEmitter);

module.exports = new Lagoon();

module.exports.Lagoon = Lagoon;
