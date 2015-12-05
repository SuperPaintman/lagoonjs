# Requires
Benchmark   = require('benchmark')
lagoon      = require '../lagoon'


# Init
suite = new Benchmark.Suite

logger = new lagoon.Lagoon()

# Time
BenchmarkTimeConsole = new Benchmark 'Console#time', {
    defer: true
    fn: (deferred)->
        console.time("$")
        setTimeout ->
            console.timeEnd("$")
            deferred.resolve()
        , 1000
}

BenchmarkTimeLagoon = new Benchmark 'Lagoon#time', {
    defer: true
    fn: (deferred)->
        logger.time("$")
        setTimeout ->
            logger.timeEnd("$")
            deferred.resolve()
        , 1000
}

suite.add BenchmarkTimeConsole
     .add BenchmarkTimeLagoon
     .on 'cycle', (event)->
         logger.log String(event.target)
     .on 'complete', ->
         logger.log 'Fastest is ' + this.filter('fastest').pluck('name')
     .run { 
         'initCount': 10
         'async': false
     }