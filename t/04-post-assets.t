use strict;
use warnings;

use lib 't/lib';
use MockDB;
MockDB::mock();

use tessa;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

subtest 'POST /assets' => sub {
    plan tests => 6;

    my $test = Plack::Test->create($app);
    my $req  = HTTP::Request->new(POST => '/assets');
    $req->header('application/json');
    $req->content('{}');

    my $res = $test->request( $req );
    ok( !$res->is_success, 'POST /assets with empty body was not successful' );
    is( $res->code, 400, 'got HTTP 400 (BAD REQUEST) for malformed POST' );
    is_deeply(
	JSON::from_json($res->content),
	{ errors => ['Missing required parameter \'name\' or \'uri\' from JSON request body'] },
	'got expected error for empty POST /assets'
    );

    $req = HTTP::Request->new(POST => '/assets');
    $req->header('application/json');
    $req->content( JSON::to_json({ name => 'hunter', uri => 'myorg:///users/hunter' }) );

    $res = $test->request( $req );
    ok( $res->is_success, 'POST /assets with correct JSON body was successful' );
    is( $res->code, 200, 'got HTTP 200 for successful POST /assets' );

    my $json_response = JSON::from_json($res->content);
    is_deeply(
	$json_response,
	{ id	=> $json_response->{id}, 
	  name	=> 'hunter', 
	  uri	=> 'myorg:///users/hunter', 
	  notes => undef 
	},
	'successful POST /assets returned asset that was created'
    );

    teardown();
};

sub teardown {
    Plack::Test->create($app)->request( 
	HTTP::Request->new(DELETE => '/assets') 
    );
    
    return;
}

END { 
    teardown();
}

MockDB::restore();
