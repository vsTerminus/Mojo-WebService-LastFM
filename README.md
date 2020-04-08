# Mojo::WebService::LastFM

A Non-Blocking interface to the Last.FM API. Currently only supports the "recenttracks" endpoint, allowing you to query what a user is currently and was recently listening to.

It uses Mojo::UserAgent to make the calls and supports both callbacks and promises (with Mojo::Promise).


## INSTALL

This module is now officially part of CPAN, which means you can install it simply and easily using tools like cpanminus.

Using cpanminus:

    cpanm Mojo::WebService::LastFM
