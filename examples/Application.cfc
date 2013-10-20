<cfcomponent>
    <cfset this.name = "cfredis examples" />
    <cfset this.mappings["/cfc"] = GetDirectoryFromPath(GetCurrentTemplatePath()) & "../src/cfc/" />

    <cffunction name="onApplicationStart">
        <!--- Create Redis connection --->
        <cfscript>
            this.redisHost = "localhost";    // redis server hostname or ip address
            this.redisPort = 6379;           // redis server ip address

            // Set connection pool configuration
            // http://www.ostools.net/uploads/apidocs/jedis-2.1.0/redis/clients/jedis/JedisPoolConfig.html
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

            application.redis = CreateObject("component", "cfc.cfredis").init();
            application.redis.connectionPool = this.jedisPool;
        </cfscript>

        <cflog text="Initialized application" type="information" />
    </cffunction>

    <cffunction name="onApplicationEnd">
        <!--- When ending or reinitializing, destroy the Jedis connection pool. --->
        <cfif structKeyExists(application, "redis") AND structKeyExists(application.redis, "connectionPool")>
            <cfset application.redis.connectionPool.destroy() />
        </cfif>

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
