use strict;
use warnings;

use tessa;
use Test::More tests => 4;
use Plack::Test;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

subtest 'GET /assets [NO ASSETS]' => sub {
    plan tests => 1;

    my $test = Plack::Test->create($app);
    my $res  = $test->request( 
	HTTP::Request->new(GET => '/assets') 
    );
    
    is_deeply(
	JSON::from_json($res->content),
	{ assets => [] },
	'no assets exist yet',
    );
};

subtest 'GET /assets [1 ASSET]' => sub {
    # create an asset
    my $test = Plack::Test->create($app);
    my $req  = HTTP::Request->new(POST => '/assets');
    $req->header('application/json');
    $req->content('{"name":"hunter","uri":"myorg:///users/hunter"}');
    $test->request( $req );

    my $res = $test->request( 
	HTTP::Request->new(GET => '/assets') 
    ); 

    my $json_response = JSON::from_json($res->content);
    my $asset_id = $json_response->{assets}->[0]->{id};
    is_deeply(
	$json_response,
	{ assets => [
	      { id    => $asset_id,
		name  => 'hunter', 
		uri   => 'myorg:///users/hunter',
		notes => undef,
	      }], 
	},
	'got JSON array with a single asset record',
    );

    $res = $test->request( 
	HTTP::Request->new(GET => "/assets/$asset_id") 
    ); 
    is_deeply(
	JSON::from_json($res->content),
	{ id    => $asset_id, 
	  name  => 'hunter', 
	  uri   => 'myorg:///users/hunter',
	  notes => undef,
	},
	'got correct asset for \'hunter\', \'myorg:///users/hunter\'',
    );
};

subtest 'GET /assets/asset [NO ASSETS]' => sub {
    # delete all assets
    teardown();

    my $test = Plack::Test->create($app);
    my $res = $test->request( 
	HTTP::Request->new(GET => '/assets/1111') 
    ); 

    ok ( !$res->is_success, 'GET /assets/1111 failed' );
    is( $res->code, 404, '/assets/1111 does not exist' );
    is_deeply(
	JSON::from_json($res->content),
	{ errors => [ 'asset \'1111\' does not exist' ] },
	'got correct error when requesting asset that does not exist',
    );    
};

sub teardown {
    Plack::Test->create($app)->request( 
	HTTP::Request->new(DELETE => '/assets') 
    );
    
    return;
}
