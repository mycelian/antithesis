use strict;
use warnings;
use Test::More tests => 7;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };


use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use AmuseWikiFarm::Controller::Hypothesis;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
$mech->get_ok("/hypothesis/");
my $endpoints = from_json($mech->response->content);
ok $endpoints->{links};
ok $endpoints->{links}->{links};

$mech->get_ok("/hypothesis/links");
my $links = from_json($mech->response->content);
ok $links->{help};

$mech->get_ok("/hypothesis/annotations");
my $annotation = from_json($mech->response->content);
ok $annotation->{id};
