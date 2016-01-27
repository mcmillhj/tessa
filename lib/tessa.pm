package tessa;
use Dancer2;

our $VERSION = '0.1';

use tessa::db::mysql;
my $db = tessa::db::mysql->new(
    username => 'tessa',
    password => 'asset',
);

my %HTTP_STATUS_FOR = (
    BAD_REQUEST	       => 400,
    NOT_FOUND	       => 404,
    METHOD_NOT_ALLOWED => 405,
    SERVER_ERROR       => 500,
);

my %LENGTH_FOR = (
   NAME => 128,
   NOTE => 256,
   URI  => 256, 
);

# / 
# all HTTP verbs except for OPTIONS are not allowed for '/'
any [qw(get post put del)] => '/' => \&_method_not_allowed;

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

# /assets
get '/assets' => sub {
    my @assets;

    my $assets;
    eval { 
	$assets	= $db->get_all_assets();
    };
    if ( my $err = $@ ) {
	return _throw_json_error(
  	   $HTTP_STATUS_FOR{SERVER_ERROR},
	   "Error getting all asset records: '$err'", 
	);
    }	
    

    return to_json { assets => $assets };
};

post '/assets' => sub {
    my $request = from_json request->body;

    if ( ! $request->{name} || ! $request->{uri} ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{BAD_REQUEST},
	    "Missing required parameter 'name' or 'uri' from JSON request body", 
	);
    }
  # TODO TEST FOR THIS  
    return unless _validate_asset_record( $request->{name}, $request->{uri} ); 
	    
    my $asset;
    eval {
	$asset = $db->put_asset( $request->{name}, $request->{uri} );
    };
    if ( my $err = $@ ) {
   	return _throw_json_error( 
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error creating new asset: '$err'", 
	);
    }
    return to_json($asset);     
};

del '/assets' => sub {
    eval {
	$db->delete_all_assets;
    }; 
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error deleting all assets and notes: '$err'", 
	);
    }

    return;
};

put '/assets' => \&_method_not_allowed;

# /assets/:asset_id
get '/assets/:asset_id' => sub {
    my $asset_id = route_parameters->get('asset_id');

    my $asset;
    eval {
	return unless _asset_exists( $asset_id );
        $asset = $db->get_asset( $asset_id );
    };
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
            "Error retrieving asset '$asset_id': $err", 
	);
    }
    
    return to_json $asset;
};

put '/assets/:asset_id' => sub {
    my $asset_id = route_parameters->get('asset_id');
    my $request = from_json request->body;

    if ( ! $request->{name} && ! $request->{uri} ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{BAD_REQUEST},
	    "Must supply 'name' or 'uri' in JSON request body to update an asset", 
	);
    }
    
    # TODO TEST FOR THIS  
    return unless _validate_asset_record( $request->{name}, $request->{uri} ); 

    my $asset;
    eval {
	return unless _asset_exists( $asset_id );
	$asset = $db->update_asset( $asset_id, $request->{name}, $request->{uri} );
    };
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
            "Error updating asset '$asset_id': $err", 
        );
    }

    return to_json $asset;
};

del '/assets/:asset_id' => sub {
    my $asset_id = route_parameters->get('asset_id');

    eval {
	$db->delete_asset( $asset_id );
    }; 
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
            "Error deleting asset '$asset_id': $err", 
        );
    }
    
    return;
};

post '/assets/:asset_id' => \&_method_not_allowed;

# /assets/:asset_id/notes

get '/assets/:asset_id/notes' => sub {
    my $asset_id = route_parameters->get('asset_id');

    my $notes;
    eval {
	return unless _asset_exists( $asset_id );
	$notes = $db->get_all_notes_for_asset( $asset_id );
    };
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error getting notes for asset '$asset_id': $err", 
	);
    }

    return to_json $notes;
};

post '/assets/:asset_id/notes' => sub {
    my $asset_id = route_parameters->get('asset_id');

    my $request = from_json request->body;
    if ( ! $request->{note} ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{BAD_REQUEST},
	    "Missing required parameter 'note' in JSON request body", 
	);
    }
   
    return unless _validate_note_record( $request->{note} );
 
    my $asset;
    eval {
	return unless _asset_exists( $asset_id );
	$asset = $db->put_note_for_asset( $asset_id, $request->{note});
    };
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error creating new note record for asset '$asset_id': $err", 
	);
    }

    return to_json $asset;
};

