package AmuseWikiFarm::Controller::Hypothesis;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Hypothesis - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub hypothesis :Chained('/site') :Args(0) {
    my ($self, $c) = @_;

    my $endpoints = {
        links => {
            links => {
                method => 'GET',
                url => $c->uri_for_action('hypothesis/links')->as_string,
                desc => 'URL templates for generating URLs for HTML pages',
            },
        }
    };
    $c->stash(json => $endpoints);
    $c->detach($c->view('JSON'));

}

sub links :Chained('/site') :PathPart('hypothesis/links') :Args(0) {
    my ($self, $c) = @_;

    my $links = {
        "account.settings" => $c->uri_for('/')->as_string,
        "forgot-password" => $c->uri_for_action('/user/reset_password')->as_string,
        "groups.new" => $c->uri_for('/')->as_string,
        "help" => $c->uri_for_action('/help/faq')->as_string,
        "oauth.authorize" => $c->uri_for('/')->as_string,
        "oauth.revoke" => $c->uri_for('/')->as_string,
        "search.tag" => $c->uri_for('/')->as_string,
        "signup" => $c->uri_for('/')->as_string,
        "user" => $c->uri_for('/')->as_string,
    };
    $c->stash(json => $links);
    $c->detach($c->view('JSON'));
}

=encoding utf8

=head1 AUTHOR

Mycelian <agogagave@riseup.net>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
