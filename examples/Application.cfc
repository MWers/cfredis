<cfcomponent>
    <cfset this.name = "cfredis examples" />
    <cfset this.mappings["/cfc"] = GetDirectoryFromPath(GetCurrentTemplatePath()) & "../src/cfc/" />

    <cffunction name="onApplicationStart">
        <cfset var local = {} />

        <!--- Create Redis connection --->
        <cfscript>
            local.redisHost = "localhost";    // redis server hostname or ip address
            local.redisPort = 6379;           // redis server ip address
            local.redisTimeout = 2000;        // redis connection timeout

            // If your server requires a password, uncomment the following line and set it.
            // local.redisPassword = "foobared"; // redis server password

            // Set connection pool configuration
            // http://www.ostools.net/uploads/apidocs/jedis-2.1.0/redis/clients/jedis/JedisPoolConfig.html
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
            if (StructKeyExists(local, "redisPassword")) {
                local.jedisPool.init(local.jedisPoolConfig, local.redisHost, local.redisPort, local.redisTimeout, local.redisPassword);
            } else {
                local.jedisPool.init(local.jedisPoolConfig, local.redisHost, local.redisPort);
            }

            local.redis = CreateObject("component", "cfc.cfredis").init();
            local.redis.connectionPool = local.jedisPool;
        </cfscript>

        <cflock scope="Application" type="exclusive" timeout="10">
            <cfset application.redis = local.redis />
        </cflock>

        <cflog text="Initialized application" type="information" />
    </cffunction>

    <cffunction name="onApplicationEnd">
        <!--- When ending or reinitializing, destroy the Jedis connection pool. --->
        <cflock scope="Application" type="exclusive" timeout="10">
            <cfif structKeyExists(application, "redis") AND structKeyExists(application.redis, "connectionPool")>
                <cfset application.redis.connectionPool.destroy() />
            </cfif>
        </cflock>

        <cflog text="Ended application" type="information" />
    </cffunction>

    <cffunction name="onRequestStart">
        <!--- Reload application? --->
        <cfif structKeyExists(url, "reinit") AND url.reinit EQ "true">
            <cfset this.onApplicationEnd() />
            <cfset this.onApplicationStart() />
        </cfif>
    </cffunction>
</cfcomponent>
