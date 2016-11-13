This is a stripped down Last.FM module that only supports querying the currently playing track for a user. It uses Mojo::UserAgent to send asynchronous, nonblocking calls.

Installing it should be as simple as symlinking the "Async" directory (Containing LastFM.pm) into your perl lib folder.

eg:

    - ln -s /path/to/Net-Async-LastFM/lib/Net/Async ~/perl5/lib/perl5/Net/Async
