use strict;
use warnings;

use lib 't/lib';
use MockDB;
MockDB::mock();

use tessa;
use Plack::Test;
use Test::More tests => 2;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

subtest 'GET/POST/DELETE /assets/:asset_id/notes' => sub {
    plan tests => 18;

    my $test = Plack::Test->create($app);
    my $asset_id = 0; 
    
    { # get all notes for asset that does not exist, HTTP 404
	my $req  = HTTP::Request->new(GET => "/assets/$asset_id/notes");
	
	my $res = $test->request( $req );
	ok( ! $res->is_success, "GET /assets/$asset_id/notes was not successful for asset that does not exist" );
	is( $res->code, 404, "GET /assets/$asset_id/notes returned 404 for asset that does not exist" );
    }

    { # create an asset
	my $req  = HTTP::Request->new(POST => '/assets');
	$req->header('application/json');
	$req->content(JSON::to_json({name => 'hunter', uri => 'myorg:///users/hunter'}));
	my $response = $test->request( $req );
	my $json_response = JSON::from_json($response->content);
	
	$asset_id = $json_response->{id};
    }

    { # get all notes for existing asset with no notes HTTP 200
	my $req  = HTTP::Request->new(GET => "/assets/$asset_id/notes");
	
	my $res = $test->request( $req );
	ok( $res->is_success, "GET /assets/$asset_id/notes was successful" );
	is( $res->code, 200, "GET /assets/$asset_id/notes returned 200" );

	is_deeply( 
	    JSON::from_json($res->content),
	    [],
	    "got no notes for asset $asset_id"
	);
    }

    { # add some notes for asset $asset_id
	my $req  = HTTP::Request->new(POST => "/assets/$asset_id/notes");
	$req->header('application/json');
	$req->content( JSON::to_json({ note => 'NOTE1 for hunter' }) );
	my $response = $test->request( $req );
    }

    my $note_id;
    { # get all notes for existing asset with 1 note HTTP 200
	my $req  = HTTP::Request->new(GET => "/assets/$asset_id/notes");
	
	my $res = $test->request( $req );
	ok( $res->is_success, "GET /assets/$asset_id/notes was successful" );
	is( $res->code, 200, "GET /assets/$asset_id/notes returned 200" );

	my $json_response = JSON::from_json($res->content);
	is_deeply( 
	    $json_response,
	    [{ id => 0, asset_id => 0, note => 'NOTE1 for hunter' }],
	    "got 1 note for asset $asset_id"
	);

	$note_id = $json_response->[0]->{id};
    }

    { # delete note $note_id 
	my $req  = HTTP::Request->new(DELETE => "/assets/$asset_id/notes/$note_id");
	
	my $res = $test->request( $req );
	ok( $res->is_success, "DELETE /assets/$asset_id/notes/$note_id was successful" );
	is( $res->code, 200, "DELETE /assets/$asset_id/notes/$note_id returned 200" );
    }

    { # add a new note for asset $asset_id
	my $req  = HTTP::Request->new(POST => "/assets/$asset_id/notes");
	$req->header('application/json');
	$req->content( JSON::to_json({ note => 'NOTE2 for hunter' }) );
	my $response = $test->request( $req );
	my $json_response = JSON::from_json($response->content);
	
	$note_id = $json_response->{notes}->[0]->{id};
    }

    { # update a note 
	my $req  = HTTP::Request->new(POST => "/assets/$asset_id/notes/$note_id");
	$req->content_type('application/json');
	$req->content( JSON::to_json( { note => 'NOTE2 for hunter [updated]' }) );
	my $res = $test->request( $req );
	ok( $res->is_success, "POST /assets/$asset_id/notes/$note_id was successful" );
	is( $res->code, 200, "POST /assets/$asset_id/notes/$note_id returned 200" );	

	my $json_response = JSON::from_json($res->content);
	is_deeply( 
	    $json_response->{notes}->[0],
	    { note     => 'NOTE2 for hunter [updated]',
	      id       => 1,
	      asset_id => $asset_id,
	    },
	    "updated $note_id sucessfully",
       );
    }

    { # delete all notes
	my $req = HTTP::Request->new(DELETE => "/assets/$asset_id/notes");
	
	my $res = $test->request( $req );
	ok( $res->is_success, "DELETE /assets/$asset_id/notes was successful" );
	is( $res->code, 200, "DELETE /assets/$asset_id/notes returned 200" );
    }

    { # get all notes, none exist
	my $req  = HTTP::Request->new(GET => "/assets/$asset_id/notes");
	
	my $res = $test->request( $req );
	ok( $res->is_success, "GET /assets/$asset_id/notes was successful" );
	is( $res->code, 200, "GET /assets/$asset_id/notes returned 200" );

	is_deeply( 
	    JSON::from_json($res->content),
	    [],
	    "got no notes for asset $asset_id"
	);	
    }
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

__END__
=begin
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
=end
