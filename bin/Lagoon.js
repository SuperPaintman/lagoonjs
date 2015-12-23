var AVAILABLE_CONSOLES_METHODS, Console, EventEmitter, FILENAME_VARIABLE_REGEXP, Lagoon, Promise, _, colors, dateFormat, defaultConsole, events, fs, getData, mkdirp, path,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
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

Promise = require('bluebird');

AVAILABLE_CONSOLES_METHODS = ["log", "error", "info", "warn"];

FILENAME_VARIABLE_REGEXP = /%(\w+)%/g;

EventEmitter = events.EventEmitter;

defaultConsole = new Console(process.stdout, process.stderr);

getData = function(format, timestamp) {
  var form, formated, now;
  if (format == null) {
    format = "console";
  }
  if (timestamp == null) {
    timestamp = null;
  }

  /**
   * Timestamp
   * @type {Number}
   */
  now = timestamp ? timestamp : Date.now();
  switch (format) {
    case "console":
      form = "HH:MM:ss";
      formated = dateFormat(now, form);
      break;
    case "file":
      form = "yyyy-mm-dd";
      formated = dateFormat(now, form);
      break;
    case "timestamp":
      formated = parseInt(now, 10);
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

Lagoon = (function(superClass) {
  extend(Lagoon, superClass);

  function Lagoon(opts) {
    if (opts == null) {
      opts = {};
    }
    this._transportsFile = bind(this._transportsFile, this);
    this._transportsConsole = bind(this._transportsConsole, this);
    this._transportsSend = bind(this._transportsSend, this);
    this.trace = bind(this.trace, this);
    this.dir = bind(this.dir, this);
    this.assert = bind(this.assert, this);
    this.timeEnd = bind(this.timeEnd, this);
    this.time = bind(this.time, this);
    this.debug = bind(this.debug, this);
    this.fatal = bind(this.fatal, this);
    this.error = bind(this.error, this);
    this.warn = bind(this.warn, this);
    this.info = bind(this.info, this);
    this.log = bind(this.log, this);
    this._getFileInfo = bind(this._getFileInfo, this);
    this._initTextOffset = bind(this._initTextOffset, this);
    this.options = {};

    /**
     * Стиль логов
     * @type {Object}
     */
    this.options.settings = {
      log: {
        use: true,
        color: "yellow",
        background: false,
        text: "log",
        trace: false
      },
      info: {
        use: true,
        color: "gray",
        background: false,
        text: "info",
        trace: false
      },
      warn: {
        use: true,
        color: "cyan",
        background: false,
        text: "warn",
        trace: false
      },
      error: {
        use: true,
        color: "red",
        background: false,
        text: "error",
        trace: false
      },
      fatal: {
        use: true,
        color: "white",
        background: "bgRed",
        text: "fatal",
        trace: true
      },
      debug: {
        use: true,
        color: "magenta",
        background: false,
        text: "debug",
        trace: false
      },
      time: {
        use: true,
        color: "grey",
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
        filename: "./logs/log-%date%.log"
      }
    };

    /**
     * Variavles for filename
     * 
     * Formated:
     * * `%date%`       - date in **yyyy.mm.dd** format
     * * `%timestamp%`  - date in **timestamp**
     * * `%level%`      - Level of **current log**
     */
    this.options.variables = {
      "date": function() {
        return getData("file").formated;
      },
      "timestamp": function() {
        return getData("timestamp").formated;
      }
    };
    this.options = _.merge(this.options, opts);
    this._initTextOffset();
    this.timers = {};
    this._isDirectory = false;
  }


  /**
   * Инициализация отступа
   *
   * @private
   */

  Lagoon.prototype._initTextOffset = function() {
    var i, key, len, maxLen, offset, ref, ref1, ref2, value;
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
    for (key in ref1) {
      value = ref1[key];
      if (value.text != null) {
        offset = "";
        len = value.text.length;
        for (i = 0, ref2 = maxLen - len; 0 <= ref2 ? i < ref2 : i > ref2; 0 <= ref2 ? i++ : i--) {
          offset += " ";
        }
        this.options.settings[key]._offset = offset;
      }
    }
    return this;
  };


  /**
   * Форматирование входной строки
   * 
   * @return
   * {
   *     root : "/",
   *     dir : "/home/user/dir",
   *     base : "file.txt",
   *     ext : ".txt",
   *     name : "file"
   * }
   */

  Lagoon.prototype._getFileInfo = function(vars) {
    var filename;
    if (vars == null) {
      vars = {};
    }
    filename = this.options.transports.file.filename;
    filename = filename.replace(FILENAME_VARIABLE_REGEXP, (function(_this) {
      return function() {
        var matches, variable;
        matches = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        variable = matches[1];
        if (_this.options.variables[variable]) {
          return _this.options.variables[variable](_this);
        } else if (vars[variable]) {
          return vars[variable];
        } else {
          return matches[0];
        }
      };
    })(this));
    return path.parse(filename);
  };


  /**
   * Загрузка лога
   * @param  {Number}   timestamp - Таймстамп файла
   * @param  {Function} callback  
   *
   * @deprecated
   */


  /*
  loadLogs: (timestamp, callback)=>
       * 1 Параметр
      if typeof timestamp == 'function'
          callback = timestamp
  
          timestamp = new Date().getTime()
  
      pathToFolder = @._getFileInfo()
      filename = _getFilename()
      date = getData "timestamp", timestamp
      parhToLog = path.join pathToFolder, filename
  
      try
          fs.readFile parhToLog, 'utf8', (err, data)->
              if err then return callback err, null
              reg = /({.*})(?:\r|\n|$)/gi
  
              data = data.toString()
  
              logs = []
              while (log = reg.exec data) != null
                  try
                      logs.push JSON.parse log[0]
                  catch error
                      @.emit 'error', error
  
              callback null, logs
      catch e
          @.emit 'error', e
   */


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
   * Паспределения по транспортам
   * @param  {String}     [level="log"[]
   * @param  {Array}      args
   * @param  {Array}      [unformatedArgs=null] - Только для файлов
   */

  Lagoon.prototype._transportsSend = function(level, args, unformatedArgs) {
    var ref;
    if (level == null) {
      level = "log";
    }
    if (unformatedArgs == null) {
      unformatedArgs = null;
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
    date = getData("console");
    logs.push("[" + (colors["grey"](date.formated)) + "]");
    logSettings = this.options.settings[level];
    logColor = colors;
    if (logSettings.color) {
      logColor = logColor[logSettings.color];
    }
    if (logSettings.background) {
      logColor = logColor[logSettings.background];
    }
    logs.push("[" + (logColor(logSettings.text)) + "]" + logSettings._offset);
    logs = logs.concat(args);
    if (logSettings.use) {
      if (indexOf.call(AVAILABLE_CONSOLES_METHODS, level) >= 0) {
        method = level;
      } else {
        method = "log";
      }
      defaultConsole[method].apply(defaultConsole, logs);
    }
    if (logSettings.trace) {
      defaultConsole.trace();
    }
    return this.emit('transports:console', {
      level: level,
      message: args,
      timestamp: date.now
    });
  };


  /**
   * Запись логов в файл
   * @param  {String} level       - уровень вывода
   * @param  {Object} args        - аргументы лога
   *
   * @return {Promise}
   */

  Lagoon.prototype._transportsFile = function(level, args) {
    var date, pathInfo;
    if (level == null) {
      level = "log";
    }
    pathInfo = this._getFileInfo({
      level: level
    });
    date = getData("timestamp");
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return mkdirp(pathInfo.dir, function(err) {
          if (err) {
            return reject(err);
          } else {
            return resolve();
          }
        });
      };
    })(this)).then((function(_this) {
      return function() {
        var jsonLog, parhToLog;
        parhToLog = path.join(pathInfo.dir, pathInfo.base);
        jsonLog = JSON.stringify({
          level: level,
          message: args,
          timestamp: date.formated
        });
        return new Promise(function(resolve, reject) {
          return fs.appendFile(parhToLog, jsonLog + "\r\n", function(err) {
            if (err) {
              return reject(err);
            } else {
              return resolve();
            }
          });
        });
      };
    })(this)).done((function(_this) {
      return function() {
        return _this.emit('transports:file', {
          level: level,
          message: args,
          timestamp: date.now
        });
      };
    })(this), (function(_this) {
      return function(err) {
        return _this.emit('error', err);
      };
    })(this));
  };

  return Lagoon;

})(EventEmitter);

module.exports = new Lagoon();

module.exports.Lagoon = Lagoon;
