package Harbinger::Schema::Result::Server;

use Harbinger::Schema::Candy;

primary_column id => {
   data_type         => 'int',
   is_auto_increment => 1,
};

unique_column name => {
   data_type => 'nvarchar',
   size      => 512,
};

has_many measurements => '::Measurement', 'server_id';

1;

