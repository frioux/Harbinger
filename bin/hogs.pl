#!/usr/bin/env perl

use 5.18.1;
use warnings;

use Devel::Dwarn;

use Harbinger::Schema;

my $s = Harbinger::Schema->connect('dbi:SQLite:harbinger.db');
Dwarn [
   $s->resultset('Measurement')
      ->search({
         'memory_increase_in_kb' => { '>=', 1024 },
      }, {
         join => ['server', 'ident'],
         '+columns' => {
            server => 'server.name',
            ident  => 'ident.ident'
         },
         order_by => { -desc => 'memory_increase_in_kb' },
      })->hri->all
];
