# Lagoon.js

## Usage
```coffee
Lagoon  = require 'Lagoon'
logger  = new Lagoon()

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
```
