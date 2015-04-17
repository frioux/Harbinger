#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use IO::Async::Loop;
use Harbinger::Server;
use Harbinger::Client;
use DBI;

use Log::Contextual qw( set_logger );
use Log::Log4perl ':easy';
Log::Log4perl->easy_init($FATAL);
my $logger = Log::Log4perl->get_logger;
set_logger $logger;

my $loop = IO::Async::Loop->new;

my $dbh = DBI->connect('dbi:SQLite::memory:', undef, undef, { RaiseError => 1 });
my $server = Harbinger::Server->new(
   port => 0,
   loop => $loop,
   schema_connect_info => sub { $dbh },
);

my $client = Harbinger::Client->new(
  harbinger_ip => '127.0.0.1',
  harbinger_port => $server->_udp_socket->sockport,
  default_args => [ server => 'foo.lan.bar.com' ],
);

my $doom = $client->start( ident => 'test' );

$server->schema->deploy;
my $rs = $server->schema->resultset('Measurement');
ok(!$rs->count, 'no measurements');

$client->send($doom->finish);

my $f = $loop->delay_future(
   after => 1,
)->on_done(sub {
   ok($rs->count, 'got measurements');
   done_testing;
   $loop->stop;
});

$loop->run;
