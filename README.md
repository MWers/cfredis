# cfredis #

cfredis is a ColdFusion client for [Redis](http://redis.io/). It acts as a wrapper for [Jedis](https://github.com/xetorthio/jedis/), a Java client for [Redis](http://redis.io/). It has been tested on ColdFusion 8, ColdFusion 9, and ColdFusion 10.

## Configuring cfredis ##

### Installing Dependencies ###
cfredis requires [Jedis](https://github.com/xetorthio/jedis/) and [Apache Commons Pool](http://commons.apache.org/proper/commons-pool/), specifically [jedis-2.1.0.jar](https://github.com/downloads/xetorthio/jedis/jedis-2.1.0.jar) and [commons-pool-1.6-bin.tar.gz](http://www.bizdirusa.com/mirrors/apache//commons/pool/binaries/commons-pool-1.6-bin.tar.gz). 

Within the `commons-pool-1.6-bin.tar.gz` archive, you will find `commons-pool-1.6.jar`. Copy `jedis-2.1.0.jar` and `commons-pool-1.6.jar` to `_cfroot_/lib` and restart ColdFusion. You may also use [JavaLoader](https://github.com/markmandel/JavaLoader) to include `jedis-2.1.0.jar` and `commons-pool-1.6.jar`.

### Installing the CFC ###

Copy [src/cfc/cfredis.cfc](https://github.com/MWers/cfredis/blob/master/src/cfc/cfredis.cfc) to wherever you store your CFCs or clone the cfredis repository into your webroot.

### Initializing cfredis ###

Place the following initialization code in the `OnApplicationStart` method in `Application.cfc`, in `Application.cfm`, or in `OnRequestStart.cfm`:

```cfm
<cfscript>
local.redisHost = "localhost";  // redis server hostname or ip address
local.redisPort = 6379;         // redis server ip address

// Configure connection pool
local.jedisPoolConfig = CreateObject("java", "redis.clients.jedis.JedisPoolConfig");
local.jedisPoolConfig.init();
local.jedisPoolConfig.testOnBorrow = false;
local.jedisPoolConfig.testOnReturn = false;
local.jedisPoolConfig.testWhileIdle = true;
local.jedisPoolConfig.maxActive = 100;
local.jedisPoolConfig.maxIdle = 5;
local.jedisPoolConfig.numTestsPerEvictionRun = 10;
local.jedisPoolConfig.timeBetweenEvictionRunsMillis = 10000;
local.jedisPoolConfig.maxWait = 3000;

local.jedisPool = CreateObject("java", "redis.clients.jedis.JedisPool");
local.jedisPool.init(local.jedisPoolConfig, local.redisHost, local.redisPort);

// The "cfc.cfredis" component name will change depending on where you put cfredis
local.redis = CreateObject("component", "cfc.cfredis").init();
local.redis.connectionPool = local.jedisPool;
</cfscript>

<cflock scope="Application" type="exclusive" timeout="10">
    <cfset application.redis = local.redis />
</cflock>
```

## Using cfredis ##

Use the `application.redis` object to execute Redis commands:

```cfm
<cfset application.redis.set("your:key:name", "key value") />
<cfset value = application.redis.get("your:key:name") />
```

## Examples ##

I've included a number of [examples](https://github.com/MWers/cfredis/tree/master/examples) using cfredis.

## Redis Commands ##

* [Redis Command Reference](http://redis.io/commands)
* [Jedis Command Reference](http://www.ostools.net/uploads/apidocs/jedis-2.1.0/redis/clients/jedis/Commands.html)

cfredis implements all of the Redis methods implemented in redis.clients.jedis.Jedis with the following changes:

* `ltrim` has been renamed to `_ltrim` to avoid conflicts with the built-in CF function `LTrim()`

* The following overloaded Jedis methods have been combined to singular CF methods:
    * `sort`
    * `zinterstore`
    * `zrangeByScore`
    * `zrangeByScoreWithScores`
    * `zrevrangeByScore`
    * `zrevrangeByScoreWithScores`
    * `zunionstore`

* Transactions and Pipelining are not yet supported

## Support ##

If you have any problems with cfredis, please submit an issue:

<https://github.com/MWers/cfredis/issues>

## How To Help ##

If you'd like to help to make cfredis better, please fork this project and submit a pull request. A great place to start would be in creating MXUnit tests. They can be based on the Jedis JUnit tests here:

<https://github.com/xetorthio/jedis/tree/master/src/test/java/redis/clients/jedis/tests>

Thanks!
