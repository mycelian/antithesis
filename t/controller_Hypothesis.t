use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Hypothesis;

ok( request('/hypothesis')->is_success, 'Request should succeed' );
done_testing();
