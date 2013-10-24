<cfset pageTitle = "hmset/hmget" />
<cfinclude template="../includes/header.cfm" />

<h3>Set hash using hmset</h3>
<pre>
redisKey = "example:command:hmset";
hashValues = {};
hashValues["one"] = "uno";
hashValues["two"] = "dos";
hashValues["three"] = "tres";
application.redis.hmset(redisKey, hashValues);
</pre>
<cfscript>
    redisKey = "example:command:hmset";
    hashValues = {};
    hashValues["one"] = "uno";
    hashValues["two"] = "dos";
    hashValues["three"] = "tres";
    application.redis.hmset(redisKey, hashValues);
</cfscript>
<cfdump var="#hashValues#" expand="true" label="hashValues" />

<hr />

<h3>Get hash using hgetall</h3>
<pre>
application.redis.hgetall(redisKey)
</pre>
<cfdump var="#application.redis.hgetall(redisKey)#" expand="true" label="application.redis.hgetall(redisKey)" />

<hr />

<h3>Set hash using hmset</h3>
<pre>
redisKey = "example:command:hmset";
hashValues = {};
hashValues["one"] = "1";
hashValues["two"] = "2";
hashValues["three"] = "3";
application.redis.hmset(redisKey, hashValues);
</pre>
<cfscript>
    redisKey = "example:command:hmset";
    hashValues = {};
    hashValues["one"] = "1";
    hashValues["two"] = "2";
    hashValues["three"] = "3";
    application.redis.hmset(redisKey, hashValues);
</cfscript>
<cfdump var="#hashValues#" expand="true" label="hashValues" />

<hr />

<h3>Get hash using hgetall</h3>
<pre>
application.redis.hgetall(redisKey)
</pre>
<cfdump var="#application.redis.hgetall(redisKey)#" expand="true" label="application.redis.hgetall(redisKey)" />

<hr />

<h3>Set hash using hmset</h3>
<pre>
redisKey = "example:command:hmset";
hashValues = {};
hashValues[1] = "one";
hashValues[2] = "two";
hashValues[3] = "three";
application.redis.hmset(redisKey, hashValues);
</pre>
<cfscript>
    redisKey = "example:command:hmset";
    hashValues = {};
    hashValues[1] = "one";
    hashValues[2] = "two";
    hashValues[3] = "three";
    application.redis.hmset(redisKey, hashValues);
</cfscript>
<cfdump var="#hashValues#" expand="true" label="hashValues" />

<hr />

<h3>Get hash using hgetall</h3>
<pre>
application.redis.hgetall(redisKey)
</pre>
<cfdump var="#application.redis.hgetall(redisKey)#" expand="true" label="application.redis.hgetall(redisKey)" />

<hr />

<h3>Set hash containing type "Double" values using hmset</h3>
<p>(This will cause an error on Railo)</p>
<pre>
redisKey = "example:command:hmset";
hashValues = {};
hashValues["one"] = 1;
hashValues["two"] = 2;
hashValues["three"] = 3;
application.redis.hmset(redisKey, hashValues);
</pre>
<cftry>
    <cfscript>
        redisKey = "example:command:hmset";
        hashValues = {};
        hashValues["one"] = 1;
        hashValues["two"] = 2;
        hashValues["three"] = 3;
        application.redis.hmset(redisKey, hashValues);
    </cfscript>
    <cfdump var="#hashValues#" expand="true" label="hashValues" />
    <cfcatch type="Any">
        <cfdump var="#cfcatch#" expand="true" label="hashValues" />
    </cfcatch>
</cftry>


<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:hmset") />
