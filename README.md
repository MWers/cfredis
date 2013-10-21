# cfredis #

cfredis is a ColdFusion client for [Redis](http://redis.io/). It acts as a wrapper for the excellent [Jedis](https://github.com/xetorthio/jedis/) Java client for [Redis](http://redis.io/).

## Configuring cfredis ##

To use cfredis, first download Jedis and place it somewhere within your ColdFusion classpath like `[CFHOME]/lib` (or better yet, use JavaLoader to include it):

<https://github.com/xetorthio/jedis/downloads>

Jedis depends on [Apache Commons Pool](http://commons.apache.org/proper/commons-pool/download_pool.cgi) which should also be downloaded and added to your ColdFusion classpath or included via JavaLoader.

Then place the following initialization code in the `OnApplicationStart` method in `Application.cfc`, in `OnRequestStart.cfm`, or in `Application.cfm`:

```cfm
<cfscript>
this.redisHost = "localhost";
this.redisPort = 6379;

// Set connection pool configuration
this.jedisPoolConfig = CreateObject("java", "redis.clients.jedis.JedisPoolConfig");
this.jedisPoolConfig.init();
this.jedisPoolConfig.testOnBorrow = false;
this.jedisPoolConfig.testOnReturn = false;
this.jedisPoolConfig.testWhileIdle = true;
this.jedisPoolConfig.maxActive = 100;
this.jedisPoolConfig.maxIdle = 5;
this.jedisPoolConfig.numTestsPerEvictionRun = 10;
this.jedisPoolConfig.timeBetweenEvictionRunsMillis = 10000;
this.jedisPoolConfig.maxWait = 3000;

this.jedisPool = CreateObject("java", "redis.clients.jedis.JedisPool");
this.jedisPool.init(this.jedisPoolConfig, this.redisHost, this.redisPort);

// The "cfc.cfredis" component name will change depending on where you put cfredis
application.redis = CreateObject("component", "cfc.cfredis").init();
application.redis.connectionPool = this.jedisPool;
</cfscript>
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
