package Mojo::WebService::LastFM;
use feature 'say';

use Moo;
use strictures 2;
use Mojo::UserAgent;
use Mojo::Promise;
use Mojo::Exception;
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
    croak '$username is undefined' unless defined $params->{'username'};
    croak '$callback is undefined' unless defined $callback;

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
        $callback->($tx->error) unless defined $tx->result;

        my $json = $tx->res->json;
        $callback->(Mojo::Exception->new('json response is undefined')) unless defined $json;

        $callback->($json);
    });
}

# Promise wrapper for nowplaying
sub nowplaying_p
{
    my ($self, $params) = @_;
    my $promise = Mojo::Promise->new;

    $self->nowplaying($params, sub{ $promise->resolve(shift) });
    return $promise;
}

# Simplified sub that returns a simple subset of recent_tracks only containing the currently playing or last played track
sub nowplaying
{
    my ($self, $params, $callback) = @_;
    my $username;
    if ( ref $params eq 'HASH' )
    {
        croak 'username is undefined' unless exists $params->{'username'};
        $username = $params->{'username'};
    }
    elsif ( ref \$params eq 'SCALAR' ) 
    {
        $username = $params;
    }
    else
    {
        croak 'Invalid params format. Accept Hashref or Scalar.';
    }

    croak 'callback is undefined' unless defined $callback;

    my $np;

    $self->recent_tracks_p({ 'username' => $username, 'limit' => 1 })->then(sub
    {
        my $json = shift;
        $callback->(Mojo::Exception->new('$json is undefined')) unless defined $json;

        if ( exists $json->{'recenttracks'}{'track'}[0] )
        {
            my $track = $json->{'recenttracks'}{'track'}[0];
            
            my $np = {
                'artist' => $track->{'artist'}{'#text'},
                'album'  => $track->{'album'}{'#text'},
                'title'  => $track->{'name'},
                'date'   => $track->{'date'},
                'image'  => $track->{'image'},
            };

            $callback->($np);
        }
        else
        {
            $callback->(Mojo::Exception->new('Error: Response missing now-playing information.'));
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
    croak 'user is undefined' unless defined $user;
    croak 'callback is undefined' unless defined $callback;

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
