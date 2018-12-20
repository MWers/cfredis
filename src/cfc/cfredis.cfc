<!---
Copyright (c) 2011-2013 Matthew Walker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 --->

<!---
# cfredis #

cfredis is a ColdFusion wrapper for the
[Jedis](https://github.com/xetorthio/jedis/) Java client for
[Redis](http://redis.io/).

To use cfredis, first download Jedis and place it somewhere within your
ColdFusion classpath (or better yet, use JavaLoader to include it):

https://github.com/xetorthio/jedis/downloads

Jedis depends on
[Apache Commons Pool](http://commons.apache.org/proper/commons-pool/download_pool.cgi)
which should also be downloaded and added to your ColdFusion classpath or
included via JavaLoader.

Then place the following initialization code in the `OnRequestStart`
method in `Application.cfc`, in `OnRequestStart.cfm`, or in `Application.cfm`:

<cfset request.redis = CreateObject("component","cfredis").init() />
<cfset pool = CreateObject("java","redis.clients.jedis.JedisPool") />
<cfset pool.init("redis.server.hostname.or.ip.address", redis.port) />
<cfset request.redis.connectionPool = pool />

On a page where you wish to make a Redis connection, do so as follows:

<cfset request.redis.set("your:key:name", "key value") />
<cfset value = request.redis.get("your:key:name") />

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

If you'd like to help to make cfredis better, please fork this project
and submit a pull request. A great place to start would be in creating
MXUnit tests. They can be based on the Jedis JUnit tests here:

https://github.com/xetorthio/jedis/tree/master/src/test/java/redis/clients/jedis/tests

Thanks!
--->

<cfcomponent name="cfredis" displayname="Redis Controller" hint="This CFC handles communication with Redis">

    <cfset this.connectionPool = "">

    <cffunction name="init" access="public" returntype="Any" output="no">
        <cfreturn this>
    </cffunction>

    <cffunction name="getResource" access="private" returntype="Any" output="no">
        <cfreturn this.connectionPool.getResource()>
    </cffunction>

    <cffunction name="returnResource" access="private" returntype="Any" output="no">
        <cfargument name="connection" required="yes">

        <cfset this.connectionPool.returnResource(arguments.connection)>

        <cfreturn>
    </cffunction>


    <!--- APPEND - Long append(String key, String value) --->
    <cffunction name="append" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.append(JavaCast("string", arguments.key), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- AUTH - String auth(String password) --->
    <!--- It's advised to set server password when creating the JedisPool instance rather than using AUTH --->
    <cffunction name="auth" access="public" returntype="string" output="no">
        <cfargument name="password" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.auth(JavaCast("string", arguments.password)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- FIXME: Add the following new functions --->
    <!--- BITCOUNT - Long bitcount(final String key) --->
    <!--- BITCOUNT - Long bitcount(final String key, long start, long end) --->
    <!--- BITOP - Long bitop(BitOP op, final String destKey, String... srcKeys) --->


    <!--- BLPOP - List<String> blpop(int timeout, String... keys) --->
    <cffunction name="blpop" access="public" returntype="array" output="no">
        <cfargument name="timeout" type="numeric" required="yes" />
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the blpop method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.blpop(JavaCast("int", arguments.timeout), JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- BRPOP - List<String> brpop(int timeout, String... keys) --->
    <cffunction name="brpop" access="public" returntype="array" output="no">
        <cfargument name="timeout" type="numeric" required="yes" />
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the brpop method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.brpop(JavaCast("int", arguments.timeout), JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- BRPOPLPUSH - String brpoplpush(String source, String destination, int timeout) --->
    <cffunction name="brpoplpush" access="public" returntype="string" output="no">
        <cfargument name="source" type="string" required="yes" />
        <cfargument name="destination" type="string" required="yes" />
        <cfargument name="timeout" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.brpoplpush(JavaCast("string", arguments.source), JavaCast("string", arguments.destination), JavaCast("int", arguments.timeout)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- DBSIZE - Long dbSize() --->
    <cffunction name="dbSize" access="public" returntype="numeric" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.dbSize() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- DECR - Long decr(String key) --->
    <cffunction name="decr" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.decr(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- DECRBY - Long decrBy(String key, long integer) --->
    <cffunction name="decrBy" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="integer" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.decrBy(JavaCast("string", arguments.key), JavaCast("long", arguments.integer)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- DEL - Long del(String... keys) --->
    <cffunction name="del" access="public" returntype="numeric" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var key = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <!--- Iterate over array copying it to a new array. This prevents the error that we get
                  when using the result of a Redis call as the argument to another. --->
            <cfloop array="#arguments.keys#" index="key">
                <cfset ArrayAppend(keysArray, key) />
            </cfloop>
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the del method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.del(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ECHO - String echo(String string) --->
    <cffunction name="echo" access="public" returntype="string" output="no">
        <cfargument name="string" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.echo(JavaCast("string", arguments.string)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- EVAL - Object eval(String script) --->
    <!--- EVAL - Object eval(String script, List<String> keys, List<String> args) --->
    <!--- It should be used as eval(script) or eval(script, keys, args) --->
    <cffunction name="eval" access="public" returntype="any" output="no">
        <cfargument name="script" type="string" required="yes" />
        <cfargument name="keys" type="array" required="no" default="#ArrayNew(1)#" />
        <cfargument name="args" type="array" required="no" default="#ArrayNew(1)#" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.eval(JavaCast("string", arguments.script), arguments.keys, arguments.args) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- TODO: Create function to eval with keyCount and params args --->
    <!--- EVAL - Object eval(String script, int keyCount, String... params) --->
    <!--- It should be used as eval(script, keyCount, params) --->


    <!--- EVALSHA - Object evalsha(String sha1) --->
    <!--- EVALSHA - Object evalsha(String sha1, List<String> keys, List<String> args) --->
    <!--- It should be used as evalsha(script) or evalsha(script, keys, args) --->
    <cffunction name="evalsha" access="public" returntype="any" output="no">
        <cfargument name="sha1" type="string" required="yes" />
        <cfargument name="keys" type="array" required="no" default="#ArrayNew(1)#" />
        <cfargument name="args" type="array" required="no" default="#ArrayNew(1)#" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.evalsha(JavaCast("string", arguments.sha1), arguments.keys, arguments.args) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- TODO: Create function to evalsha with keyCount and params args --->
    <!--- EVALSHA - Object evalsha(String script, int keyCount, String... params) --->
    <!--- It should be used as evalsha(script, keyCount, params) --->


    <!--- EXISTS - Boolean exists(String key) --->
    <cffunction name="exists" access="public" returntype="boolean" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.exists(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- EXPIRE - Long expire(String key, int seconds) --->
    <cffunction name="expire" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="seconds" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.expire(JavaCast("string", arguments.key), JavaCast("int", arguments.seconds)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- EXPIREAT - Long expireAt(String key, long unixTime) --->
    <cffunction name="expireAt" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="unixTime" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.expireAt(JavaCast("string", arguments.key), JavaCast("long", arguments.unixTime)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- FLUSHALL - String flushAll() --->
    <cffunction name="flushAll" access="public" returntype="string" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.flushAll() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- FLUSHDB - String flushDB() --->
    <cffunction name="flushDB" access="public" returntype="string" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.flushDB() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- GET - String get(String key) --->
    <cffunction name="get" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.get(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- GETSET - String getSet(String key, String value) --->
    <cffunction name="getSet" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.getSet(JavaCast("string", arguments.key), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- GETBIT - boolean getbit(String key, long offset) --->
    <cffunction name="getbit" access="public" returntype="boolean" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="offset" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.getbit(JavaCast("string", arguments.key), JavaCast("long", arguments.offset)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- GETRANGE - String getrange(String key, long startOffset, long endOffset) --->
    <cffunction name="getrange" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="startOffset" type="numeric" required="yes" />
        <cfargument name="endOffset" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.getrange(JavaCast("string", arguments.key), JavaCast("long", arguments.startOffset), JavaCast("long", arguments.endOffset)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- HDEL - Long hdel(final String key, final String... fields) --->
    <cffunction name="hdel" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="fields" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var fieldsArray = '' />
        <cfset var field = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset fieldsArray = ArrayNew(1) />
        <cfif isArray(arguments.fields)>
            <!--- Iterate over array copying it to a new array. This prevents the error that we get
                  when using the result of a Redis call as the argument to another. --->
            <cfloop array="#arguments.fields#" index="field">
                <cfset ArrayAppend(fieldsArray, field) />
            </cfloop>
        <cfelseif isSimpleValue(arguments.fields)>
            <cfset ArrayAppend(fieldsArray, arguments.fields) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(fieldsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The fields argument passed to the hdel method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.hdel(JavaCast("string", arguments.key), JavaCast("string[]", fieldsArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- HEXISTS - Boolean hexists(String key, String field) --->
    <cffunction name="hexists" access="public" returntype="boolean" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="field" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hexists(JavaCast("string", arguments.key), JavaCast("string", arguments.field)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- HGET - String hget(String key, String field) --->
    <cffunction name="hget" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="field" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hget(JavaCast("string", arguments.key), JavaCast("string", arguments.field)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- HGETALL - Map<String,String> hgetAll(String key) --->
    <cffunction name="hgetAll" access="public" returntype="struct" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hgetAll(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn StructNew() />
        </cfif>
    </cffunction>


    <!--- HINCRBY - Long hincrBy(String key, String field, long value) --->
    <cffunction name="hincrBy" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="field" type="string" required="yes" />
        <cfargument name="value" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hincrBy(JavaCast("string", arguments.key), JavaCast("string", arguments.field), JavaCast("long", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- HKEYS - Set<String> hkeys(String key) --->
    <cffunction name="hkeys" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hkeys(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- HLEN - Long hlen(String key) --->
    <cffunction name="hlen" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hlen(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- HMGET - List<String> hmget(String key, String... fields) --->
    <cffunction name="hmget" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="fields" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var fieldsArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset fieldsArray = ArrayNew(1) />
        <cfif isArray(arguments.fields)>
            <cfset fieldsArray = arguments.fields />
        <cfelseif isSimpleValue(arguments.fields)>
            <cfset ArrayAppend(fieldsArray, arguments.fields) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(fieldsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The fields argument passed to the hmget method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.hmget(JavaCast("string", arguments.key), JavaCast("string[]", fieldsArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- HMSET - String hmset(String key, Map hash) --->
    <cffunction name="hmset" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="hash" type="struct" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hmset(JavaCast("string", arguments.key), arguments.hash) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- HSET - Long hset(String key, String field, String value) --->
    <cffunction name="hset" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="field" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hset(JavaCast("string", arguments.key), JavaCast("string", arguments.field), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- HSETNX - Long hsetnx(String key, String field, String value) --->
    <cffunction name="hsetnx" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="field" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hsetnx(JavaCast("string", arguments.key), JavaCast("string", arguments.field), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- HVALS - List<String> hvals(String key) --->
    <cffunction name="hvals" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.hvals(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- INCR - Long incr(String key) --->
    <cffunction name="incr" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.incr(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- INCRBY - Long incrBy(String key, long integer) --->
    <cffunction name="incrBy" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="integer" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.incrBy(JavaCast("string", arguments.key), JavaCast("long", arguments.integer)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- KEYS - Set<String> keys(String pattern) --->
    <cffunction name="keys" access="public" returntype="array" output="no">
        <cfargument name="pattern" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.keys(JavaCast("string", arguments.pattern)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- LINDEX - String lindex(String key, long index) --->
    <cffunction name="lindex" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="index" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lindex(JavaCast("string", arguments.key), JavaCast("long", arguments.index)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- LINSERT - Long linsert(String key, LIST_POSITION where, String pivot, String value) --->
    <cffunction name="linsert" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="where" type="any" required="yes" />
        <cfargument name="pivot" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.linsert(JavaCast("string", arguments.key), arguments.where, JavaCast("string", arguments.pivot), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- LLEN - Long llen(String key) --->
    <cffunction name="llen" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.llen(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- LPOP - String lpop(String key) --->
    <cffunction name="lpop" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lpop(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>

    <!--- LPUSH - Long lpush(String key, String string) --->
    <cffunction name="lpush" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="string" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var stringArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset stringArray = ArrayNew(1) />
        <cfif isArray(arguments.string)>
            <cfset stringArray = arguments.string />
        <cfelseif isSimpleValue(arguments.string)>
            <cfset ArrayAppend(stringArray, arguments.string) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(stringArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The string argument passed to the rpush method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.lpush(JavaCast("string", arguments.key), JavaCast("string[]", stringArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>

    <!--- FIXME: Change to use format Long lpushx(final String key, final String... string) --->
    <!--- LPUSHX - Long lpushx(String key, String string) --->
    <cffunction name="lpushx" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="string" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lpushx(JavaCast("string", arguments.key), JavaCast("string", arguments.string)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- LRANGE - List<String> lrange(String key, long start, long end) --->
    <cffunction name="lrange" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lrange(JavaCast("string", arguments.key), JavaCast("long", arguments.start), JavaCast("long", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- LREM - Long lrem(String key, long count, String value) --->
    <cffunction name="lrem" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="count" type="numeric" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lrem(JavaCast("string", arguments.key), JavaCast("long", arguments.count), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- LSET - String lset(String key, long index, String value) --->
    <cffunction name="lset" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="index" type="numeric" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.lset(JavaCast("string", arguments.key), JavaCast("long", arguments.index), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- LTRIM - String ltrim(String key, long start, long end) --->
    <!--- Original redis command prefixed with '_' to avoid conflict with builtin CF function --->
    <cffunction name="_ltrim" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.ltrim(JavaCast("string", arguments.key), JavaCast("long", arguments.start), JavaCast("long", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- MGET - List<String> mget(String... keys) --->
    <cffunction name="mget" access="public" returntype="array" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the mget method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.mget(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- MOVE - Long move(String key, int dbIndex) --->
    <cffunction name="move" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="dbIndex" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.move(JavaCast("string", arguments.key), JavaCast("int", arguments.dbIndex)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- MSET - String mset(String... keysvalues) --->
    <cffunction name="mset" access="public" returntype="string" output="no">
        <cfargument name="keysvalues" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysvaluesArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysvaluesArray = ArrayNew(1) />
        <cfif isArray(arguments.keysvalues)>
            <cfset keysvaluesArray = arguments.keysvalues />
        <cfelseif isSimpleValue(arguments.keysvalues)>
            <cfset ArrayAppend(keysvaluesArray, arguments.keysvalues) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysvaluesArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keysvalues argument passed to the mset method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.mset(JavaCast("string[]", keysvaluesArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- MSETNX - Long msetnx(String... keysvalues) --->
    <cffunction name="msetnx" access="public" returntype="numeric" output="no">
        <cfargument name="keysvalues" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysvaluesArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysvaluesArray = ArrayNew(1) />
        <cfif isArray(arguments.keysvalues)>
            <cfset keysvaluesArray = arguments.keysvalues />
        <cfelseif isSimpleValue(arguments.keysvalues)>
            <cfset ArrayAppend(keysvaluesArray, arguments.keysvalues) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysvaluesArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keysvalues argument passed to the msetnx method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.msetnx(JavaCast("string[]", keysvaluesArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- MULTI - Transaction multi() --->
    <cffunction name="multi" access="public" returntype="Any" output="no">
        <cfset var trans = '' />

        <cfset trans = CreateObject("component","cfredis_transaction").init() />
        <cfset trans.transaction = getResource().multi() />

        <cfreturn trans />
    </cffunction>


    <!--- PERSIST - Long persist(String key) --->
    <cffunction name="persist" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.persist(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- PING - String ping() --->
    <cffunction name="ping" access="public" returntype="string" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.ping() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- PIPELINED - Pipeline pipelined() --->
    <cffunction name="pipelined" access="public" returntype="Any" output="no">
        <cfset var pipe = '' />

        <cfset pipe = CreateObject("component","cfredis_pipeline").init() />
        <cfset pipe.pipeline = getResource().pipelined() />

        <cfreturn pipe />
    </cffunction>


    <!--- PSUBSCRIBE - void psubscribe(JedisPubSub jedisPubSub, String... patterns) --->
    <cffunction name="psubscribe" access="public" returntype="void" output="no">
        <cfargument name="jedisPubSub" type="any" required="yes" />
        <cfargument name="patterns" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var patternsArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset patternsArray = ArrayNew(1) />
        <cfif isArray(arguments.patterns)>
            <cfset patternsArray = arguments.patterns />
        <cfelseif isSimpleValue(arguments.patterns)>
            <cfset ArrayAppend(patternsArray, arguments.patterns) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(patternsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The patterns argument passed to the psubscribe method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.psubscribe(arguments.jedisPubSub, JavaCast("string[]", patternsArray)) />
        <cfset returnResource(connection) />

        <cfreturn />
    </cffunction>


    <!--- PUBLISH - Long publish(String channel, String message) --->
    <cffunction name="publish" access="public" returntype="numeric" output="no">
        <cfargument name="channel" type="string" required="yes" />
        <cfargument name="message" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.publish(JavaCast("string", arguments.channel), JavaCast("string", arguments.message)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- QUIT - String quit() --->
    <cffunction name="quit" access="public" returntype="string" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.quit() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- RANDOMKEY - String randomKey() --->
    <cffunction name="randomKey" access="public" returntype="string" output="no">

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.randomKey() />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- RENAME - String rename(String oldkey, String newkey) --->
    <cffunction name="rename" access="public" returntype="string" output="no">
        <cfargument name="oldkey" type="string" required="yes" />
        <cfargument name="newkey" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.rename(JavaCast("string", arguments.oldkey), JavaCast("string", arguments.newkey)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- RENAMENX - Long renamenx(String oldkey, String newkey) --->
    <cffunction name="renamenx" access="public" returntype="numeric" output="no">
        <cfargument name="oldkey" type="string" required="yes" />
        <cfargument name="newkey" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.renamenx(JavaCast("string", arguments.oldkey), JavaCast("string", arguments.newkey)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- RPOP - String rpop(String key) --->
    <cffunction name="rpop" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.rpop(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- RPOPLPUSH - String rpoplpush(String srckey, String dstkey) --->
    <cffunction name="rpoplpush" access="public" returntype="string" output="no">
        <cfargument name="srckey" type="string" required="yes" />
        <cfargument name="dstkey" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.rpoplpush(JavaCast("string", arguments.srckey), JavaCast("string", arguments.dstkey)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- RPUSH - Long rpush(String key, String string) --->
    <cffunction name="rpush" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="string" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var stringArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset stringArray = ArrayNew(1) />
        <cfif isArray(arguments.string)>
            <cfset stringArray = arguments.string />
        <cfelseif isSimpleValue(arguments.string)>
            <cfset ArrayAppend(stringArray, arguments.string) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(stringArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The string argument passed to the rpush method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.rpush(JavaCast("string", arguments.key), JavaCast("string[]", stringArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- FIXME: Change to use format Long rpushx(final String key, final String... string) --->
    <!--- RPUSHX - Long rpushx(String key, String string) --->
    <cffunction name="rpushx" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="string" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.rpushx(JavaCast("string", arguments.key), JavaCast("string", arguments.string)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SADD - Long sadd(String key, String member) --->
    <cffunction name="sadd" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var memberArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset memberArray = ArrayNew(1) />
        <cfif isArray(arguments.member)>
            <cfset memberArray = arguments.member />
        <cfelseif isSimpleValue(arguments.member)>
            <cfset ArrayAppend(memberArray, arguments.member) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(memberArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The member argument passed to the sadd method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sadd(JavaCast("string", arguments.key), JavaCast("string[]", memberArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SCARD - Long scard(String key) --->
    <cffunction name="scard" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.scard(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SCRIPTEXISTS - Boolean scriptExists(String sha1) --->
    <!--- SCRIPTEXISTS - List<Boolean> scriptExists(String... sha1) --->
    <!--- This method combines all scriptExists methods provided by Jedis --->
    <cffunction name="scriptexists" access="public" returntype="any" output="no">
        <cfargument name="sha1" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var sha1Array = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset sha1Array = ArrayNew(1) />
        <cfif isArray(arguments.sha1)>
            <cfset sha1Array = arguments.sha1 />
        <cfelseif isSimpleValue(arguments.sha1)>
            <cfset ArrayAppend(sha1Array, arguments.sha1) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(sha1Array, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The sha1 argument passed to the scriptexists method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.scriptexists(JavaCast("string[]", sha1Array)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- SCRIPTLOAD - String scriptLoad(String script) --->
    <cffunction name="scriptload" access="public" returntype="string" output="no">
        <cfargument name="script" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.scriptload(JavaCast("string", arguments.script)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SDIFF - Set<String> sdiff(String... keys) --->
    <cffunction name="sdiff" access="public" returntype="array" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sdiff method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sdiff(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- SDIFFSTORE - Long sdiffstore(String dstkey, String... keys) --->
    <cffunction name="sdiffstore" access="public" returntype="numeric" output="no">
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sdiffstore method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sdiffstore(JavaCast("string", arguments.dstkey), JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SELECT - String select(int index) --->
    <cffunction name="select" access="public" returntype="string" output="no">
        <cfargument name="index" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.select(JavaCast("int", arguments.index)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SET - String set(String key, String value) --->
    <cffunction name="set" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.set(JavaCast("string", arguments.key), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SETBIT - boolean setbit(String key, long offset, boolean value) --->
    <cffunction name="setbit" access="public" returntype="boolean" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="offset" type="numeric" required="yes" />
        <cfargument name="value" type="boolean" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.setbit(JavaCast("string", arguments.key), JavaCast("long", arguments.offset), JavaCast("boolean", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SETEX - String setex(String key, int seconds, String value) --->
    <cffunction name="setex" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="seconds" type="numeric" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.setex(JavaCast("string", arguments.key), JavaCast("int", arguments.seconds), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SETNX - Long setnx(String key, String value) --->
    <cffunction name="setnx" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.setnx(JavaCast("string", arguments.key), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SETRANGE - long setrange(String key, long offset, String value) --->
    <cffunction name="setrange" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="offset" type="numeric" required="yes" />
        <cfargument name="value" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.setrange(JavaCast("string", arguments.key), JavaCast("long", arguments.offset), JavaCast("string", arguments.value)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SINTER - Set<String> sinter(String... keys) --->
    <cffunction name="sinter" access="public" returntype="array" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sinter method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sinter(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- SINTERSTORE - Long sinterstore(String dstkey, String... keys) --->
    <cffunction name="sinterstore" access="public" returntype="numeric" output="no">
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sinterstore method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sinterstore(JavaCast("string", arguments.dstkey), JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SISMEMBER - Boolean sismember(String key, String member) --->
    <cffunction name="sismember" access="public" returntype="boolean" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.sismember(JavaCast("string", arguments.key), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SMEMBERS - Set<String> smembers(String key) --->
    <cffunction name="smembers" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.smembers(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- SMOVE - Long smove(String srckey, String dstkey, String member) --->
    <cffunction name="smove" access="public" returntype="numeric" output="no">
        <cfargument name="srckey" type="string" required="yes" />
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.smove(JavaCast("string", arguments.srckey), JavaCast("string", arguments.dstkey), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SORT - List<String> sort(String key) --->
    <!--- SORT - List<String> sort(String key, SortingParams sortingParameters) --->
    <!--- SORT - Long sort(String key, String dstkey) --->
    <!--- SORT - Long sort(String key, SortingParams sortingParameters, String dstkey) --->
    <!--- This method combines all four sort methods provided by Jedis --->
    <cffunction name="sort" access="public" returntype="any" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="sortingParameters" type="any" required="no" />
        <cfargument name="dstkey" type="string" required="no" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.sortingParameters") AND IsDefined("arguments.dstkey")>
            <cfset result = connection.sort(JavaCast("string", arguments.key), arguments.sortingParameters, JavaCast("string", arguments.dstkey)) />
        <cfelseif IsDefined("arguments.sortingParameters")>
            <cfset result = connection.sort(JavaCast("string", arguments.key), arguments.sortingParameters) />
        <cfelseif IsDefined("arguments.dstkey")>
            <cfset result = connection.sort(JavaCast("string", arguments.key), JavaCast("string", arguments.dstkey)) />
        <cfelse>
            <cfset result = connection.sort(JavaCast("string", arguments.key)) />
        </cfif>
        <cfset returnResource(connection) />

        <!--- If dstkey is defined, method returns numeric, otherwise it returns array --->
        <cfif IsDefined("arguments.dstkey")>
            <cfif isDefined("result")>
                <cfreturn result />
            <cfelse>
                <cfreturn 0 />
            </cfif>
        <cfelse>
            <cfif isDefined("result")>
                <cfreturn result.toArray() />
            <cfelse>
                <cfreturn ArrayNew(1) />
            </cfif>
        </cfif>
    </cffunction>


    <!--- SPOP - String spop(String key) --->
    <cffunction name="spop" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.spop(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SRANDMEMBER - String srandmember(String key) --->
    <cffunction name="srandmember" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.srandmember(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SREM - Long srem(String key, String member) --->
    <cffunction name="srem" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var memberArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset memberArray = ArrayNew(1) />
        <cfif isArray(arguments.member)>
            <cfset memberArray = arguments.member />
        <cfelseif isSimpleValue(arguments.member)>
            <cfset ArrayAppend(memberArray, arguments.member) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(memberArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The member argument passed to the srem method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.srem(JavaCast("string", arguments.key), JavaCast("string[]", memberArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- STRLEN - Long strlen(String key) --->
    <cffunction name="strlen" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.strlen(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- SUBSCRIBE - void subscribe(JedisPubSub jedisPubSub, String... channels) --->
    <cffunction name="subscribe" access="public" returntype="void" output="no">
        <cfargument name="jedisPubSub" type="any" required="yes" />
        <cfargument name="channels" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var channelsArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset channelsArray = ArrayNew(1) />
        <cfif isArray(arguments.channels)>
            <cfset channelsArray = arguments.channels />
        <cfelseif isSimpleValue(arguments.channels)>
            <cfset ArrayAppend(channelsArray, arguments.channels) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(channelsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The channels argument passed to the subscribe method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.subscribe(arguments.jedisPubSub, JavaCast("string[]", channelsArray)) />
        <cfset returnResource(connection) />

        <cfreturn />
    </cffunction>


    <!--- SUBSTR - String substr(String key, int start, int end) --->
    <cffunction name="substr" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.substr(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- SUNION - Set<String> sunion(String... keys) --->
    <cffunction name="sunion" access="public" returntype="array" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sunion method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sunion(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- SUNIONSTORE - Long sunionstore(String dstkey, String... keys) --->
    <cffunction name="sunionstore" access="public" returntype="numeric" output="no">
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 2 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the sunionstore method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.sunionstore(JavaCast("string", arguments.dstkey), JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- TTL - Long ttl(String key) --->
    <cffunction name="ttl" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.ttl(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- TYPE - String type(String key) --->
    <cffunction name="type" access="public" returntype="string" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.type(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- WATCH - String watch(String... keys) --->
    <cffunction name="watch" access="public" returntype="string" output="no">
        <cfargument name="keys" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var keysArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 1 />

        <cfset keysArray = ArrayNew(1) />
        <cfif isArray(arguments.keys)>
            <cfset keysArray = arguments.keys />
        <cfelseif isSimpleValue(arguments.keys)>
            <cfset ArrayAppend(keysArray, arguments.keys) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(keysArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The keys argument passed to the watch method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfset result = connection.watch(JavaCast("string[]", keysArray)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn '' />
        </cfif>
    </cffunction>


    <!--- ZADD - Long zadd(String key, double score, String member) --->
    <cffunction name="zadd" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="score" type="numeric" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zadd(JavaCast("string", arguments.key), JavaCast("double", arguments.score), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZCARD - Long zcard(String key) --->
    <cffunction name="zcard" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zcard(JavaCast("string", arguments.key)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZCOUNT - Long zcount(String key, double min, double max) --->
    <cffunction name="zcount" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="min" type="numeric" required="yes" />
        <cfargument name="max" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zcount(JavaCast("string", arguments.key), JavaCast("double", arguments.min), JavaCast("double", arguments.max)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZINCRBY - Double zincrby(String key, double score, String member) --->
    <cffunction name="zincrby" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="score" type="numeric" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zincrby(JavaCast("string", arguments.key), JavaCast("double", arguments.score), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZINTERSTORE - Long zinterstore(String dstkey, String... sets) --->
    <!--- ZINTERSTORE - Long zinterstore(String dstkey, ZParams params, String... sets) --->
    <!--- This method combines both zinterstore methods provided by Jedis --->
    <cffunction name="zinterstore" access="public" returntype="numeric" output="no">
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="params" type="any" required="no" />
        <cfargument name="sets" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var setsArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 3 />

        <cfset setsArray = ArrayNew(1) />
        <cfif isArray(arguments.sets)>
            <cfset setsArray = arguments.sets />
        <cfelseif isSimpleValue(arguments.sets)>
            <cfset ArrayAppend(setsArray, arguments.sets) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(setsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The sets argument passed to the zinterstore method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.params")>
            <cfset result = connection.zinterstore(JavaCast("string", arguments.dstkey), arguments.params, JavaCast("string[]", setsArray)) />
        <cfelse>
            <cfset result = connection.zinterstore(JavaCast("string", arguments.dstkey), JavaCast("string[]", setsArray)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZRANGE - Set<String> zrange(String key, int start, int end) --->
    <cffunction name="zrange" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrange(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- ZRANGEBYSCORE - Set<String> zrangeByScore(String key, String min, String max) --->
    <!--- ZRANGEBYSCORE - Set<String> zrangeByScore(String key, double min, double max) --->
    <!--- ZRANGEBYSCORE - Set<String> zrangeByScore(String key, double min, double max, int offset, int count) --->
    <!--- This method combines all three zrangeByScore methods provided by Jedis --->
    <cffunction name="zrangeByScore" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="min" type="string" required="yes" />
        <cfargument name="max" type="string" required="yes" />
        <cfargument name="offset" type="numeric" required="no" />
        <cfargument name="count" type="numeric" required="no" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var minJavaType = '' />
        <cfset var maxJavaType = '' />

        <cfset minJavaType = Iif(IsNumeric(arguments.min),DE("double"),DE("string")) />
        <cfset maxJavaType = Iif(IsNumeric(arguments.max),DE("double"),DE("string")) />

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.offset") AND IsDefined("arguments.count")>
            <cfset result = connection.zrangeByScore(JavaCast("string", arguments.key), JavaCast(minJavaType, arguments.min), JavaCast(maxJavaType, arguments.max), JavaCast("int", arguments.offset), JavaCast("int", arguments.count)) />
        <cfelse>
            <cfset result = connection.zrangeByScore(JavaCast("string", arguments.key), JavaCast(minJavaType, arguments.min), JavaCast(maxJavaType, arguments.max)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- ZRANGEBYSCOREWITHSCORES - Set<Tuple> zrangeByScoreWithScores(String key, double min, double max) --->
    <!--- ZRANGEBYSCOREWITHSCORES - Set<Tuple> zrangeByScoreWithScores(String key, double min, double max, int offset, int count) --->
    <!--- This method combines both zrangeByScoreWithScores methods provided by Jedis --->
    <cffunction name="zrangeByScoreWithScores" access="public" returntype="struct" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="min" type="numeric" required="yes" />
        <cfargument name="max" type="numeric" required="yes" />
        <cfargument name="offset" type="numeric" required="no" />
        <cfargument name="count" type="numeric" required="no" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.offset") AND IsDefined("arguments.count")>
            <cfset result = connection.zrangeByScoreWithScores(JavaCast("string", arguments.key), JavaCast("double", arguments.min), JavaCast("double", arguments.max), JavaCast("int", arguments.offset), JavaCast("int", arguments.count)) />
        <cfelse>
            <cfset result = connection.zrangeByScoreWithScores(JavaCast("string", arguments.key), JavaCast("double", arguments.min), JavaCast("double", arguments.max)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn StructNew() />
        </cfif>
    </cffunction>


    <!--- ZRANGEWITHSCORES - Set<Tuple> zrangeWithScores(String key, int start, int end) --->
    <cffunction name="zrangeWithScores" access="public" returntype="struct" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrangeWithScores(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn StructNew() />
        </cfif>
    </cffunction>


    <!--- ZRANK - Long zrank(String key, String member) --->
    <cffunction name="zrank" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrank(JavaCast("string", arguments.key), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- FIXME: Convert to use format Long zrem(final String key, final String... members) --->
    <!--- ZREM - Long zrem(String key, String member) --->
    <cffunction name="zrem" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrem(JavaCast("string", arguments.key), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZREMRANGEBYRANK - Long zremrangeByRank(String key, int start, int end) --->
    <cffunction name="zremrangeByRank" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zremrangeByRank(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZREMRANGEBYSCORE - Long zremrangeByScore(String key, double start, double end) --->
    <cffunction name="zremrangeByScore" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zremrangeByScore(JavaCast("string", arguments.key), JavaCast("double", arguments.start), JavaCast("double", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZREVRANGE - Set<String> zrevrange(String key, int start, int end) --->
    <cffunction name="zrevrange" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrevrange(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- ZREVRANGEBYSCORE - Set<String> zrevrangeByScore(String key, String max, String min) --->
    <!--- ZREVRANGEBYSCORE - Set<String> zrevrangeByScore(String key, double max, double min) --->
    <!--- ZREVRANGEBYSCORE - Set<String> zrevrangeByScore(String key, double max, double min, int offset, int count) --->
    <!--- This method combines all three zrevrangeByScore methods provided by Jedis --->
    <cffunction name="zrevrangeByScore" access="public" returntype="array" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="max" type="string" required="yes" />
        <cfargument name="min" type="string" required="yes" />
        <cfargument name="offset" type="numeric" required="no" />
        <cfargument name="count" type="numeric" required="no" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var minJavaType = '' />
        <cfset var maxJavaType = '' />

        <cfset maxJavaType = Iif(IsNumeric(arguments.max),DE("double"),DE("string")) />
        <cfset minJavaType = Iif(IsNumeric(arguments.min),DE("double"),DE("string")) />

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.offset") AND IsDefined("arguments.count")>
            <cfset result = connection.zrevrangeByScore(JavaCast("string", arguments.key), JavaCast(maxJavaType, arguments.max), JavaCast(minJavaType, arguments.min), JavaCast("int", arguments.offset), JavaCast("int", arguments.count)) />
        <cfelse>
            <cfset result = connection.zrevrangeByScore(JavaCast("string", arguments.key), JavaCast(maxJavaType, arguments.max), JavaCast(minJavaType, arguments.min)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result.toArray() />
        <cfelse>
            <cfreturn ArrayNew(1) />
        </cfif>
    </cffunction>


    <!--- ZREVRANGEBYSCOREWITHSCORES - Set<Tuple> zrevrangeByScoreWithScores(String key, double max, double min) --->
    <!--- ZREVRANGEBYSCOREWITHSCORES - Set<Tuple> zrevrangeByScoreWithScores(String key, double max, double min, int offset, int count) --->
    <!--- This method combines both zrevrangeByScoreWithScores methods provided by Jedis --->
    <cffunction name="zrevrangeByScoreWithScores" access="public" returntype="struct" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="max" type="numeric" required="yes" />
        <cfargument name="min" type="numeric" required="yes" />
        <cfargument name="offset" type="numeric" required="no" />
        <cfargument name="count" type="numeric" required="no" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.offset") AND IsDefined("arguments.count")>
            <cfset result = connection.zrevrangeByScoreWithScores(JavaCast("string", arguments.key), JavaCast("double", arguments.max), JavaCast("double", arguments.min), JavaCast("int", arguments.offset), JavaCast("int", arguments.count)) />
        <cfelse>
            <cfset result = connection.zrevrangeByScoreWithScores(JavaCast("string", arguments.key), JavaCast("double", arguments.max), JavaCast("double", arguments.min)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn StructNew() />
        </cfif>
    </cffunction>


    <!--- ZREVRANGEWITHSCORES - Set<Tuple> zrevrangeWithScores(String key, int start, int end) --->
    <cffunction name="zrevrangeWithScores" access="public" returntype="struct" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="start" type="numeric" required="yes" />
        <cfargument name="end" type="numeric" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrevrangeWithScores(JavaCast("string", arguments.key), JavaCast("int", arguments.start), JavaCast("int", arguments.end)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn StructNew() />
        </cfif>
    </cffunction>


    <!--- ZREVRANK - Long zrevrank(String key, String member) --->
    <cffunction name="zrevrank" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zrevrank(JavaCast("string", arguments.key), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZSCORE - Double zscore(String key, String member) --->
    <cffunction name="zscore" access="public" returntype="numeric" output="no">
        <cfargument name="key" type="string" required="yes" />
        <cfargument name="member" type="string" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />

        <cfset connection = getResource() />
        <cfset result = connection.zscore(JavaCast("string", arguments.key), JavaCast("string", arguments.member)) />
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>


    <!--- ZUNIONSTORE - Long zunionstore(String dstkey, String... sets) --->
    <!--- ZUNIONSTORE - Long zunionstore(String dstkey, ZParams params, String... sets) --->
    <!--- This method combines both zunionstore methods provided by Jedis --->
    <cffunction name="zunionstore" access="public" returntype="numeric" output="no">
        <cfargument name="dstkey" type="string" required="yes" />
        <cfargument name="params" type="any" required="no" />
        <cfargument name="sets" type="any" required="yes" />

        <cfset var connection = '' />
        <cfset var result = '' />
        <cfset var namedArgumentCount = '' />
        <cfset var setsArray = '' />
        <cfset var i = '' />

        <cfset namedArgumentCount = 3 />

        <cfset setsArray = ArrayNew(1) />
        <cfif isArray(arguments.sets)>
            <cfset setsArray = arguments.sets />
        <cfelseif isSimpleValue(arguments.sets)>
            <cfset ArrayAppend(setsArray, arguments.sets) />

            <!--- Treat additional non-named arguments as java-style varargs arguments --->
            <cfif ArrayLen(arguments) GT namedArgumentCount>
                <cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
                    <cfif isSimpleValue(arguments[i])>
                        <cfset ArrayAppend(setsArray, arguments[i]) />
                    </cfif>
                </cfloop>
            </cfif>
        <cfelse>
            <cfthrow type="InvalidArgumentTypeException" message="The sets argument passed to the zunionstore method is not an array or one or more strings." />
        </cfif>

        <cfset connection = getResource() />
        <cfif IsDefined("arguments.params")>
            <cfset result = connection.zunionstore(JavaCast("string", arguments.dstkey), arguments.params, JavaCast("string[]", setsArray)) />
        <cfelse>
            <cfset result = connection.zunionstore(JavaCast("string", arguments.dstkey), JavaCast("string[]", setsArray)) />
        </cfif>
        <cfset returnResource(connection) />

        <cfif isDefined("result")>
            <cfreturn result />
        <cfelse>
            <cfreturn 0 />
        </cfif>
    </cffunction>

</cfcomponent>
