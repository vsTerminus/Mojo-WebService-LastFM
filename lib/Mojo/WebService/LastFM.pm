package Mojo::WebService::LastFM;
use feature 'say';

use Moo;
use strictures 2;
use Mojo::UserAgent;
use Mojo::Promise;
use Carp;
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
has 'base_url'  => ( is => 'lazy', default => 'http://ws.audioscrobbler.com/2.0' );

sub recent_tracks_p
{
    my ($self, $params) = @_;

    my $promise = Mojo::Promise->new;
    $self->recent_tracks($params, sub { $promise->resolve(shift) });
    return $promise;
}

sub recent_tracks
{
    my ($self, $params, $callback) = @_;
    croak '$username is undefined' unless exists $params->{'username'};
    carp '$callback is undefined' unless defined $callback;

    my $limit = $params->{'limit'} // 1;

    my $url = $self->base_url . 
    '/?method=user.getrecenttracks' .
    '&user=' . $params->{'username'} . 
    '&api_key=' . $self->api_key . 
    '&format=json' . 
    '&limit=' . $limit;

    $self->ua->get($url => sub
    {
        my ($ua, $tx) = @_;
        croak "Error: " . $tx->error unless defined $tx->result;

        my $json = $tx->res->json;
        croak 'Error: $json response is undefined' unless defined $json;

        $callback->($json) if defined $callback;
    });
}

# Promise wrapper for nowplaying
sub nowplaying_p
{
    my ($self, $params) = @_;
    my $promise = Mojo::Promise->new;

    $self->nowplaying($params, sub { $promise->resolve(shift) });

    return $promise;
}

# Simplified sub that returns a simple subset of recent_tracks only containing the currently playing or last played track
sub nowplaying
{
    my ($self, $username, $callback) = @_;

    my $np;

    $self->recent_tracks_p({ 'username' => $username, 'limit' => 1 })->then(sub
    {
        my $json = shift;
        croak '$json is undefined' unless defined $json;

        my $track = $json->{'recenttracks'}{'track'}[0];
        my $artist = $track->{'artist'}{'#text'};
        my $title = $track->{'name'};
        my $album = $track->{'album'}{'#text'};
        
        if ( defined $artist and defined $title )
        {
            my $np = {
                'artist' => $artist,
                'album'  => $album,
                'title'  => $title,
                'date'   => $track->{'date'},
                'image'  => $track->{'image'},
            };

            $callback->($np);
        }
        else
        {
            $callback->({});
        }
    });
}

sub info_p
{
    my ($self, $user) = @_;
    my $promise = Mojo::Promise->new;

    $self->info($user, sub { $promise->resolve(shift) });
    
    return $promise;
}

# Get user info
sub info
{
    my ($self, $user, $callback) = @_;
    croak '$user is undefined' unless defined $user;
    carp '$callback is undefined' unless defined $callback;

    my $url = $self->base_url . 
    '/?method=user.getinfo' . 
    '&user=' . $user .
    '&api_key=' . $self->api_key .
    '&format=json';
    
    $self->ua->get($url => sub
    {
        my ($ua, $tx) = @_;
        my  $json = $tx->res->json;
        $callback->($json);
    });
}

1;
