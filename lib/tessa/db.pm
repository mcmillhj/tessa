package tessa::db;
use Moose::Role; 

requires qw(
   delete_asset 
   delete_all_assets 
   delete_all_notes_for_asset
   get_asset 
   get_all_assets 
   put_asset
   put_note_for_asset
   update_asset
);

1;

__END__

=pod 

=head1 NAME 

tessa::db

=head1 REQUIRED_METHODS

 delete_asset 
 delete_all_assets 
 delete_notes_for_asset
 get_asset 
 get_all_assets 
 get_notes_for_asset
 put_asset
 put_notes_for_assets 
 update_asset


=head1 DESCRIPTION

Abstract base class for tessa database backends. 
All classes that consume this role must supply the methods listed above

=head1 SYNOPSIS

 package tessa::db::X;
 with qw(tessa::db);

 sub get_asset {
    ...
 }
 
 ...

 1;

=cut 
