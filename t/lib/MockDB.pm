package MockDB;

use tessa::db::mysql;
use Test::MockModule;

my %assets; 
my %notes; 

my $asset_idx = 0;
my $note_idx  = 0;

my $module = Test::MockModule->new('tessa::db::mysql');
sub mock {
    $module->mock('delete_all_assets', sub {
	%assets = ();
	%notes  = ();

	return;
    });
    $module->mock('delete_asset', sub { 
	my ($self, $asset_id) = @_;
	delete $assets{$asset_id};
	%notes = grep { $notes{$_}->{asset_id} ne $asset_id } keys %notes; 

	return;
    });
    $module->mock('delete_all_notes_for_asset', sub { 
	my ($self, $asset_id) = @_;
	%notes = grep { $notes{$_}->{asset_id} ne $asset_id } keys %notes; 

	return;
    });
    $module->mock('delete_note_for_asset', sub { 
	my ($self, $asset_id, $note_id) = @_;
	if ( $notes{$note_id}->{asset_id} == $asset_id ) {
	    delete $notes{$note_id};
	}
	
	return;
    });
    $module->mock('get_all_assets', sub {
	return [ map { _get_asset($_) } keys %assets ];
    });
    $module->mock('get_asset', sub {
	my ($self, $asset_id) = @_;

	return _get_asset($asset_id);
    });
    $module->mock('get_all_notes_for_asset', sub {
	my ($self, $asset_id) = @_;
	
	return [
	    grep { $notes{$_}->{asset_id} eq $asset_id } keys %notes 
        ]; 
    });
    $module->mock('put_asset', sub {
	my ($self, $name, $uri) = @_;

	my $asset_id = $asset_idx++;
	$assets{$asset_id} = { id => $asset_id, name => $name, uri => $uri };
	return _get_asset($asset_id);
    });
    $module->mock('put_note_for_asset', sub {
	my ($self, $asset_id, $note) = @_;

	$notes{$note_idx++} = { id => $note_idx, note => $note, asset_id => $asset_id };
	return _get_asset($asset_id);
    });    
    $module->mock('update_asset', sub {
	my ($self, $asset_id, $name, $uri) = @_;

	$assets{$asset_id} = { 
	    name => $name // $assets{$asset_id}->{name}, 
	    uri  => $uri // $assets{$asset_id}->{uri}, 
	};
	return _get_asset($asset_id);
    });    
    $module->mock('update_note_for_asset', sub {
	my ($self, $asset_id, $note_id, $note) = @_;

	$notes{$note_id} = { 
	    note => $note // $notes{$note_id}->{note}, 
	};
	return _get_asset($asset_id);
    });    

    return;
}

sub _get_asset {
    my ($asset_id) = @_;
    return unless exists $assets{$asset_id};

    my @notes;
    foreach my $note_id ( keys %notes ) {
	next unless $notes->{$note_id}->{asset_id} == $asset_id;
	
	push @notes, { id => $note_id, note => $notes{$note_id}->{note} };
    }
    
    return { 
	id    => $asset_id,
	name  => $assets{$asset_id}->{name},
	uri   => $assets{$asset_id}->{uri},
	notes => @notes ? \@notes : undef,
    }; 
}

sub restore {
    $module->unmock_all();
    return;
}

1;

__END__

=pod 

=head1 NAME 

MockDB

=head1 DESCRIPTION 

Mock database backend for testing. Mocks all subroutines that would have written to
or read from MySQL. Uses Perl hashes for storage.

=head1 SYNOPSIS

 use MockDB;
 MockDB::mock();

 # TEST CODE HERE

 MockDB::restore();

=cut
