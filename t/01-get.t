use strict;
use warnings;

use tessa;
use Test::More tests => 3;
use Plack::Test;
use HTTP::Request::Common;

my $app = tessa->to_app;
is( ref $app, 'CODE', 'created application ok' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

ok( ! $res->is_success, '[GET /] was not successful' );
is( $res->code, 405, '[GET /] returned status code 405: Method Not Allowed' );
