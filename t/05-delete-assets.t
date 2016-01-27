use strict;
use warnings;

use lib 't/lib';
use MockDB;
MockDB::mock();

use tessa;
use Test::More tests => 3;
use Plack::Test;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

subtest 'DELETE /assets' => sub {
    plan tests => 2;

    my $test = Plack::Test->create($app);

    { # delete all assets
	my $req  = HTTP::Request->new(DELETE => '/assets');
	
	my $res = $test->request( $req );
	ok( $res->is_success, 'DELETE /assets was successful' );
    }

    { # get all assets (should be none) 
	my $res  = $test->request( 
	    HTTP::Request->new(GET => '/assets') 
	    );
    
	is_deeply(
	    JSON::from_json($res->content),
	    { assets => [] },
	    'no assets exist',
	);
    }
};

subtest 'DELETE /assets/asset' => sub {
    plan tests => 3;

    my $test = Plack::Test->create($app);
    my $asset_id; 
    { # create an asset 
	my $req  = HTTP::Request->new(POST => '/assets');
	$req->header('application/json');
	$req->content('{"name":"hunter","uri":"myorg:///users/hunter"}');
	my $response = $test->request( $req );
	my $json_response = JSON::from_json($response->content);
	$asset_id = $json_response->{id};
    }

    { # delete the created asset
	my $req  = HTTP::Request->new(DELETE => "/assets/$asset_id");
	my $response = $test->request( $req );
	
	ok( $response->is_success, "DELETE /assets/$asset_id was successful" );
    }

    { # attempt to retrieve asset $asset_id, should not exist
	my $req  = HTTP::Request->new(GET => "/assets/$asset_id");
	my $response = $test->request( $req );
	
	ok( ! $response->is_success, "GET /assets/$asset_id failed" );
	is( $response->code, 404, "GET /assets/$asset_id returned 404" );
    }
};

sub teardown {
    Plack::Test->create($app)->request( 
	HTTP::Request->new(DELETE => '/assets') 
    );
    
    return;
}

teardown();
MockDB::restore();
