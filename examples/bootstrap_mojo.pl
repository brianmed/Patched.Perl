use Patched::Minimal;

my $perl_path = "/usr/local/perl-5.20.3";

unless (-d $perl_path) {
    Patched::Log->info("Perl::Build->install_from_cpan('5.20.3')");

    require Perl::Build;

    Perl::Build->install_from_cpan('5.20.3' => (dst_path  => $perl_path));
};

my $left = command(cmd => command->find("curl"), args => ["-L", "http://cpanmin.us"]);
my $right = command(cmd => "$perl_path/bin/perl", args => ["-", "App::cpanminus"]);
pipeline($left, $right)->run;

command(cmd => "$perl_path/bin/cpanm", args => ["--notest", "Mojolicious"])->run;

command(cmd => "$perl_path/bin/cpanm", args => ["--notest", "Statocles"])->run;
