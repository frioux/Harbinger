package Harbinger::Schema::ResultSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw(
   Helper::ResultSet::IgnoreWantarray
   Helper::ResultSet::SetOperations
   Helper::ResultSet::ResultClassDWIM
   Helper::ResultSet::Me
   Helper::ResultSet::CorrelateRelationship
   Helper::ResultSet::Shortcut
));

1;

