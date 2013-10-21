<cfset pageTitle = 'hdel' />
<cfinclude template="../includes/header.cfm" />

<h3>Set hash using hmset</h3>
<pre>
redisKey = "example:command:hdel";
hashValues = {};
hashValues["one"] = "uno";
hashValues["two"] = "dos";
hashValues["three"] = "tres";
application.redis.hmset(redisKey, hashValues);
</pre>
<cfscript>
    redisKey = "example:command:hdel";
    hashValues = {};
    hashValues["one"] = "uno";
    hashValues["two"] = "dos";
    hashValues["three"] = "tres";
    application.redis.hmset(redisKey, hashValues);
</cfscript>

<hr />

<h3>Get hash using hgetall</h3>
<pre>
redisKey = "example:command:hdel";
application.redis.hgetall(redisKey);
</pre>
<cfdump var="#application.redis.hgetall(redisKey)#" expand="true" label="hgetall" />

<hr />

<h3>Delete hash value using hdel</h3>
<pre>
redisKey = "example:command:hdel";
application.redis.hdel(redisKey, "two");
</pre>
<cfset application.redis.hdel(redisKey, "two") />

<hr />

<h3>Get hash using hgetall</h3>
<pre>
redisKey = "example:command:hdel";
application.redis.hgetall(redisKey);
</pre>
<cfdump var="#application.redis.hgetall(redisKey)#" expand="true" label="hgetall" />

<hr />

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:hdel") />
