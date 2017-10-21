###
Requires
###
fs              = require 'fs'

gulp            = require 'gulp'
gulpsync        = require('gulp-sync')(gulp)

sourcemaps      = require 'gulp-sourcemaps'

gutil           = require 'gulp-util'
clean           = require "gulp-clean"
zip             = require 'gulp-zip'

mocha           = require 'gulp-mocha'

CronJob         = require('cron').CronJob
colors          = require 'colors'

# Server
coffee          = require 'gulp-coffee'
cson            = require 'gulp-cson'

jsdoc           = require "gulp-jsdoc"

# Client
#-- Styles
stylus          = require 'gulp-stylus'
# sass            = require 'gulp-sass'
# less            = require 'gulp-less'

minifyCss       = require 'gulp-minify-css'
autoprefixer    = require 'gulp-autoprefixer'

#-- Images
imagemin        = require 'gulp-imagemin'
jpegtran        = require 'imagemin-jpegtran'
pngquant        = require 'imagemin-pngquant'
gifsicle        = require 'imagemin-gifsicle'

#-- General
browserify      = require 'gulp-browserify'
uglify          = require 'gulp-uglify'
rename          = require 'gulp-rename'
insert          = require 'gulp-insert'

###
=====================================
Пути
=====================================
###

# Папки где находится проект
folders = 
    server:
        development:    "development"
        production:     "bin"

    client:
        public:         "public"
        private:        "private"
        templates:      "templates"

        assets:
            coffee:     "coffee"
            js:         "js"
            styles:     "styles"
            images:     "images"
            copy:       "copy"

    general:
        docs:           "docs"
        backup:         "backup"
        release:        "release"

times =
    backup: 30

fileExt = 
    styles:             "styl"
    # styles:             "scss"
    # styles:             "less"

# Пути до задач
paths =
    # Клиентские файлы
    client:
        # Styles
        styles:
            from: [
                "./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.styles}/**/*.#{fileExt.styles}"
                "!./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.styles}/**/_*.#{fileExt.styles}"
            ]
            to:     "./#{folders.server.production}/#{folders.client.public}/css/"
            suffix: ""

        # Coffee
        coffee:
            from: [
                "./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.coffee}/**/*.coffee"
                "!./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.coffee}/**/_*.coffee"
            ]
            to:     "./#{folders.server.production}/#{folders.client.public}/js/"
            suffix: ".min"

        # JavaScript
        js:
            from: [
                "./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.js}/**/*.js"
                "!./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.js}/**/_*.js"
                "!./#{folders.server.production}/**/*.js"
            ]
            to:     "./#{folders.server.production}/#{folders.client.public}/js/"
            suffix: ".min"
        # Картинки
        images:
            from: [
                "./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.images}/**/*.*"
                "!./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.images}/**/_*.*"
            ]
            to: "./#{folders.server.production}/#{folders.client.public}/images/"
        # Копирование
        copy:
            from: [
                "./#{folders.server.development}/#{folders.client.private}/#{folders.client.assets.copy}/**/*"
            ]
            to:     "./#{folders.server.production}/#{folders.client.public}/"
            suffix: ""

        # Шаблоны
        templates:
            from: [
                "./#{folders.server.development}/#{folders.client.templates}/**/*"
            ]
            to: "./#{folders.server.production}/#{folders.client.templates}/"

    # Серверные файлы
    server:
        coffee:
            from: [
                "./#{folders.server.development}/**/*.coffee"
                "!./#{folders.server.development}/#{folders.client.private}/**/*"
            ]
            to:     "./#{folders.server.production}/"

        cson:
            from: [
                "./#{folders.server.development}/**/*.cson"
                "!./#{folders.server.development}/#{folders.client.private}/**/*"
            ]
            to:     "./#{folders.server.production}/"

    # Остальное
    general:
        # Документация
        jsdoc:
            from: [
                "./#{folders.server.production}/**/*.js"
                "!./#{folders.server.production}/node_modules/**/*.js"
            ]
            to: "./#{folders.general.docs}/"
        # Бэкапы
        backup:
            from: [
                "./#{folders.server.development}/**/*"
                "./#{folders.general.release}/**/*"
                "./*.*"
                "!./"
                "!./#{folders.general.docs}/**/*"
                "!./#{folders.general.backup}/**/*"
                "!./#{folders.server.production}/**/*"
            ]
            to: "./#{folders.general.backup}/"
        # Релизы
        release:
            from: [
                "./#{folders.server.production}/**/*"
                "./*.{json,js,yml,md,txt}"
                "!./"
                "!./#{folders.server.development}/**/*"
                "!./#{folders.general.docs}/**/*"
                "!./#{folders.general.backup}/**/*"
                "!./#{folders.general.release}/**/*"
            ]
            to: "./#{folders.general.release}/"
        # Очистка предыдущей сборки
        clean:
            from: [
                "./#{folders.server.production}/**/*"
            ]
        # Тестирование
        test:
            from: [
                "./#{folders.server.production}/test/**/test*.js"
            ]

