package Harbinger::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

our $VERSION = 1;

__PACKAGE__->load_namespaces(
   default_resultset_class => 'ResultSet',
);

1;
