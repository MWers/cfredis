<cfset pageTitle = 'del' />
<cfinclude template="../includes/header.cfm" />

<h3>delete by string</h3>
<pre>
application.redis.set("example:command:del:key1", "foo");
application.redis.del("example:command:del:key1");
</pre>
<cfscript>
application.redis.set("example:command:del:key1", "foo");
result = application.redis.del("example:command:del:key1");
</cfscript>
<cfoutput>#result#</cfoutput>

<hr />

<h3>delete by array</h3>
<pre>
stringArray = [];
application.redis.set("example:command:del:key1", "foo");
application.redis.set("example:command:del:key2", "bar");
ArrayAppend(stringArray, "example:command:del:key1");
ArrayAppend(stringArray, "example:command:del:key2");
application.redis.del(stringArray);
</pre>
<cfscript>
stringArray = [];
application.redis.set("example:command:del:key1", "foo");
application.redis.set("example:command:del:key2", "bar");
ArrayAppend(stringArray, "example:command:del:key1");
ArrayAppend(stringArray, "example:command:del:key2");
result = application.redis.del(stringArray);
</cfscript>
<cfoutput>#result#</cfoutput>

<hr />

<h3>delete by array</h3>
<pre>
stringArray = [];
application.redis.set("example:command:del:key1", "foo");
application.redis.set("example:command:del:key2", "bar");
application.redis.set("example:command:del:key3", "bav");
application.redis.set("example:command:del:key4", "baz");
ArrayAppend(stringArray, "example:command:del:key1");
ArrayAppend(stringArray, "example:command:del:key2");
ArrayAppend(stringArray, "example:command:del:key3");
application.redis.del(stringArray);
</pre>
<cfscript>
stringArray = [];
application.redis.set("example:command:del:key1", "foo");
application.redis.set("example:command:del:key2", "bar");
application.redis.set("example:command:del:key3", "bav");
application.redis.set("example:command:del:key4", "baz");
ArrayAppend(stringArray, "example:command:del:key1");
ArrayAppend(stringArray, "example:command:del:key2");
ArrayAppend(stringArray, "example:command:del:key3");
result = application.redis.del(stringArray);
</cfscript>
<cfoutput>#result#</cfoutput>

<hr />

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:del:key4") />
