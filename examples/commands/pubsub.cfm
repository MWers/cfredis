<cfset pageTitle = 'pub/sub' />
<cfinclude template="../includes/header.cfm" />

<!--- Set up example data --->
<cfset application.redis.del("example:pubsub:test-channel") />

<h3>Subscribe to a channel in the Redis CLI</h3>
<pre>
$ redis-cli
redis 127.0.0.1:6379&gt; SUBSCRIBE "example:pubsub:test-channel"
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "example:pubsub:test-channel"
3) (integer) 1
</pre>

<hr />

<h3>Publish messages to channel using ColdFusion</h3>
<pre>
application.redis.publish("example:pubsub:test-channel", "test message 1");
application.redis.publish("example:pubsub:test-channel", "test message 2");
application.redis.publish("example:pubsub:test-channel", "test message 3");
application.redis.publish("example:pubsub:test-channel", "test message 4");
</pre>
<cfscript>
result1 = application.redis.publish("example:pubsub:test-channel", "test message 1");
result2 = application.redis.publish("example:pubsub:test-channel", "test message 2");
result3 = application.redis.publish("example:pubsub:test-channel", "test message 3");
result4 = application.redis.publish("example:pubsub:test-channel", "test message 4");
</cfscript>
<cfoutput>#result1#</cfoutput><br />
<cfoutput>#result2#</cfoutput><br />
<cfoutput>#result3#</cfoutput><br />
<cfoutput>#result4#</cfoutput><br />

<hr />

<h3>Expected messages in Redis CLI</h3>
<pre>
1) "message"
2) "example:pubsub:test-channel"
3) "test message 1"
1) "message"
2) "example:pubsub:test-channel"
3) "test message 2"
1) "message"
2) "example:pubsub:test-channel"
3) "test message 3"
1) "message"
2) "example:pubsub:test-channel"
3) "test message 4"
</pre>

<cfinclude template="../includes/footer.cfm" />

<!--- Clean up example data --->
<cfset application.redis.del("example:pubsub:test-channel") />
