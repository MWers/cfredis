# cfredis #

cfredis is a ColdFusion wrapper for the [Jedis](https://github.com/xetorthio/jedis/) Java client for [Redis](http://redis.io/).

To use cfredis, first download Jedis and place it somewhere within your ColdFusion classpath (or better yet, use JavaLoader to include it):

https://github.com/xetorthio/jedis/downloads

(Note: Jedis depends on [Apache Commons Pool](http://commons.apache.org/proper/commons-pool/download_pool.cgi) which should also be downloaded and added to your ColdFusion classpath or included via JavaLoader.)

Then place the following initialization code in the `OnRequestStart` method in `Application.cfc`, in `OnRequestStart.cfm`, or in `Application.cfm`:

```cfm
<cfset request.redis = CreateObject("component","cfredis").init() />
<cfset pool = CreateObject("java","redis.clients.jedis.JedisPool") />
<cfset pool.init("redis.server.hostname.or.ip.address", redis.port) />
<cfset request.redis.connectionPool = pool />
```

On a page where you wish to make a Redis connection, do so as follows:

```cfm
<cfset request.redis.set("your:key:name", "key value") />
<cfset value = request.redis.get("your:key:name") />
```

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

* Transactions and Pipelining are not yet supported.

If you have any problems with cfredis, please submit an issue:

https://github.com/MWers/cfredis/issues

If you'd like to help to make cfredis better, please fork this project and submit a pull request. A great place to start would be in creating MXUnit tests. They can be based on the Jedis JUnit tests here:

https://github.com/xetorthio/jedis/tree/master/src/test/java/redis/clients/jedis/tests

Thanks!
