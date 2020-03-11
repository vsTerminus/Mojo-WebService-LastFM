use Mojo::Base -strict;

use Test::More;
use Test::Exception;
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

    # It doesn't really matter what the username is, we'll get a response back.
    $lastfm->recenttracks_p({ 'username' => 'testuser' })->then(sub{ is(shift, '{success: true}', "Happy Path") })->wait();

    # Undefined username should croak
    dies_ok( sub { $lastfm->recenttracks_p({ 'username' => undef }) }, 'Undefined Username Croaks' );

    # No callback should also croak
    dies_ok( sub { $lastfm->recenttracks({ 'username' => 'testuser' }) }, 'Undefined Callback Croaks' );


}

main();

done_testing();
