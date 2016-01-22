use strict; 
use warnings; 

use Test::More tests => 2;

require_ok 'Riak::Light' 
    or BAIL_OUT 'Perl module to speak to riak is *not* installed';

my $riak = Riak::Light->new(
    host => '127.0.0.1',
    port => 8087, # protocol buffer port
);
ok( $riak->is_alive, 'riak service is running' );
