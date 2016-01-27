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

my $test = Plack::Test->create($app);
my $res  = $test->request( 
   HTTP::Request->new(OPTIONS => '/') 
);

ok( $res->is_success, '[OPTIONS /] was successful' );
is_deeply( 
    JSON::from_json($res->content),
    _expected_endpoints(),
   '[OPTIONS /] return the expected API endpoints and operations',
);

sub _expected_endpoints {
    return { 
	endpoints => [
	    { endpoint => '/',
	      operations => [qw(OPTIONS)],
	    },
	    { endpoint => '/assets',
	      operations => [qw(GET POST DELETE)],
	    },
	    { endpoint => '/assets/:asset',
	      operations => [qw(GET PUT DELETE)]
	    },
	    { endpoint => '/assets/:asset/notes',
	      operations => [qw(GET POST DELETE)],
	    },
	    { endpoint => '/assets/:asset/notes/:note',
	      operations => [qw(GET PUT DELETE)],
	    },
	],
    };
}

MockDB::restore();
	   
