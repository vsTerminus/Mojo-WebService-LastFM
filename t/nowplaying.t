use Mojo::Base -strict;

use Test::More;
use Mock::Quick;
use Mojolicious::Lite;
use Mojo::Promise;
use Data::Dumper;
use Data::Compare;

get '/app/' => sub {
    my $c = shift;

    # Need a somewhat valid json structure for the sub to dissect.
    my $json = {
        'recenttracks' => {
            'track' => [
                {
                    'artist' => {
                        '#text' => 'Artist',
                    },
                    'name' => 'Title',
                    'album' => {
                        '#text' => 'Album',
                    },
                    'date' => 'today',
                    'image' => 'image.jpg',
                },
            ],
        },
    };

    $c->render(json => $json);
};

app->log->level('fatal');
app->start();

##########################

require_ok( 'Mojo::WebService::LastFM' );


my $lastfm = Mojo::WebService::LastFM->new(
    'api_key' => 'abc123',
    'base_url' => '/app'
);
$lastfm->ua->server->app(app);

sub main
{
    my $json;

    my $expected = {
        'artist' => 'Artist',
        'album' => 'Album',
        'title' => 'Title',
        'date'  => 'today',
        'image' => 'image.jpg',
    };
    $lastfm->nowplaying_p({ 'username' => 'testuser' })->then(sub{ $json = shift })->wait();
    ok( Compare($json->{'album'}, $expected->{'album'}), 'Happy Path' );
}

main();

done_testing();
