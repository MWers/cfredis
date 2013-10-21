<cfset pageTitle = "index" />
<cfinclude template="./includes/header.cfm" />

<p>The following examples assume that you have an instance
of Redis running at <code>localhost:6379</code>.</p>

<a href="commands/set_get.cfm">set/get</a><br />
<a href="commands/del.cfm">del</a><br />
<a href="commands/incr.cfm">incr</a><br />
<a href="commands/mget.cfm">mget</a><br />
<a href="commands/hmset.cfm">hmset/hmget</a><br />
<a href="commands/hdel.cfm">hdel</a><br />
<a href="commands/pubsub.cfm">pub/sub</a><br />
<a href="commands/benchmark.cfm">benchmark</a><br />

<cfinclude template="./includes/footer.cfm" />
