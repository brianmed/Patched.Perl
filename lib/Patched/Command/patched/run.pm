package Patched::Command::patched::run;

use autodie;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Net::OpenSSH;
use File::Temp qw(tempfile);

use Patched::Globals;
use Patched::File;
use Patched::Bcrypt;
use Patched::Command;

has description => 'Run a cmd';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'host=s'   => \my $host,
      'user=s'   => \my $user,
      'pass=s'   => \my $pass,
      'port=s'   => \my $port,
      'cmd=s'    => \my $cmd;

    $port //= 22;

    unless ($host) {
        say $self->usage;
        die("Please specify -host.\n");
    }

    unless ($cmd) {
        say $self->usage;
        die("Please specify -cmd.\n");
    }

    say("[ssh2 connect] $host");
    my $ssh2 = Net::OpenSSH->new(host => $host, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);

    say("[verify supported OS] $host");
    my $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
    unless ($system) {
        die("We only support CentOS right now.\n");
    }

    say("[run $cmd]");
    $system = $ssh2->system({timeout => 30}, $cmd) or die("system failed: " . $ssh2->error);
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::run - Run a command

=head1 SYNOPSIS

  Usage: APPLICATION patched run [OPTIONS]

    ./patched.pl patched run

  Options:
    --host <name>     Hostname to run on
    --user <user>     Username for ssh
    --pass <secret>   Password for ssh
    --port <number>   Port for ssh
    --cmd  <string>   Command

=head1 DESCRIPTION

L<Patched::Command::patched::run> run L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::run> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $run->description;
  $run            = $run->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage  = $run->usage;
  $run       = $run->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::run> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $run->run(@ARGV);

Run this command.

=cut
