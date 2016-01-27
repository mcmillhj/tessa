package tessa::db::mysql;
use Moose;
with qw(tessa::db);

use DBI;

has dsn => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    builder  => '_build_dsn',
);

has [qw(username password)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has dbh => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_dbh',
);

sub _build_dsn {
    return 'DBI:mysql:;port=3306;database=tessa;host=192.34.60.158';
}

sub _build_dbh {
    my ($self) = @_;

    return DBI->connect(
	$self->dsn, 
	$self->username,
	$self->password, 
	{ RaiseError => 1, AutoCommit => 1, PrintError => 1, ShowErrorStatement => 1 }
    );
}

sub delete_asset {
    my ($self, $asset_id) = @_;

    my $sth = $self->dbh->prepare(q{
       delete from tessa.assets where id = ?;
    });
    $sth->execute( $asset_id );    

    my $note_sth = $self->dbh->prepare(q{
       delete from tessa.notes where asset_id = ?; 
    });
    $note_sth->execute( $asset_id );
    
    return;
}

sub delete_all_assets {
    my ($self) = @_;

    my $sth = $self->dbh->prepare(q{
       delete from tessa.assets;
    });
    $sth->execute();

    my $note_sth = $self->dbh->prepare(q{
       delete from tessa.notes; 
    });
    $note_sth->execute();

    return;
}

sub delete_all_notes_for_asset {
    my ($self, $asset_id) = @_;

    my $sth = $self->dbh->prepare(q{
       delete from tessa.notes
       where asset_id = ?;
    });
    $sth->execute( $asset_id );

    return;
}

sub delete_note_for_asset {
    my ($self, $asset_id, $note_id ) = @_;

    my $sth = $self->dbh->prepare(q{
       delete from tessa.notes
       where asset_id = ?
          and id = ?;
    });
    $sth->execute( $asset_id, $note_id );

    return;    
}

sub get_all_assets {
    my ($self) = @_;

    my $sth = $self->dbh->prepare(q{
       select id, 
              name, 
              uri
       from tessa.assets;
    });
    $sth->execute(); 

    my $assets = $sth->fetchall_arrayref( {} );
    foreach my $asset ( @$assets ) {
	$asset->{notes} = $self->get_all_notes_for_asset( $asset->{id} );
    }

    return $assets;
}

sub get_asset {
    my ($self, $asset_id) = @_;

    my $sth = $self->dbh->prepare(q{
       select id, 
              name, 
              uri
       from tessa.assets
       where id = ?;
    });
    $sth->execute( $asset_id );    

    my $asset = $sth->fetchrow_hashref;
    return unless $asset;

    $asset->{notes} = $self->get_all_notes_for_asset( $asset_id );
    return $asset;
}

sub get_all_notes_for_asset {
    my ($self, $asset_id) = @_;

    my $note_sth = $self->dbh->prepare(q{
       select id, 
              note 
       from tessa.notes
       where asset_id = ?;
    });
    $note_sth->execute( $asset_id );

    return $note_sth->fetchall_arrayref( {} );
}

sub put_asset {
    my ($self, $name, $uri ) = @_;

    my $sth = $self->dbh->prepare(q{
       insert into tessa.assets (name, uri) values (?, ?);
    });
    $sth->execute( $name, $uri );

    my $asset_id = $self->dbh->{mysql_insertid};
    return $self->get_asset( $asset_id );
}

sub put_note_for_asset {
    my ($self, $asset_id, $note) = @_;

    my $sth = $self->dbh->prepare(q{
       insert into tessa.notes (asset_id, note)
       values (?, ?);
    });
    $sth->execute( $asset_id, $note );

    return $self->get_asset( $asset_id );
}

sub update_asset {
    my ($self, $asset_id, $name, $uri) = @_;

    my $sth = $self->dbh->prepare(q{
       update tessa.assets 
       set name = coalesce(?, name), 
           uri = coalesce(?, uri) 
       where id = ?;
    });
    $sth->execute( $name, $uri, $asset_id );
    
    return $self->get_asset( $asset_id );
}

sub update_note_for_asset {
    my ($self, $asset_id, $note_id, $note) = @_;

    my $note_sth = $self->dbh->prepare(q{
       update tessa.notes
       set note = ? 
       where id = ? and asset_id = ?;
    });
    $note_sth->execute( $note, $note_id, $asset_id );

    return $self->get_asest( $asset_id );
}

1;

__END__

=pod 

=head1 NAME 

tessa::db::mysql

=head1 DESCRIPTION 

MySQL database backend for a tessa instance

=head1 SYNOPSIS

 use tessa::db::mysql; 

 my $db = tessa::db::mysql->new(
     username => '<username>',
     password => '<password>',
 );

 # create an asset
 my $asset_hashref = $db->put_asset( '<name>', '<uri>' );
 
 # retrieve an asset
 my $asset_hashref = $db->get_asset( $asset_hashref->{id} );
 
 # update an asset
 $db->update_asset( $asset_hashref->{id}, '<new-name>', '<new-uri>' );
 
 # delete an asset
 $db->delete_asset( $assert_hashref->{id} );

 # add a note 
 $db->put_note_for_asset( $asset_hashref->{id}, '<note>' );

=head1 METHODS 

=over 4

=item I<delete_asset>

delete an asset record from tessa.assets denoted by the supplied $asset_id

=item I<delete_all_assets>

delete all asset records from tessa.assets

=item I<delete_all_notes_for_asset>

delete all note records from tessa.notes for a particular $asset_id

=item I<delete_not_for_asset>

delete a specific note record, denoted by $note_id, for a particular $asset_id

=item I<get_asset> 

retrieve an asset record from tessa.assets by the supplied $asset_id

=item I<get_all_asset> 

retrieve all asset records from tessa.assets, including any notes that an asset may have
in tessa.notes

=item I<get_all_notes_for_asset> 

retrieve all note records from tessa.notes for a particular $asset_id

=item I<put_asset> 

create a new asset record in tessa.assets with the supplied name a$nd $uri

=item I<put_note_for_asset>

create a new note record for a particular $asset_id

=item I<update_asset>

update an asset record in tessa.assets by id, overwriting the $name and $uri data fields if new values are supplied

=item I<update_note_for_asset>

update a note record $note_id that belongs to an asset record $asset_id

=back

=cut 