###
=====================================
Окружение
=====================================
###
$isProduction = false

###
=====================================
Функции
=====================================
###

###*
 * Обработчик ошибок
 * @param  {Error} err - ошибка
###
error = (err)->
    if err.toString
        console.log err.toString()
    else
        console.log err.message
    @.emit 'end'

###*
 * Получение версии пакета
 * @param  {String} placeholder - строка которая заменит версию пакета, если JSON файл поврежден
 * @return {String}             - версия пакета
###
getPackageVersion = (placeholder)->
    try
        packageFile = fs.readFileSync("./package.json").toString()
        packageFile = JSON.parse packageFile

        if packageFile?.version?
            version = "v#{packageFile.version}"
        else
            version = null
    catch e
        error e
        version = null

    if !version and placeholder
        version = "#{placeholder}"
    else if !version
        version = "v0.0.0"

    return version

###*
 * Преобразует минуты в cron
 * @param  {Number} min - период бекаров
 * @return {String}     - cron date
###
getCronTime = (min)->
    return "0 */#{min} * * * *"

###
=====================================
Задачи
=====================================
###
###
-------------------------------------
Клиент
-------------------------------------
###
# Styles
gulp.task 'client:styles', (next)->
    gulp.src paths.client.styles.from
        # Source map
        .pipe if $isProduction then gutil.noop() else sourcemaps.init()
        # Рендер Styles
        .pipe stylus().on 'error', error
        # .pipe sass().on 'error', error
        # .pipe less().on 'error', error
        # Добавление префиксов
        .pipe autoprefixer {
            browsers: ['last 100 version']
        }
        # Минификация
        #-- TODO: добавить keepSpecialComments
        .pipe minifyCss {
            rebase: false
        }
        # Переименование
        .pipe rename {
            suffix: paths.client.styles.suffix
        }
        # Сохранение Source Map
        .pipe if $isProduction then gutil.noop() else sourcemaps.write("./")
        # Сохранение
        .pipe gulp.dest paths.client.styles.to
        .on 'error', error
        .on 'finish', next

    return

# Coffee
gulp.task 'client:coffee', (next)->
    gulp.src paths.client.coffee.from
        # Source map
        .pipe if $isProduction then gutil.noop() else sourcemaps.init()
        # Рендер Coffee
        .pipe coffee({bare: true}).on 'error', error
        # Минификация
        .pipe uglify()
        # Переименование
        .pipe rename {
            suffix: paths.client.coffee.suffix
        }
        # Сохранение Source Map
        .pipe if $isProduction then gutil.noop() else sourcemaps.write("./")
        # Сохранение
        .pipe gulp.dest paths.client.coffee.to
        .on 'error', error
        .on 'finish', next
        
    return

# JS
gulp.task 'client:js', (next)->
    gulp.src paths.client.js.from
        # Source map
        .pipe if $isProduction then gutil.noop() else sourcemaps.init()
        # Минификация
        .pipe uglify()
        # Переименование
        .pipe rename {
            suffix: paths.client.js.suffix
        }
        # Сохринение Source Map
        .pipe if $isProduction then gutil.noop() else sourcemaps.write("./")
        # Сохранение
        .pipe gulp.dest paths.client.js.to
        .on 'error', error
        .on 'finish', next

    return

# Картинки
gulp.task 'client:images', (next)->
    gulp.src paths.client.images.from
        # Минификация
        .pipe imagemin {
            progressive: true
            # svgoPlugins: [
            #     removeViewBox: false
            # ]
            use: [
                jpegtran()
                pngquant()
                gifsicle()
            ]
        }
        # Сохранение
        .pipe gulp.dest paths.client.images.to
        .on 'error', error
        .on 'finish', next

    return

# Копирование
gulp.task 'client:copy', (next)->
    gulp.src paths.client.copy.from
        # Сохранение
        .pipe gulp.dest paths.client.copy.to
        .on 'error', error
        .on 'finish', next
    
    return

gulp.task 'client:templates', (next)->
    gulp.src paths.client.templates.from
        # Сохранение
        .pipe gulp.dest paths.client.templates.to
        .on 'error', error
        .on 'finish', next
    
    return

###
-------------------------------------
Сервер
-------------------------------------
###
# Coffee
gulp.task 'development:coffee', (next)->
    gulp.src paths.server.coffee.from
        # Рендер Coffee
        .pipe coffee({bare: true}).on 'error', error
        # Сохранение
        .pipe gulp.dest paths.server.coffee.to
        .on 'error', error
        .on 'finish', next

    return

# Cson
gulp.task 'development:cson', (next)->
    gulp.src paths.server.cson.from
        # Рендер Cson
        .pipe cson().on 'error', error
        .pipe gulp.dest paths.server.cson.to
        .on 'error', error
        .on 'finish', next

    return

