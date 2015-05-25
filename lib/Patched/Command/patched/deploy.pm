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
      'start'    => \my $start,
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

    $api_key = Patched::Bcrypt->hash_password($api_key);

    unless ($method =~ m/^(ssh|local)$/) {
        say $self->usage;
        die("Please specify ssh or local for -method.\n");
    }

    if ($start && !$boot) {
        die("Please don't specify -start without -boot.\n");
    }

    $host //= 22;
    $type //= "standalone";

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

    if ($boot) {
        say("[sftp check previous boot script] $host");
        my $not_found = 0;
        $sftp->find("/etc/rc.d/init.d/patched", on_error => sub { $not_found = 1 });
        unless ($not_found) {
            die("Boot script '/etc/rc.d/init.d/patched' exists.\n");
        }
    }

    say("[sftp mkpath] $InstallDir");
    $sftp->mkpath($InstallDir) or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/pids");
    $sftp->mkpath("$InstallDir/pids") or die("sftp error: " . $sftp->error);

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
    $sftp->put($fh, "$InstallDir/config") or die("sftp error: " . $sftp->error);

    say("[sftp put] $InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");
    $sftp->put("dist/CentOS-6.6-perl-5.20.2.tar.gz", "$InstallDir/CentOS-6.6-perl-5.20.2.tar.gz") or die("sftp error: " . $sftp->error);
    say("[sftp symlink] $InstallDir/perl-5.20.2/bin/perl -> $InstallDir/perl");
    $sftp->symlink("$InstallDir/perl" => "$InstallDir/perl-5.20.2/bin/perl") or die("sftp error: " . $sftp->error);

    say("[ssh2 system] cd $InstallDir && tar -zxvf CentOS-6.6-perl-5.20.2.tar.gz");
    $system = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "cd $InstallDir && tar -zxf CentOS-6.6-perl-5.20.2.tar.gz") or die("install failed: " . $ssh2->error);
    unless ($system) {
        die("We only support CentOS right now.\n");
    }

    say("[sftp remove] $InstallDir/CentOS-6.6-perl-5.20.2.tar.gz");
    $sftp->remove("$InstallDir/CentOS-6.6-perl-5.20.2.tar.gz") or die("sftp error: " . $sftp->error);

    say("[sftp rput] docroot $InstallDir/docroot");
    $sftp->rput("docroot", "$InstallDir/docroot") or die("sftp error: " . $sftp->error);

    say("[sftp rput] lib $InstallDir/lib");
    $sftp->rput("lib", "$InstallDir/lib") or die("sftp error: " . $sftp->error);

    unless ($boot) {
        say("[SUCCESS installed]");
        return;
    }

    say("[sftp put] /etc/rc.d/init.d/patched");
    $sftp->put("etc/CentOS-6/rc.d/init.d/patched", "/etc/rc.d/init.d/patched") or die("sftp error: " . $sftp->error);

    say("[ssh2 system] chkconfig --add patched");
    $system = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "chkconfig --add patched") or die("install failed: " . $ssh2->error);
    unless ($system) {
        die("Ambiguous install: Patched may not start on boot.\n");
    }

    say("[ssh2 system] chkconfig patched on");
    $system = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "chkconfig patched on") or die("install failed: " . $ssh2->error);
    unless ($system) {
        die("Ambiguous install: Patched may not start on boot.\n");
    }

    if ($start) {
        say("[ssh2 system] service patched start");
        $system = $ssh2->system({timeout => 120, stderr_discard => 1, stdin_discard => 1, stdout_discard => 1}, "service patched start") or die("install failed: " . $ssh2->error);
        unless ($system) {
            die("Ambiguous install: Patched not started.\n");
        }
    }

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
    --method <type>   Install mode [ssh|local]
    --type <mode>     Type of install [standalone|minion]
    --api_key <key>   Password for remote agent
    --config_dbi_user <user>   Username for DBI [used with minion]
    --config_dbi_pass <pass>   Password for DBI [used with minion]
    --start           Start Patched after install
    --boot            Start Patched on boot
    --start           Start Patched after install

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

