package Patched::Command::patched::deploy;

use autodie;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(spurt sha1_sum);
use Time::HiRes;
use Net::OpenSSH;
use File::Temp qw(tempfile);

use Patched::Globals;
use Patched::File;
use Patched::Bcrypt;
use Patched::Command;

has description => 'Deploy Patched';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'host=s'   => \my $host,
      'user=s'   => \my $user,
      'pass=s'   => \my $pass,
      'port=s'   => \my $port;

    unless ($host) {
        say $self->usage;
        die("Please specify -host.\n");
    }

    $port //= 22;

    say("[ssh2 connect] $host");
    my $ssh2 = Net::OpenSSH->new(host => $host, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);

    say("[verify supported OS] $host");
    my $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
    unless ($system) {
        die("We only support CentOS right now.\n");
    }

    my $sftp = $ssh2->sftp;
    my $InstallDir = $Patched::Globals::InstallDir;

    say("[sftp check previous install] $host");
    my $not_found = 0;
    $sftp->find($InstallDir, on_error => sub { $not_found = 1 });
    unless ($not_found) {
        die("Install directory '$InstallDir' exists.\n");
    }

    say("[sftp mkpath] $InstallDir");
    $sftp->mkpath($InstallDir) or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/pids");
    $sftp->mkpath("$InstallDir/pids") or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/log");
    $sftp->mkpath("$InstallDir/log") or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/dist");
    $sftp->mkpath("$InstallDir/dist") or die("sftp error: " . $sftp->error);

    my $dry_version = "5.20.3";

    say("[sftp put] $InstallDir/CentOS-6-perl-$dry_version.tar.gz");
    $sftp->put("dist/CentOS-6-perl-$dry_version.tar.gz", "$InstallDir/CentOS-6-perl-$dry_version.tar.gz") or die("sftp error: " . $sftp->error);
    say("[sftp symlink] $InstallDir/perl-$dry_version/bin/perl -> $InstallDir/perl");
    $sftp->symlink("$InstallDir/perl" => "$InstallDir/perl-$dry_version/bin/perl") or die("sftp error: " . $sftp->error);

    say("[ssh2 system] cd $InstallDir && tar -zxvf CentOS-6-perl-$dry_version.tar.gz");
    $system = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "cd $InstallDir && tar -zxf CentOS-6-perl-$dry_version.tar.gz") or die("install failed: " . $ssh2->error);
    unless ($system) {
        die("Unable to install perl-$dry_version\n");
    }

    say("[sftp remove] $InstallDir/CentOS-6-perl-$dry_version.tar.gz");
    $sftp->remove("$InstallDir/CentOS-6-perl-$dry_version.tar.gz") or die("sftp error: " . $sftp->error);

    say("[sftp rput] lib $InstallDir/lib");
    $sftp->rput("lib", "$InstallDir/lib") or die("sftp error: " . $sftp->error);

    say("[SUCCESS installed]");
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::deploy - Deploy Patched

=head1 SYNOPSIS

  Usage: APPLICATION patched deploy [OPTIONS]

    ./patched.pl patched deploy

  Options:
    --host <name>     Hostname to deploy to
    --user <user>     Username for ssh
    --pass <secret>   Password for ssh
    --port <number>   Port for ssh

=head1 DESCRIPTION

L<Patched::Command::patched::deploy> deploy L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::deploy> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $deploy->description;
  $deploy         = $deploy->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $deploy->usage;
  $deploy   = $deploy->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::deploy> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $deploy->run(@ARGV);

Run this command.

=cut

