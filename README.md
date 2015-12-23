# Lagoon.js

## Installation
```sh
npm install lagoonjs --save
```

--------------------------------------------------------------------------------

## Usage
```coffee
lagoon  = require 'lagoonjs'
logger  = new lagoon.Lagoon() # Or use `lagoon`

logger.on "logger", (level, args)->
    console.log level, '+'

logger.log "It's log"
logger.info "It's info"
logger.warn "It's warn"
logger.error "It's error"
logger.fatal "It's fatal"
logger.debug "It's debug"

logger.time "First timer"
setTimeout ->
    logger.timeEnd "First timer"
, 500

logger.assert(1, 2)
logger.dir(logger)
logger.trace()

lagoon.log 'Default logger', '+' # <- `lagoon`
logger.log 'Created logger', '+'
```

--------------------------------------------------------------------------------

## Formatting filename
You can set dynamic filename with variables.

Default filename is set to: `"./logs/log-%date%.log"`.

That is, `%date%` will be replaced by the date in the `yyyy-mm-dd` format.
You can also set the variable names for folders.

**Variable**:
* `%date%`       - date in **yyyy.mm.dd** format
* `%timestamp%`  - date in **timestamp**
* `%level%`      - Level of **current log**

You can define your own variables:

```coffee
lagoon  = require 'lagoonjs'
logger  = new lagoon.Lagoon({
    transports:
        file:
            use:        true
            filename:   "./logs/log-%myVar%.log" # <- %myVar%

    variables:
        myVar: (LagoonLogger)-> Math.random() # <- LagoonLogger it's self `this` link to logger
})
```

--------------------------------------------------------------------------------

## API
### Lagoon
* **opts** {`Object`}

```coffee
opts:
    settings:
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
    transports:
        console:
            use:        true
        file:
            use:        false
            filename:   "./logs/log-%date%.log"

    variables:
        "date":         -> getData("file").formated
        "timestamp":    -> getData("timestamp").formated
```

### Lagoon#log
* **args...** {`Any`}

### Lagoon#info
* **args...** {`Any`}

### Lagoon#warn
* **args...** {`Any`}

### Lagoon#error
* **args...** {`Any`}

### Lagoon#fatal
* **args...** {`Any`}

### Lagoon#debug
* **args...** {`Any`}

--------------------------------------------------------------------------------

### Lagoon#time
* **label** {`String`}

### Lagoon#timeEnd
* **label** {`String`}
* **show** {`Boolean`} - if `true`, then prints delta time to stdout with newline. Else return delta time in *ms*.

* **return** {`Number`} - if **show** is *true*

--------------------------------------------------------------------------------

### Lagoon#assert
Default console method `console.assert`

### Lagoon#dir
Default console method `console.dir`

### Lagoon#trace
Default console method `console.trace`

--------------------------------------------------------------------------------

## Changelog
### 1.1.0 [`Stable`]
```diff
+ Formatting filename with variables
```

### 1.0.0 [`Stable`]
```diff
+ First realise
```
