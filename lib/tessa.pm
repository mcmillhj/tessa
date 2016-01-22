package tessa;
use Dancer2;

our $VERSION = '0.1';

any [qw(get post put delete)] => '/' => \&method_not_allowed;

options '/' => sub {
    return to_json { 
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
};

sub method_not_allowed {
    return send_error('METHOD NOT ALLOWED', 405);
}

true;

__END__

=pod

=head1 NAME 

tessa

=head1 DESCRIPTION

tessa, an asset manager.

=cut
