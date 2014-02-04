package Harbinger::Web;

use 5.18.1;
use Web::Simple;
use JSON::MaybeXS;

use Harbinger::Schema;
my $schema = Harbinger::Schema->connect('dbi:SQLite:harbinger.db');

sub dispatch_request {
  sub (/foo) { [ 200, [ 'Content-Type', 'text/html' ], [ '
<!doctype html>
<head>
</head>
<body>
<img src="/sms" alt="Emacs!" />
</body>

  ' ] ] },

   sub (/sms) {
      require Chart::Clicker;
      require Chart::Clicker::Axis::DateTime;
       my $dtf = $schema->storage->datetime_parser;

         my @out =
            map {
               $_->{measured_at} = $dtf->parse_datetime($_->{measured_at})->epoch;
               $_
            }
            $schema->resultset('Measurement')
               ->search({
                  measured_at => {
                     '>=', $dtf->format_datetime(
                        DateTime->now( time_zone => 'UTC' )->subtract( days => 1)
                     )
                  },
                  'ident.ident' => ['sms-sent'],
                  count => { '!=', undef },
               }, {
                  'columns' => ['count', 'measured_at'],
                  join => [qw( ident server )],
                  order_by => { -asc => 'measured_at' },
               })
               ->hri
               ->all;

         my @in =
            map {
               $_->{measured_at} = $dtf->parse_datetime($_->{measured_at})->epoch;
               $_
            }
            $schema->resultset('Measurement')
               ->search({
                  measured_at => {
                     '>=', $dtf->format_datetime(
                        DateTime->now( time_zone => 'UTC' )->subtract( days => 1)
                     )
                  },
                  'ident.ident' => ['sms2-in', 'sms1-in'],
                  count => { '!=', undef },
               }, {
                  'columns' => ['count', 'measured_at'],
                  join => [qw( ident server )],
                  order_by => { -asc => 'measured_at' },
               })
               ->hri
               ->all;

         die "no rows found" unless @in && @out;

         my $cc = Chart::Clicker->new( width => 800, height => 300 );

         my @series = (
            Chart::Clicker::Data::Series->new({
               name   => 'SMS in',
               values => [map 0+$_->{count}, @in    ],
               keys   => [map $_->{measured_at}, @in],
            }),
            Chart::Clicker::Data::Series->new({
               name   => 'SMS out',
               values => [map 0+$_->{count}, @out    ],
               keys   => [map $_->{measured_at}, @out],
            })
         );

         my @ds = map Chart::Clicker::Data::DataSet->new( series => [$_] ), @series;

         $cc->add_to_datasets($_) for @ds;

         my $def = $cc->get_context('default');

         my $dtaxis = Chart::Clicker::Axis::DateTime->new(
             format => '%l:%M %P',
             position => 'bottom',
             orientation => 'horizontal'
         );
         $def->domain_axis($dtaxis);
         $def->renderer->brush->width(1);
         $def->range_axis->fudge_amount(0.1);
         $cc->draw;

       [ 200,
         [ 'Content-Type' => 'image/png' ],
         [
            $cc->rendered_data
         ],
       ],
   },

   sub () {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
   }
};

1;
