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

sub nowplaying
{
    my ($self, $user) = @_;

    my $base_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks';
    my $format = 'json';
    my $limit = '1';
    my $api_key = $self->{'api_key'};

    my $api_url = $base_url . "&user=$user&api_key=$api_key&format=$format&limit=$limit";

    my $ua = $self->{'ua'};
    my $json = $ua->get($api_url)->res->json;

    my $track = $json->{'recenttracks'}{'track'}[0];
    my $np = $track->{'artist'}{'#text'} . " - " . $track->{'name'};

    return $np
    
}

1;
