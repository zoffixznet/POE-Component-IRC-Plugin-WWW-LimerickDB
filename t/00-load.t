#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
    use_ok('POE::Component::WWW::LimerickDB');
	use_ok( 'POE::Component::IRC::Plugin::WWW::LimerickDB' );
}

diag( "Testing POE::Component::IRC::Plugin::WWW::LimerickDB $POE::Component::IRC::Plugin::WWW::LimerickDB::VERSION, Perl $], $^X" );
