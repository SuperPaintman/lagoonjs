var Benchmark, BenchmarkTimeConsole, BenchmarkTimeLagoon, lagoon, logger, suite;

Benchmark = require('benchmark');

lagoon = require('../lagoon');

suite = new Benchmark.Suite;

logger = new lagoon.Lagoon();

BenchmarkTimeConsole = new Benchmark('Console#time', {
  defer: true,
  fn: function(deferred) {
    console.time("$");
    return setTimeout(function() {
      console.timeEnd("$");
      return deferred.resolve();
    }, 1000);
  }
});

BenchmarkTimeLagoon = new Benchmark('Lagoon#time', {
  defer: true,
  fn: function(deferred) {
    logger.time("$");
    return setTimeout(function() {
      logger.timeEnd("$");
      return deferred.resolve();
    }, 1000);
  }
});

suite.add(BenchmarkTimeConsole).add(BenchmarkTimeLagoon).on('cycle', function(event) {
  return logger.log(String(event.target));
}).on('complete', function() {
  return logger.log('Fastest is ' + this.filter('fastest').pluck('name'));
}).run({
  'initCount': 10,
  'async': false
});