del '/assets/:asset_id/notes' => sub {
    my $asset_id = route_parameters->get('asset_id');

    eval {
	$db->delete_all_notes_for_asset( $asset_id );
    }; 
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error deleting all note records for asset '$asset_id': $err", 
	);
    }
    
    return;
};

put '/assets/:asset_id/notes' => \&_method_not_allowed;

# /assets/:asset_id/notes/:note_id

put '/assets/:asset_id/notes/:note_id' => sub {
    my $asset_id = route_parameters->get('asset_id');
    my $note_id  = route_parameters->get('note_id');

    my $request = from_json request->body;
    if ( ! $request->{note} ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{BAD_REQUEST},
	    "Missing required parameter 'note' in JSON request body", 
	);
    }

    return unless _validate_note_record( $request->{note} );

    my $asset;
    eval {
	return unless _asset_exists( $asset_id );
	return unless _asset_owns_note( $asset_id, $note_id );
	$asset = $db->update_note_for_asset( $asset_id, $note_id, $request->{note} );
    };

    return to_json $asset;
};

del '/assets/:asset_id/notes/:note_id' => sub {
    my $asset_id = route_parameters->get('asset_id');
    my $note_id  = route_parameters->get('note_id');

    eval {
	return unless _asset_owns_note( $asset_id, $note_id );
	$db->delete_note_for_asset( $asset_id, $note_id );
    }; 
    if ( my $err = $@ ) {
	return _throw_json_error(
	    $HTTP_STATUS_FOR{SERVER_ERROR},
	    "Error deleting note record '$note_id' for asset '$asset_id': $err", 
	);
    }

    return;
};

any [qw(post get)] => '/assets/:asset_id/notes/:note_id' => \&_method_not_allowed;

sub _validate_asset_record {
    my ($name, $uri) = @_;
	
    my @errors; 
    push @errors, "name '$name' is > $LENGTH_FOR{NAME} characters"
	if $name && length $name > $LENGTH_FOR{NAME};
    push @errors, "uri '$uri' is > $LENGTH_FOR{URI} characters"
	if $uri && length $uri > $LENGTH_FOR{URI};

    return _throw_json_error(
	$HTTP_STATUS_FOR{BAD_REQUEST},
	@errors,
    ) if @errors;
    return 1;
}

sub _validate_note_record {
    my ($note) = @_;
	
    my @errors; 
    push @errors, "note '$note' is > $LENGTH_FOR{NOTE} characters"
	if length $note > $LENGTH_FOR{NOTE};

    return _throw_json_error(
	$HTTP_STATUS_FOR{BAD_REQUEST},
	@errors,
    ) if @errors;
    return 1;
}

sub _asset_exists {
    my ($asset_id) = @_;

    my $asset = $db->get_asset( $asset_id );
    return _throw_json_error(
        $HTTP_STATUS_FOR{NOT_FOUND},
	"asset '$asset_id' does not exist", 
    ) unless $asset;

    return 1;
}

sub _asset_owns_note {
    my ($asset_id, $note_id) = @_;

    return _throw_json_error( 
	$HTTP_STATUS_FOR{BAD_REQUEST},
	"asset '$asset_id' does not own note '$note_id'",
    ) unless grep { 
	$_->{id} == $note_id 
    } @{ $db->get_asset( $asset_id )->{notes} };
}

sub _build_error_json {
    my (@error_messages) = @_;

    return to_json { errors => [ @error_messages ] };
}

sub _throw_json_error {
    my ($http_status_code, @error_messages) = @_;

    Dancer2::Core::Error->new(
	response     => response(),
	status       => $http_status_code,
	content      => _build_error_json(@error_messages),
	content_type => 'application/json',
    )->throw;    
    return;
}

sub _method_not_allowed {
    return _throw_json_error(
	$HTTP_STATUS_FOR{METHOD_NOT_ALLOWED},
	'METHOD NOT ALLOWED',
    );
}

true;

__END__

=pod

=head1 NAME 

tessa

=head1 DESCRIPTION

tessa, an asset manager.

=cut
