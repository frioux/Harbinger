package Harbinger::Schema::Candy;

use strict;
use warnings;

use base 'DBIx::Class::Candy';

sub base { 'Harbinger::Schema::Result' }
sub perl_version { 12 }
sub autotable { 1 }

1;

