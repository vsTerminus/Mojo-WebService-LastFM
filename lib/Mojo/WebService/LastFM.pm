package Mojo::WebService::LastFM;
use feature 'say';

use Moo;
use strictures 2;
use Mojo::UserAgent;
use Mojo::Promise;
use namespace::clean;

has 'api_key'   => ( is => 'ro' );
has 'ua'        => ( is => 'lazy', builder => sub 
{ 
    my $self = shift;
    my $ua = Mojo::UserAgent->new; 
    $ua->transactor->name("Mojo-WebService-LastFM");
    $ua->connect_timeout(5);
    return $ua;
});

# Promise wrapper for nowplaying
sub nowplaying_p
{
    my ($self, $params) = @_;
    my $promise = Mojo::Promise->new;

    $self->nowplaying($params, sub { $promise->resolve(shift) });

    return $promise;
}

# This is now a recursive subroutine for retries.
# $retries is an optional parameter which defines the maximum number of times the function should try to get data from the API.
# If undefined it will default to 3.
# The subroutine will call itself, decrementing the current retries value until it reaches zero and then send "Nothing playing for $user" to the callback.
# If it succeeds, it will send the nowplaying info back to the callback function.

# If the format parameter is passed in the sub will return a string in the specified format
# If not, the sub will return a hashref with artist, album, and title.
sub nowplaying
{
    my ($self, $params, $callback) = @_;

    my $user = $params->{'user'};
    my $format = $params->{'format'};
    my $retries = $params->{'retries'};

    my $base_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks';
    my $api_key = $self->{'api_key'};
    my $api_url = $base_url . "&user=$user&api_key=$api_key&format=json&limit=1";
    my $ua = $self->ua;

    $retries = 3 unless defined $retries;
    my $np;

    $ua->get($api_url => sub {
        my ($ua, $tx) = @_;
        my $json = $tx->res->json; 

        my $track = $json->{'recenttracks'}{'track'}[0];
        my $artist = $track->{'artist'}{'#text'};
        my $title = $track->{'name'};
        my $album = $track->{'album'}{'#text'};
        
        if ( defined $artist and defined $album and defined $title )
        {
            # If the caller wants the results returns in a string format, do that now.
            if ( defined $format )
            {
                $format =~ s/%artist%/$artist/g;
                $format =~ s/%album%/$album/g;
                $format =~ s/%title%/$title/g;
    
                $np = $format;
            }
            # If we were not given a format, just return a hashref with artist, album, and title.
            else
            {
                $np = {
                    'artist' => $artist,
                    'album'  => $album,
                    'title'  => $title,
                    'date'   => $track->{'date'},
                    'image'  => $track->{'image'},
                };
            }
        }

        if ( defined $np )
        {
            $callback->($np);
        }
        elsif ( --$retries > 0 )
        {
            # Try again.
            $self->nowplaying($user, { format => $format, callback => $callback, retries => $retries});
        }
        else
        {
            $callback->("Nothing playing for $user");
        }
    });
}

# Get user info
sub getinfo
{
    my ($self, $user, $callback) = @_;

    my $base_url = "https://ws.audioscrobbler.com/2.0/?method=user.getinfo";

    my $api_key = $self->{'api_key'};
    my $api_url = $base_url . "&user=$user&api_key=$api_key&format=json";
    
    $self->{'ua'}->get($api_url => sub
    {
        my ($ua, $tx) = @_;

        my  $json = $tx->res->json;
        $callback->($json);
    });

}

1;
