use Patched::Minimal;

my $conf = config("user.conf");

unless (user($conf->{username})->exists) {
    user($conf->{username})->add({
        uid => $conf->{uid},
        password => $conf->{password},  # it is password
    });
}

my $add_access = sprintf("%s        ALL=(ALL)       NOPASSWD: ALL\n", $conf->{username});
my $requiretty = "Defaults    requiretty\n";

##
file("/etc/sudoers")->upsert($add_access)->comment($requiretty);

##
directory("/opt")->chown($conf->{username}, $conf->{username});

##
my $perl_ver = "5.20.3";
my $perl_path = "/opt/perl-$perl_ver";

unless (-d $perl_path) {
    Patched::Log->info("Perl::Build->install_from_cpan('$perl_ver')");

    require Perl::Build;

    Perl::Build->install_from_cpan($perl_ver => (dst_path  => $perl_path));
};

##
my $left = command(cmd => command->find("curl"), args => ["-L", "http://cpanmin.us"]);
my $right = command(cmd => "$perl_path/bin/perl", args => ["-", "App::cpanminus"]);
pipeline($left, $right)->run;

##
command(cmd => "$perl_path/bin/cpanm", args => ["--notest", "Mojolicious"])->run;
