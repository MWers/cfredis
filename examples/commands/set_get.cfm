<cfset pageTitle = 'set/get' />
<cfinclude template="../includes/header.cfm" />

<h3>Set value using set</h3>
<pre>
application.redis.set("example:command:get:keyname", "this is the key value")
</pre>
<cfset result = application.redis.set("example:command:get:keyname", "this is the key value") />
<cfoutput>#result#</cfoutput>

<hr />

<h3>Get value using get</h3>
<pre>
application.redis.get("example:command:get:keyname")
</pre>
<cfset result = application.redis.get("example:command:get:keyname") />
<cfoutput>#result#</cfoutput>

<hr />

<h3>Set value using set</h3>
<pre>
application.redis.set('example:command:get:foo', 'bar')
</pre>
<cfoutput>#application.redis.set('example:command:get:foo', 'bar')#</cfoutput>

<hr />

<h3>Get value using get</h3>
<pre>
application.redis.get('example:command:get:foo')
</pre>
<cfoutput>#application.redis.get('example:command:get:foo')#</cfoutput>

<hr />

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:get:keyname") />
<cfset application.redis.del("example:command:get:foo") />
