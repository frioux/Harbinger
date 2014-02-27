use 5.18.1;
use warnings;

use Sereal::Decoder qw(decode_sereal);

use Socket;
use IO::Async::Socket;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

use Log::Contextual qw( :log :dlog set_logger with_logger );
use Log::Log4perl ':easy';
Log::Log4perl->easy_init($DEBUG);
my $logger = Log::Log4perl->get_logger;
set_logger $logger;

use Try::Tiny;

use Harbinger::Schema;
my $schema = Harbinger::Schema->connect('dbi:SQLite:harbinger.db');

my $loop = IO::Async::Loop->new;

my $s = IO::Socket::INET->new(
   Proto => 'udp',
   ReuseAddr => 1,
   Type => SOCK_DGRAM,
   LocalPort => 8001,
) or die "No bind: $@\n";

my $sock = IO::Async::Socket->new(
   handle => $s,
   on_recv => sub {
      my ( $self, $dgram, $addr ) = @_;

      my $client = $s->peerhost . ':' . $s->peerport;

      try {
         my $measurement = decode_sereal($dgram);
         return unless $measurement->{server};
         log_info {
            my $a = shift;
            my $ms = _format_ms($a->{ms});
            sprintf "meas c:% 4i  $ms  $a->{server}:$a->{port} $a->{ident}",
               $a->{c} || 0;
         } $measurement;
         try {
            $schema->resultset('Measurement')->create({
               server => { name => delete $measurement->{server} },
               ident  => { ident => delete $measurement->{ident} },

               milliseconds_elapsed => $measurement->{ms},
               pid => $measurement->{pid},
               port => $measurement->{port} || 0,
               db_query_count => $measurement->{qc} || 0,
               memory_increase_in_kb => $measurement->{mg} || 0,

               count => $measurement->{c} || 0,
            })
         } catch {
            log_warn { "failed to insert data into database: $_" } $_
         }
      } catch {
         log_warn { "failed to decode sereal: $_" } $_
      };
   },
   on_recv_error => sub {
      my ( $self, $errno ) = @_;
      die "Cannot recv - $errno\n";
   },
);
$loop->add($sock);
$loop->run;

use Term::ANSIColor 'color';

sub _format_ms {
   my ($ms) = @_;

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
