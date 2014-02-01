package Harbinger::Schema::Result;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{
   TimeStamp
   Helper::Row::NumifyGet
   Helper::Row::RelationshipDWIM
});

sub default_result_namespace { 'Harbinger::Schema::Result' }

1;

