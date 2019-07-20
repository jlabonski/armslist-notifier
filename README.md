# armslist-notifier - Lets you know when new things go on sale on armslist

_OR: never tell your friends you can write software_

Written in bash, two dependancies, docker container included. As a bit of a
programming exercise in pain, why not do it in bash? The classifieds website is
openly hostile to scraping, provides no RSS or easy way to pull data out of it,
and has tons of XHTML errors which renders it unparsable. The glue of bash to
the rescue!

I leverage `Tidy` (tested version 5.6.0) to at the very least emit something
approaching parsable XHTML. From there I suck it into `xmllint` which has a
handy xpath executor. I'm happy that this path exists before I had to resort to
doing something terrible like instantiating a browser in order to be lax enough
to parse the page.

Check for errors, broken xpath extraction, etc, etc, then mail it all up via
AWS SES. Slap in `cron` and call it a day.

Docker image included because why not?
