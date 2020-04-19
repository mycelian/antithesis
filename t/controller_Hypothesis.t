use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };


use Test::WWW::Mechanize::Catalyst;
use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Hypothesis;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
$mech->get_ok("/hypothesis/test?q=hello");
$mech->content_contains('hello');
done_testing();
