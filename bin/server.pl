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

      try { decode_sereal($dgram) } catch { warn $_ };
   },
   on_recv_error => sub {
      my ( $self, $errno ) = @_;
      die "Cannot recv - $errno\n";
   },
);
$loop->add($sock);
$loop->run;
