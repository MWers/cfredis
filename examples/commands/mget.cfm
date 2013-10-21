<cfset pageTitle = 'mget' />
<cfinclude template="../includes/header.cfm" />

<h3>Set values and retrieve using mget</h3>
<pre>
application.redis.set("example:command:mget:key1", "foo");
application.redis.set("example:command:mget:key2", "bar");
application.redis.set("example:command:mget:key3", "bav");
application.redis.set("example:command:mget:key4", "baz");

keys = [];
ArrayAppend(keys, "example:command:mget:key1");
ArrayAppend(keys, "example:command:mget:key2");
ArrayAppend(keys, "example:command:mget:key3");
ArrayAppend(keys, "example:command:mget:key4");
application.redis.mget(keys);
</pre>
<cfscript>
application.redis.set("example:command:mget:key1", "foo");
application.redis.set("example:command:mget:key2", "bar");
application.redis.set("example:command:mget:key3", "bav");
application.redis.set("example:command:mget:key4", "baz");

keys = [];
ArrayAppend(keys, "example:command:mget:key1");
ArrayAppend(keys, "example:command:mget:key2");
ArrayAppend(keys, "example:command:mget:key3");
ArrayAppend(keys, "example:command:mget:key4");
result = application.redis.mget(keys);
</cfscript>
<cfdump var="#result#" expand="true" label="mget" />

<hr />

<h3>Iterate over the results</h3>
<pre>
&lt;cfloop from="1" to="#arrayLen(result)#" index="i"&gt;
    &lt;cfif ArrayIsDefined(result, i)&gt;
        &lt;cfoutput&gt;element #i#: #result[i]#&lt;/cfoutput&gt;&lt;br /&gt;
    &lt;/cfif&gt;
&lt;/cfloop&gt;
</pre>
<cfloop from="1" to="#arrayLen(result)#" index="i">
    <cfif ArrayIsDefined(result, i)>
        <cfoutput>element #i#: #result[i]#</cfoutput><br />
    </cfif>
</cfloop>

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:mget:key1") />
<cfset application.redis.del("example:command:mget:key2") />
<cfset application.redis.del("example:command:mget:key3") />
<cfset application.redis.del("example:command:mget:key4") />
