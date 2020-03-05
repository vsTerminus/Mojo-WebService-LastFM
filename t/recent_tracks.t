use Mojo::Base -strict;

use Test::More;
use Mock::Quick;
use Mojolicious::Lite;
use Mojo::Promise;
use Data::Dumper;

get '/app/' => sub {
    my $c = shift;

    $c->render(json => '{success: true}');
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

    $lastfm->recent_tracks_p({ 'username' => 'testuser' })->then(sub{ $json = shift })->wait();
    is( $json, '{success: true}', 'Happy Path' );
}

main();

done_testing();
