# Requires
events          = require 'events'
path            = require 'path'
fs              = require 'fs'
Console         = require('console').Console

colors          = require 'colors'
dateFormat      = require 'dateformat'
mkdirp          = require 'mkdirp'
_               = require 'lodash'
Promise         = require 'bluebird'

# Consts
AVAILABLE_CONSOLES_METHODS = [
    "log"
    "error"
    "info"
    "warn"
]

FILENAME_VARIABLE_REGEXP = /%(\w+)%/g

# Init
EventEmitter    = events.EventEmitter

defaultConsole  = new Console(process.stdout, process.stderr)

# Helps
getData = (format = "console", timestamp = null)->
    ###*
     * Timestamp
     * @type {Number}
    ###
    now = if timestamp then timestamp else Date.now()

    switch format
        when "console"
            form = "HH:MM:ss"
            formated = dateFormat now, form
        when "file"
            form = "yyyy-mm-dd"
            formated = dateFormat now, form
        when "timestamp"
            formated = parseInt now, 10
        else
            form = format
            formated = dateFormat now, form

    return {
        now
        formated
        form
    }

class Lagoon extends EventEmitter
    constructor: (opts = {})->
        @options = {}

        ###*
         * Стиль логов
         * @type {Object}
        ###
        @options.settings = {
            log:
                use:        true
                color:      "yellow"
                background: false
                text:       "log"
                trace:      false
            info:
                use:        true
                color:      "gray"
                background: false
                text:       "info"
                trace:      false
            warn:
                use:        true
                color:      "cyan"
                background: false
                text:       "warn"
                trace:      false
            error:
                use:        true
                color:      "red"
                background: false
                text:       "error"
                trace:      false
            fatal:
                use:        true
                color:      "white"
                background: "bgRed"
                text:       "fatal"
                trace:      true
            debug:
                use:        true
                color:      "magenta"
                background: false
                text:       "debug"
                trace:      false
            time:
                use:        true
                color:      "grey"
                background: false
                text:       "time"
                trace:      false
        }

        ###*
         * Транспорты
         * @type {Object}
        ###
        @options.transports = {
            console:
                use:    true
            file:
                use:        false
                filename:   "./logs/log-%date%.log"
        }

        ###*
         * Variavles for filename
         * 
         * Formated:
         * * `%date%`       - date in **yyyy.mm.dd** format
         * * `%timestamp%`  - date in **timestamp**
         * * `%level%`      - Level of **current log**
        ###
        @options.variables = {
            "date":         -> getData("file").formated
            "timestamp":    -> getData("timestamp").formated
        }

        # Мердж опций
        @options = _.merge @options, opts

        # Выравнивание заголовков
        do @._initTextOffset

        # Таймеры
        @timers = {}

        # Есть ли папка
        @_isDirectory = false

    ###*
     * Инициализация отступа
     *
     * @private
    ###
    _initTextOffset: =>
        maxLen = 0

        for key, value of @options.settings
            if value.text?
                len = value.text.length

                maxLen = Math.max(maxLen, len)

        for key, value of @options.settings
            if value.text?
                offset = ""

                len = value.text.length
                for [0...maxLen - len]
                    offset += " " 

                @options.settings[ key ]._offset = offset

        return @

    ###*
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
    ###
    _getFileInfo: (vars = {})=> 
        filename = @options.transports.file.filename

        # Replace variables
        filename = filename.replace FILENAME_VARIABLE_REGEXP, (matches...)=>
            variable = matches[1]

            # Function
            if @options.variables[ variable ]
                @options.variables[ variable ](@)
            # Static
            else if vars[ variable ]
                vars[ variable ]
            # Self
            else
                matches[0]

        return path.parse(filename)

    ###*
     * Загрузка лога
     * @param  {Number}   timestamp - Таймстамп файла
     * @param  {Function} callback  
     *
     * @deprecated
    ###
    ###
    loadLogs: (timestamp, callback)=>
        # 1 Параметр
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
    ###

    ###*
     * Стандартные логи
    ###
    log: (args...)=>
        @._transportsSend "log", args
    info: (args...)=>
        @._transportsSend "info", args
    warn: (args...)=>
        @._transportsSend "warn", args
    error: (args...)=>
        @._transportsSend "error", args
    fatal: (args...)=>
        @._transportsSend "fatal", args
    debug: (args...)=>
        @._transportsSend "debug", args

    ###*
     * Время
    ###
    time: (label)=>
        if label
            @timers[ label ] = {}
            @timers[ label ].start = Date.now()

    timeEnd: (label, show = true)=>
        if label and @timers[ label ]
            @timers[ label ].end = Date.now()
            delta = @timers[ label ].end - @timers[ label ].start

            delete @timers[ label ]

            if show
                args = []
                args.push "#{colors["cyan"]( label )}:"
                args.push "#{colors["green"]( delta )}ms"

                @._transportsSend "time", args, [
                    label
                    delta
                ]
            else
                return delta

    ###*
     * Default
    ###
    assert: (args...)=> defaultConsole.assert.apply @, args
    dir:    (args...)=> defaultConsole.dir.apply    @, args
    trace:  (args...)=> defaultConsole.trace.apply  @, args

    ###*
     * Паспределения по транспортам
     * @param  {String}     [level="log"[]
     * @param  {Array}      args
     * @param  {Array}      [unformatedArgs=null] - Только для файлов
    ###
    _transportsSend: (level="log", args, unformatedArgs = null)=>
        if @options.settings[ level ]?.use
            # Вывод в консоль
            if @options.transports.console.use
                @._transportsConsole level, args

            # Вывод в файл
            if @options.transports.file.use
                if unformatedArgs
                    @._transportsFile level, unformatedArgs
                else
                    @._transportsFile level, args

            if unformatedArgs
                @.emit "logger", level, unformatedArgs
                @.emit "logger:#{ level }", unformatedArgs
            else
                @.emit "logger", level, args
                @.emit "logger:#{ level }", args


    ###*
     * Вывод отформатированного лога на экран
     * @param  {String} level       - уровень вывода
     * @param  {Array} args         - аргументы лога
    ###
    _transportsConsole: (level="log", args)=>
        logs = []
        # Текущая дата в формате HH:MM:ss
        date = getData "console"

        # Добавление времени
        logs.push "[#{colors["grey"](date.formated)}]"

        logSettings = @options.settings[ level ]

        logColor = colors
        if logSettings.color       then logColor = logColor[ logSettings.color ]
        if logSettings.background  then logColor = logColor[ logSettings.background ]

        # Добавление уровня
        logs.push "[#{ logColor(logSettings.text) }]#{ logSettings._offset }"
        
        # Добавление аргументов
        logs = logs.concat args

        # Console
        if logSettings.use
            if level in AVAILABLE_CONSOLES_METHODS
                method = level
            else
                method = "log"

            defaultConsole[ method ](logs...)

        # Trace
        if logSettings.trace
            defaultConsole.trace()

        # Event
        @.emit 'transports:console', {
            level:      level
            message:    args
            timestamp:  date.now
        }

    ###*
     * Запись логов в файл
     * @param  {String} level       - уровень вывода
     * @param  {Object} args        - аргументы лога
     *
     * @return {Promise}
    ###
    _transportsFile: (level="log", args)=>
        # Информация о файле
        pathInfo = @._getFileInfo({
            level: level
        })

        # Текущее время
        date = getData "timestamp"

        # Создание папки
        new Promise (resolve, reject)=>
            mkdirp pathInfo.dir, (err)=>
                if err then reject(err)
                else resolve()
        # Запись в файл
        .then =>
            # Полный путь до папки
            parhToLog = path.join(pathInfo.dir, pathInfo.base)

            jsonLog = JSON.stringify {
                level:      level
                message:    args
                timestamp:  date.formated
            }

            new Promise (resolve, reject)=>
                fs.appendFile parhToLog, "#{jsonLog}\r\n", (err)=>
                    if err then reject(err)
                    else resolve()
        # Инициализация эвента
        .done =>
            # Event
            @.emit 'transports:file', {
                level:      level
                message:    args
                timestamp:  date.now
            }
        , (err)=>
            @.emit 'error', err

# Exports
module.exports          = new Lagoon()
module.exports.Lagoon   = Lagoon