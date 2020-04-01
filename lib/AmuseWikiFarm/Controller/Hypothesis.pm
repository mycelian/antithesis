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

sub hypothesis :Chained('/site') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub test :Chained('hypothesis') :Args(0) {
    my ( $self, $c) = @_;

    $c->response->body($c->req->param('q'));
    $c->response->header('Cache-Control' => 'no-cache');
}

=encoding utf8

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
