<cfset pageTitle = 'benchmark' />
<cfinclude template="../includes/header.cfm" />

<cfparam name="url.iterations" default="10000">

<h3>set (<cfoutput>#url.iterations#</cfoutput> iterations)</h3>
<pre>
for(i = 1; i &lt;= <cfoutput>#url.iterations#</cfoutput>; i++) {
    application.redis.set("example:command:benchmark:#i#", i);
}
</pre>
<cfflush />
<cfscript>
    startTime = getTickCount();
    for(i = 1; i <= url.iterations; i++) {
        application.redis.set("example:command:benchmark:#i#", i);
    }
    totalTime = getTickCount() - startTime;
</cfscript>
<cfoutput>
    set: #url.iterations# commands in #totalTime#ms
    (#Round(url.iterations/totalTime*1000)# reqs/sec)
</cfoutput>

<hr />

<h3>get (<cfoutput>#url.iterations#</cfoutput> iterations)</h3>
<pre>
for(i = 1; i &lt;= <cfoutput>#url.iterations#</cfoutput>; i++) {
    application.redis.get("example:command:benchmark:#i#");
}
</pre>
<cfflush />
<cfscript>
    startTime = getTickCount();
    for(i = 1; i <= url.iterations; i++) {
        application.redis.get("example:command:benchmark:#i#");
    }
    totalTime = getTickCount() - startTime;
</cfscript>
<cfoutput>
    get: #url.iterations# commands in #totalTime#ms
    (#Round(url.iterations/totalTime*1000)# reqs/sec)
</cfoutput>

<hr />

<h3>del (<cfoutput>#url.iterations#</cfoutput> iterations)</h3>
<pre>
for(i = 1; i &lt;= <cfoutput>#url.iterations#</cfoutput>; i++) {
    application.redis.del("example:command:benchmark:#i#");
}
</pre>
<cfflush />
<cfscript>
    startTime = getTickCount();
    for(i = 1; i <= url.iterations; i++) {
        application.redis.del("example:command:benchmark:#i#");
    }
    totalTime = getTickCount() - startTime;
</cfscript>
<cfoutput>
    del: #url.iterations# commands in #totalTime#ms
    (#Round(url.iterations/totalTime*1000)# reqs/sec)
</cfoutput>

<hr />

<cfinclude template="../includes/footer.cfm" />
