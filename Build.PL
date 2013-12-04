use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::WWW::LimerickDB',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/WWW/LimerickDB.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE'                                       => 0.9999,
        'POE::Component::IRC::Plugin::BasePoCoWrap' => 0.004,
        'POE::Component::WWW::LimerickDB'           => 0.0102,
    },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-WWW-LimerickDB-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
