package Harbinger::Schema::Result::Ident;

use Harbinger::Schema::Candy;

primary_column id => {
   data_type         => 'int',
   is_auto_increment => 1,
};

unique_column ident => {
   data_type => 'varchar',
   size      => 512,
};

has_many measurements => '::Measurement', 'ident_id';

1;