###
-------------------------------------
General
-------------------------------------
###
# Документация
gulp.task 'general:jsdoc', (next)->
    gulp.src paths.general.jsdoc.from
        # Рендер Cson
        .pipe jsdoc.parser().on 'error', error

        # Сохраниение в формате JSON
        # .pipe gulp.dest paths.general.jsdoc.to
        # Рендер в HTML документ
        .pipe jsdoc.generator paths.general.jsdoc.to
        .on 'error', error
        .on 'finish', next
    
    return

# Удаление сборки
gulp.task 'general:clean', (next)->
    gulp.src paths.general.clean.from, {read: false}
        # Удаление всего
        .pipe clean()
        .on 'error', error
        .on 'finish', next

    return

# Backup
gulp.task 'general:backup', (next)->
    time = new Date().getTime()
    version = getPackageVersion()

    gulp.src paths.general.backup.from, { base: './' }
        .pipe zip "bu-#{version}-#{time}.zip"
        .pipe gulp.dest paths.general.backup.to
        .on 'error', error
        .on 'finish', next

    return

gulp.task 'general:backup:cron', (next)->
    new CronJob getCronTime times.backup, ->
        console.log "#{colors.green '[CRON]'} Start make backup"
        gulp.start 'general:backup'
    , null, true, "America/Los_Angeles"

    next()
    return

# Release
gulp.task 'general:release', (next)->
    time = new Date().getTime()
    version = getPackageVersion()

    gulp.src paths.general.release.from, { base: './' }
        .pipe zip "release-#{version}-#{time}.zip"
        .pipe gulp.dest paths.general.release.to
        .on 'error', error
        .on 'finish', next
    
    return

###
-------------------------------------
Test
-------------------------------------
###
# Mocha
gulp.task 'test:mocha', (next)->
    gulp.src paths.general.test.from, {read: false}
        .pipe mocha {
            reporter: 'nyan'
            timeout: 2
        }
        .on 'error', error
        # .on 'finish', next
        
    next()

###
-------------------------------------
Settings
-------------------------------------
###
gulp.task 'settings:release', (next)->
    gutil.log gutil.colors.green "Switched to production settings"

    $isProduction = true

    next()

###
-------------------------------------
Watch
-------------------------------------
###
# Server
gulp.task 'watch:development:coffee', ->
    gulp.watch paths.server.coffee.from, gulpsync.sync [
        'development:coffee'
    ]
gulp.task 'watch:development:cson', ->
    gulp.watch paths.server.cson.from, gulpsync.sync [
        'development:cson'
    ]

# Client
gulp.task 'watch:client:coffee', ->
    gulp.watch paths.client.coffee.from, gulpsync.sync [
        'client:coffee'
    ]
gulp.task 'watch:client:js', ->
    gulp.watch paths.client.js.from, gulpsync.sync [
        'client:js'
    ]
gulp.task 'watch:client:styles', ->
    gulp.watch paths.client.styles.from, gulpsync.sync [
        'client:styles'
    ]
gulp.task 'watch:client:copy', ->
    gulp.watch paths.client.copy.from , gulpsync.sync [
        'client:copy'
    ]
gulp.task 'watch:client:templates', ->
    gulp.watch paths.client.templates.from , gulpsync.sync [
        'client:templates'
    ]
gulp.task 'watch:client:images', ->
    gulp.watch paths.client.images.from, gulpsync.sync [
        'client:images'
    ]

# General
gulp.task 'watch:test:mocha', ->
    gulp.watch paths.general.test.from, gulpsync.sync [
        'test:mocha'
    ]

gulp.task 'watch:general:jsdoc', ->
    gulp.watch paths.general.jsdoc.from, gulpsync.sync [
        'general:jsdoc'
    ]

# Parent
gulp.task 'development', gulpsync.async [
    'development:coffee'
    'development:cson'
]

gulp.task 'client', gulpsync.async [
    'client:coffee'
    'client:js'
    'client:styles'
    'client:copy'
    'client:templates'
    'client:images'
]

gulp.task 'general', gulpsync.async [
    # 'general:jsdoc'
    'general:clean'
    'general:backup'
    'general:release'
]

gulp.task 'test', gulpsync.async [
    'test:mocha'
]

gulp.task 'watch', gulpsync.async [
    'watch:development:coffee'
    'watch:development:cson'

    # 'watch:client:coffee'
    # 'watch:client:js'
    # 'watch:client:styles'
    # 'watch:client:copy'
    # 'watch:client:templates'
    # 'watch:client:images'

    # 'watch:test:mocha'
    # 'watch:general:jsdoc'
]

# Init
gulp.task 'build', gulpsync.sync [
    # 'general:backup'
    'general:clean'

    [
        'development'
        # 'client'
    ]
]

gulp.task 'release', gulpsync.sync [
    'settings:release'
    
    'build'
    'general:release'
]

gulp.task 'default', gulpsync.sync [
    'build'
    'general:backup:cron'
    'watch'
]
