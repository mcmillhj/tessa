use strict;
use warnings;

use tessa;
use Test::More tests => 6;
use Plack::Test;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

subtest '/' => sub {
    plan tests => 8;
    my $test = Plack::Test->create($app);
    foreach my $request_type ( qw(GET POST PUT DELETE) ) { 
	my $res = $test->request( 
	    HTTP::Request->new($request_type => '/') 
	);  

	ok( ! $res->is_success, "[$request_type /] was not successful" );
	is( $res->code, 405, "[$request_type /] returned status code 405: Method Not Allowed" );
    }
};

subtest '/assets' => sub {
    plan tests => 2;

    my $test = Plack::Test->create($app);
    my $res = $test->request( 
	HTTP::Request->new(PUT => '/assets') 
    );  

    ok( ! $res->is_success, '[PUT /assets] was not successful' );
    is( $res->code, 405, '[PUT /assets] returned status code 405: Method Not Allowed' );
};

subtest '/assets/:asset_id' => sub {
    plan tests => 2;

    my $test = Plack::Test->create($app);
    my $res = $test->request( 
	HTTP::Request->new(POST => '/assets/1111') 
    );  

    ok( ! $res->is_success, '[POST /assets/1111] was not successful' );
    is( $res->code, 405, '[POST /assets/1111] returned status code 405: Method Not Allowed' );
};

subtest '/assets/:asset_id/notes' => sub {
    plan tests => 2;

    my $test = Plack::Test->create($app);
    my $res = $test->request( 
	HTTP::Request->new(PUT => '/assets/1111/notes') 
    );  

    ok( ! $res->is_success, '[PUT /assets/1111/notes] was not successful' );
    is( $res->code, 405, '[PUT /assets/1111/notes] returned status code 405: Method Not Allowed' );
};

subtest '/assets/:asset_id/notes/:note_id' => sub {
    plan tests => 4;

    my $test = Plack::Test->create($app);
    foreach my $request_type ( qw(POST GET) ) {
	my $res = $test->request( 
	    HTTP::Request->new($request_type => '/assets/1111/notes/2222') 
	);  

	ok( ! $res->is_success, "[$request_type /assets/1111/notes/2222] was not successful" );
	is( $res->code, 405, "[$request_type /assets/1111/notes/2222] returned status code 405: Method Not Allowed" );
    }
};
