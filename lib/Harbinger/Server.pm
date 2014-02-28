package Harbinger::Server;

use Moo;
use warnings NONFATAL => 'all';

use Socket;
use IO::Async::Socket;
use IO::Async::Timer::Periodic;

use Sereal::Decoder qw(decode_sereal);
use Log::Contextual qw( :log :dlog );
use Try::Tiny;
use Term::ANSIColor 'color';

use Harbinger::Schema;

sub _format_ms {
   my ($ms) = @_;

   return 'ms:    ?' unless defined $ms;

   my $color;
   if ($ms < 31) {
      $color = 'white';
   } elsif ($ms < 90) {
      $color = 'green';
   } elsif ($ms < 300) {
      $color = 'yellow';
   } else {
      $color = 'red';
   }
   sprintf 'ms:%s% 5i%s', color($color), $ms, color 'reset'
}

sub _format_c {
   my ($c) = @_;

   return 'c:   ?' unless defined $c;

   sprintf 'ms:% 4i%s', $c
}

use namespace::clean;

has port => (
   is => 'ro',
   default => 8001,
);

has _udp_socket => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      IO::Socket::INET->new(
         Proto => 'udp',
         ReuseAddr => 1,
         Type => SOCK_DGRAM,
         LocalPort => shift->port,
      ) or die "No bind: $@\n";
   },
);

has schema_connect_info => (
   is => 'ro',
   required => 1,
);

has schema => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      Harbinger::Schema->connect(shift->schema_connect_info);
   },
);

has _loop => (
   is => 'ro',
   required => 1,
   init_arg => 'loop',
);

sub _deserialize_measurement {
   my ($self, $dgram) = @_;
   my $measurement;
   try {
      $measurement = decode_sereal($dgram);
      return unless
         !defined $measurement->{server}
      && !defined $measurement->{ident}
      && !defined $measurement->{pid};

      log_info {
         my $a     = shift;
         my $ms    = _format_ms($a->{ms});
         my $c     = _format_c($a->{c});
         my $ident = $a->{ident};
         my $port  = $a->{port} || '';
         $ident    = " $ident" unless $ident =~ m(^/);

         "$c  $ms  $a->{server}:$port$ident";
      } $measurement;
   } catch {
      log_warn { "failed to decode sereal: $_" } $_
   };

   return $measurement;
}

sub _create_measurement {
   my ($self, $measurement) = @_;

   try {
      $self->schema->resultset('Measurement')->create({
         server => { name  => delete $measurement->{server} },
         ident  => { ident => delete $measurement->{ident}  },

         milliseconds_elapsed  => $measurement->{ms},
         pid                   => $measurement->{pid},
         port                  => $measurement->{port},
         db_query_count        => $measurement->{qc},
         memory_increase_in_kb => $measurement->{mg},
         count                 => $measurement->{c},
      })
   } catch {
      log_error { "failed to insert data into database: $_" } $_
   }
}

has _async_socket => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      my $server = shift;

      my $sock = IO::Async::Socket->new(
         handle => $server->_udp_socket,
         on_recv => sub {
            my ( $self, $dgram, $addr ) = @_;

            my $measurement = $server->_deserialize_measurement($dgram);
            $server->_create_measurement($measurement) if $measurement;
         },
         on_recv_error => sub {
            my ( $self, $errno ) = @_;
            die "Cannot recv - $errno\n";
         },
      );
      $server->_loop->add($sock);
      $sock;
   },
);

sub BUILD { shift->_async_socket; }

sub DESTROY {
   my $self = shift;

   $self->_loop->remove($self->_async_socket);
}

1;
