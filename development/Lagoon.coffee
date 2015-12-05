# Requires
events          = require 'events'
path            = require 'path'
fs              = require 'fs'
Console         = require('console').Console

colors          = require 'colors'
dateFormat      = require 'dateformat'
mkdirp          = require 'mkdirp'
_               = require 'lodash'

# Consts
AVAILABLE_CONSOLES_METHODS = [
    "log"
    "error"
    "info"
    "warn"
]

# Init
EventEmitter    = events.EventEmitter

defaultConsole  = new Console(process.stdout, process.stderr)

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
                use:    false
                path:   "./logs/"
        }

        # Мердж опций
        @options = _.merge @options, opts

        # Выравнивание заголовков
        do @.$getOffset

        # Таймеры
        @timers = {}

        # Есть ли папка
        @isDirectory = false

        # @data = if opts?.levels then true else false

    $getOffset: ->
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

                @options.settings[ key ].$$offset = offset

    ###*
     * Стандартные логи
    ###
    log: (args...)->
        @._transportsSend "log", args
    info: (args...)->
        @._transportsSend "info", args
    warn: (args...)->
        @._transportsSend "warn", args
    error: (args...)->
        @._transportsSend "error", args
    fatal: (args...)->
        @._transportsSend "fatal", args
    debug: (args...)->
        @._transportsSend "debug", args

    ###*
     * Время
    ###
    time: (label)->
        if label
            @timers[ label ] = {}
            @timers[ label ].start = Date.now()

    timeEnd: (label, show = true)->
        if label and @timers[ label ]
            @timers[ label ].end = Date.now()
            delta = @timers[ label ].end - @timers[ label ].start

            delete @timers[ label ]

            if show
                args = []
                args.push( "#{colors["cyan"]( label )}:" )
                args.push( "#{colors["green"]( delta )}ms" )

                @._transportsSend "time", args, [
                    label
                    delta
                ]
            else
                return delta

    ###*
     * Default
    ###
    assert: (args...)-> defaultConsole.assert.apply @, args
    dir: (args...)->    defaultConsole.dir.apply    @, args
    trace: (args...)->  defaultConsole.trace.apply  @, args

    ###*
     * Загрузка лога
     * @param  {Number}   timestamp - Таймстамп файла
     * @param  {Function} callback  
    ###
    loadLogs: (timestamp, callback)->
        # 1 Параметр
        if typeof timestamp == 'function'
            callback = timestamp

            timestamp = new Date().getTime()

        pathToFolder = @._getPathToLogs()
        filename = _getFilename()
        date = _getData "timestamp", timestamp
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

    _getData = (format = "console", timestamp = null)->
        if timestamp
            now = new Date(timestamp)
        else
            now = new Date()

        switch format
            when "console"
                form = "HH:MM:ss"
                formated = dateFormat now, form
            when "file"
                form = "yyyy.mm.dd"
                formated = dateFormat now, form
            when "timestamp"
                formated = parseInt now.getTime()
            else
                form = format
                formated = dateFormat now, form

        return {
            now
            formated
            form
        }

    _getFilename = ->
        date = _getData "file"
        filename = "logger-#{date.formated}.log"

        return filename

    _getPathToLogs: -> @options.transports.file.path

    _transportsSend: (level="log", args, unformatedArgs)->
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
    _transportsConsole: (level="log", args)->
        logs = []
        date = _getData "console"
        logs.push "[#{colors["grey"](date.formated)}]"

        logSettings = @options.settings[ level ]

        logColor = colors
        if logSettings.color       then logColor = logColor[ logSettings.color ]
        if logSettings.background  then logColor = logColor[ logSettings.background ]

        logs.push "[#{ logColor(logSettings.text) }]#{ logSettings.$$offset }"
        logs = logs.concat args

        # Console
        if logSettings.use
            method = "log"
            if level in AVAILABLE_CONSOLES_METHODS
                method = level

            defaultConsole[ method ].apply @, logs

        # Trace
        if logSettings.trace
            defaultConsole.trace()

        @.emit 'transports:console', {
            level: level
            # message: Array.prototype.slice.call(args).join(' ')
            message: args
            timestamp: date.now.getTime()
        }

    ###*
     * Запись логов в файл
     * @param  {String} level       - уровень вывода
     * @param  {Object} args        - аргументы лога
    ###
    _transportsFile: (level="log", args)->
        # Создание папки под гоги
        pathToFolder = @._getPathToLogs()

        unless @isDirectory
            try
                unless fs.lstatSync( pathToFolder ).isDirectory()
                    mkdirp pathToFolder
            catch e
                mkdirp pathToFolder

                # Убрана внутряняя ошибка
                # @.emit 'error', e
        @isDirectory = true

        filename = _getFilename()
        date = _getData "timestamp"

        parhToLog = path.join pathToFolder, filename

        try
            jsonLog = JSON.stringify {
                level: level
                # message: Array.prototype.slice.call(args).join(' ')
                message: args
                timestamp: date.formated
            }
            fs.appendFile parhToLog, "#{jsonLog}\r\n"
        catch e
            @.emit 'error', e

        @.emit 'transports:file', {
            level: level
            # message: Array.prototype.slice.call(args).join(' ')
            message: args
            timestamp: date.now.getTime()
        }

# Exports
module.exports          = new Lagoon()
module.exports.Lagoon   = Lagoon