requires 'IO::Async';
requires 'Log::Contextual';
requires 'Log::Log4perl';
requires 'Try::Tiny';
requires 'DBIx::Class';
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::Candy';
requires 'DBIx::Class::TimeStamp';
requires 'Sereal::Decoder';
requires 'Term::ANSIColor';

on test => sub {
   requires 'Harbinger::Client';
};
