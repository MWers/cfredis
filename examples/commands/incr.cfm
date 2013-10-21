<cfset pageTitle = 'incr' />
<cfinclude template="../includes/header.cfm" />

<!--- Set up example data --->
<cfset application.redis.del("example:command:incr:keyname") />

<h3>incr</h3>
<pre><cfloop from="1" to="20" index="i">
application.redis.incr("example:command:incr:keyname")
<cfoutput>#application.redis.incr("example:command:incr:keyname")#</cfoutput>
</cfloop></pre>

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:command:incr:keyname") />
