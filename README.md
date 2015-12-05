# Lagoon.js

## Installation
```sh
npm install lagoonjs --save
```

-------------------------

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

-------------------------

## API
### Lagoon
* **opts** {`Object`}

```coffee
opts:
    settings:
            log:
                use:        true
                colors:     "yellow"
                background: false
                text:       "log"
                trace:      false
            info:
                use:        true
                colors:     "gray"
                background: false
                text:       "info"
                trace:      false
            warn:
                use:        true
                colors:     "cyan"
                background: false
                text:       "warn"
                trace:      false
            error:
                use:        true
                colors:     "red"
                background: false
                text:       "error"
                trace:      false
            fatal:
                use:        true
                colors:     "white"
                background: "bgRed"
                text:       "fatal"
                trace:      true
            debug:
                use:        true
                colors:     "magenta"
                background: false
                text:       "debug"
                trace:      false
            time:
                use:        true
                colors:     "grey"
                background: false
                text:       "time"
                trace:      false
    transports:
        console:
            use:    true
        file:
            use:    false
            path:   "./logs/"
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

-------------------------

### Lagoon#time
* **label** {`String`}

### Lagoon#timeEnd
* **label** {`String`}
* **show** {`Boolean`} - if `true`, then prints delta time to stdout with newline. Else return delta time in *ms*.

* **return** {`Number`} - if **show** is *true*

-------------------------

### Lagoon#assert
Default console method `console.assert`

### Lagoon#dir
Default console method `console.dir`

### Lagoon#trace
Default console method `console.trace`