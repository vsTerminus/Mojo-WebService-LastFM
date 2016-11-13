package Net::Async::LastFM;

use strict;
use warnings;
use v5.10;

use Mojo::UserAgent;

sub new
{
    my ($class, %params) = @_;
    my $self = {};

    $self->{'api_key'} = $params{'api_key'};

    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name("Net-Async-LastFM");    # Set the UserAgent for what Discord expects
    $ua->connect_timeout(5);
     
    $self->{'ua'} = $ua; # Store this ua

    bless $self, $class;
    return $self;
}

# This is now a recursive subroutine for retries.
# $retries is an optional parameter which defines the maximum number of times the function should try to get data from the API.
# If undefined it will default to 3.
# The subroutine will call itself, decrementing the current retries value until it reaches zero and then send "Nothing playing for $user" to the callback.
# If it succeeds, it will send the nowplaying info back to the callback function.

sub nowplaying
{
    my ($self, $user, $format, $callback, $retries) = @_;

    my $base_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks';
    my $api_key = $self->{'api_key'};
    my $api_url = $base_url . "&user=$user&api_key=$api_key&format=json&limit=1";
    my $ua = $self->{'ua'};

    $retries = 3 unless defined $retries;
    my $np;

    $ua->get($api_url => sub {
        my ($ua, $tx) = @_;
        my $json = $tx->res->json; 

        my $track = $json->{'recenttracks'}{'track'}[0];
        my $artist = $track->{'artist'}{'#text'};
        my $title = $track->{'name'};
        my $album = $track->{'album'}{'#text'};
    
        $format = "artist - title" unless defined $format;

        if ( defined $artist and defined $album and defined $title )
        {
            $format =~ s/\bartist\b/$artist/g;
            $format =~ s/\balbum\b/$album/g;
            $format =~ s/\btitle\b/$title/g;
    
            $np = $format;
        }

        if ( defined $np )
        {
            $callback->($np);
        }
        elsif ( --$retries > 0 )
        {
            # Try again.
            $self->nowplaying($user, $format, $callback, $retries);
        }
        else
        {
            $callback->("Nothing playing for $user");
        }
    });
}

1;
