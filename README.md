# Dell IPMI fan controller

This repo hold a small project (simplified version with some small changes of the [PowerEdge-shutup](https://github.com/White-Raven/PowerEdge-shutup))
that I'm currently using to control fans on an Dell R730XD to make it quieter.

This is currently running from a Raspberry Pi Model B I had laying around and it does the job. 

There's also a monitoring script that I'm using on a separate VM running in another server tht sets the fans in auto mode if for some reason the PI
stops responding to pings. (Eventually this should evolve to get a dump of running processes and check that the script is actually running properly).

