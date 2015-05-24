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
      'port=s'   => \my $port,
      'method=s' => \my $method,
      'type=s'   => \my $type,
      'api_key=s' => \my $api_key,
      'config_dbi_user=s' => \my $dbi_user,
      'config_dbi_pass=s' => \my $dbi_pass,
      'boot'     => \my $boot;

    unless ($method) {
        say $self->usage;
        die("Please specify -method.\n");
    }

    unless ($host) {
        say $self->usage;
        die("Please specify -host.\n");
    }

    unless ($api_key) {
        say $self->usage;
        die("Please specify -api_key.\n");
    }

    unless ($method =~ m/^(ssh|local)$/) {
        say $self->usage;
        die("Please specify ssh or local for -method.\n");
    }

    $host //= 22;
    $type //= "standalone";

    say("[ssh2 connect] $host");

    my $ssh2 = Net::OpenSSH->new(host => $host, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);

    say("[verify supported OS] $host");
    my $verify = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
    unless ($verify) {
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
    $sftp->mkpath($InstallDir);

    my @t0 = @{[Time::HiRes::gettimeofday]};

    my $json = {
        secret => { current => sha1_sum("$t0[0].$t0[1]"), whence => $t0[0] },
        type => $type,
        api_key => $api_key,
    };

    if ("minion" eq $type) {
        if (!$dbi_user || !$dbi_pass) {
            die("Need -config_dbi_user and -config_dbi_pass\n");
        }

        $json->{dbi_user} = $dbi_user;
        $json->{dbi_pass} = $dbi_pass;
    }

    my ($fh, $config) = tempfile("patched_XXXXXX", TMPDIR => 1);

    say("[spurt] JSONConfig");
    spurt(encode_json($json), $config);
    seek($fh, 0, 0);

    say("[sftp put] $InstallDir/config");
    $sftp->put($fh, "$InstallDir/config");

    say("[sftp put] $InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");
    $sftp->put("dist/CentOS-6.6-perl-5.20.2.tar.gz", "$InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");
    say("[sftp symlink] $InstallDir/perl-5.20.2/bin/perl -> $InstallDir/perl");
    $sftp->symlink("$InstallDir/perl" => "$InstallDir/perl-5.20.2/bin/perl");

    say("[sftp system] cd $InstallDir && tar -zxvf CentOS-6.6-perl-5.20.2.tar.gz");
    my $install = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "cd $InstallDir && tar -zxf CentOS-6.6-perl-5.20.2.tar.gz") or die("install failed: " . $ssh2->error);
    unless ($install) {
        die("We only support CentOS right now.\n");
    }

    say("[sftp remove] $InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");
    $sftp->remove("$InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");

    unless ($boot) {
        say("[SUCCESS installed]");
        return;
    }
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
    --method <type>   Install mode [ssh|local]
    --type <mode>     Type of install [standalone|minion]
    --api_key <key>   Password for remote agent
    --config_dbi_user <user>   Username for DBI [used with minion]
    --config_dbi_pass <pass>   Password for DBI [used with minion]
    --boot            Start Patched on boot

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

