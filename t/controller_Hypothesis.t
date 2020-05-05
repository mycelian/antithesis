use strict;
use warnings;
use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };


use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use AmuseWikiFarm::Controller::Hypothesis;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'test.amusewiki.org');
$mech->get_ok("/hypothesis/");
my $endpoints = from_json($mech->response->content);
ok $endpoints->{links};
ok $endpoints->{links}->{links};

$mech->get_ok("/hypothesis/links");
my $links = from_json($mech->response->content);
ok $links->{help};

$mech->get("/hypothesis/annotations");
is $mech->status, 401;
ok($mech->form_id('login-form'), "Found the login-form");

$mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root'});
my $post = {
    "uri" => "test"
};
$mech->post_ok("/hypothesis/annotations", $post);
my $annotation = from_json($mech->response->content);
ok $annotation->{id};

$post = {
    "test" => "test"
};
$mech->post("/hypothesis/annotations", $post);
is $mech->status, 404;
