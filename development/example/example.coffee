lagoon  = require '../lagoon'
logger  = new lagoon.Lagoon()

logger.on "logger", (level, args)->
    console.log level, args

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

lagoon.log 'Default logger', '+'
logger.log 'Created logger', '+'