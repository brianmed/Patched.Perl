package Patched::Command::patched::install;

use autodie;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(spurt sha1_sum);
use Time::HiRes;

has description => 'Install Patched';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      't|type=s'  => \my $type,
      'b|boot'    => \my $boot;

    $type = lc($type);
    unless ($type =~ m/^(standalone|minion)$/) {
        die("Please specify -type.\n");
    }

    if (-d "/opt/Patched") {
        die("Install directory '/opt/Patched' exists.\n");
    }

    say("[mkdir] /opt/Patched");
    mkdir("/opt/Patched");

    my @t0 = @{[Time::HiRes::gettimeofday]};

    my $json = {
        secret => { current => sha1_sum("$t0[0].$t0[1]"), whence => $t0[0] },
        type => $type,
    };

    say("[spurt] /opt/Patched/config");
    spurt(encode_json($json), "/opt/Patched/config");

    # Install bootup here
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::install - Install Patched

=head1 SYNOPSIS

  Usage: APPLICATION patched install [OPTIONS]

    ./patched.pl patched install

  Options:
    -t, --type <mode>   Type of install [standalone|minion]
    -b, --boot          Start Patched on boot

=head1 DESCRIPTION

L<Patched::Command::patched::install> installs L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::install> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $install->description;
  $install        = $install->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $install->usage;
  $install  = $install->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::install> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $install->run(@ARGV);

Run this command.

=cut
