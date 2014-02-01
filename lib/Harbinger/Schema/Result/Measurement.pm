package Harbinger::Schema::Result::Measurement;

use Harbinger::Schema::Candy;

primary_column id => {
   data_type         => 'int',
   is_auto_increment => 1,
};

column milliseconds_elapsed => { data_type => 'int' };
column db_query_count => { data_type => 'int' };
column pid => { data_type => 'int' };

column server_id => { data_type => 'int' };
column ident_id => { data_type => 'int' };

belongs_to server => '::Server', 'server_id';
belongs_to ident => '::Ident', 'ident_id';

1;

