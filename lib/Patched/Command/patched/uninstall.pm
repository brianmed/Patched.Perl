package Patched::Command::patched::uninstall;

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

has description => 'Uninstall Patched';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'host=s'   => \my $host,
      'user=s'   => \my $user,
      'pass=s'   => \my $pass,
      'service'    => \my $service,
      'port=s'   => \my $port;

    $port //= 22;

    unless ($host) {
        say $self->usage;
        die("Please specify -host.\n");
    }

    say("[ssh2 connect] $host");
    my $ssh2 = Net::OpenSSH->new(host => $host, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);
    my $sftp = $ssh2->sftp;

    say("[verify supported OS] $host");
    my $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
    unless ($system) {
        die("We only support CentOS right now.\n");
    }

    my $InstallDir = $Patched::Globals::InstallDir;

    if ($service) {
        say("[service running]");
        $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1, stderr_discard => 1}, "chkconfig --list patched");

        unless ($system) {
            say("[stop service]");
            $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1, stderr_discard => 1}, "service patched stop");
        }

        say("[remove symlinks]");
        $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1, stderr_discard => 1}, "chkconfig --del patched");

        my $not_found = 0;
        $sftp->find("/etc/rc.d/init.d/patched", on_error => sub { $not_found = 1 });
        unless ($not_found) {
            say("[remove service]");
            $sftp->remove("/etc/rc.d/init.d/patched") or die("sftp error: " . $sftp->error);
        }
    }

    say("[sftp check previous install] $host");
    my $not_found = 0;
    $sftp->find($InstallDir, on_error => sub { $not_found = 1 });
    if ($not_found) {
        die("Install directory '$InstallDir' doesn't exists.\n");
    }

    say("[remove $InstallDir]");
    $sftp->rremove($InstallDir) or die("sftp error: " . $sftp->error);

    say("[SUCCESS uninstalled]");
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::uninstall - Uninstall Patched

=head1 SYNOPSIS

  Usage: APPLICATION patched uninstall [OPTIONS]

    ./patched.pl patched uninstall

  Options:
    --host <name>     Hostname to uninstall from
    --user <user>     Username for ssh
    --pass <secret>   Password for ssh
    --port <number>   Port for ssh

=head1 DESCRIPTION

L<Patched::Command::patched::uninstall> uninstall L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::uninstall> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $uninstall->description;
  $uninstall      = $uninstall->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage  = $uninstall->usage;
  $uninstall = $uninstall->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::uninstall> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $uninstall->run(@ARGV);

Run this command.

=cut
