use strict;
use warnings;

use tessa;
use Test::More tests => 9;
use Plack::Test;
use HTTP::Request;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

my $test = Plack::Test->create($app);
foreach my $request_type ( qw(GET POST PUT DELETE) ) { 
    my $res = $test->request( 
	HTTP::Request->new($request_type => '/') 
    );  

    ok( ! $res->is_success, "[$request_type /] was not successful" );
    is( $res->code, 405, "[GET /] returned status code 405: Method Not Allowed" );
}
