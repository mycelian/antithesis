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
        }
    };
    $c->stash(json => $endpoints);
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
