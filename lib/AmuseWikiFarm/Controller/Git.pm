package AmuseWikiFarm::Controller::Git;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::CgitEmulated;
use Encode qw/decode/;

BEGIN { extends 'Catalyst::Controller'; }

=encoding utf8

=head1 NAME

AmuseWikiFarm::Controller::Git - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub git_notify :Chained('/site_no_auth') :PathPart('git-notify') :Args(1) {
    my ($self, $c, $token) = @_;
    my $site = $c->stash->{site};
    log_info {
        $site->id .": received notification to fetch the shared repo (token $token)"
    };
    unless ($token and $token eq $site->get_git_token) {
        $c->detach('/not_permitted');
        return;
    }
    my $job = $site->jobs->git_action_add({
                                           remote => 'shared',
                                           action => 'fetch',
                                          });
    $c->response->body("Remote Git notified: " . $c->uri_for_action('/tasks/display', [ $job->id ]) . "\n");
}

sub git :Chained('/site') :Args {
    my ($self, $c, @args) = @_;
    my $site = $c->stash->{site};
    # do not permit leading dots and URI encoded strings. We have all
    # the repo in ascii anyway.
    my $invalid = 0;
    foreach my $arg (@args) {
        $invalid++ unless $arg =~ m/\A[0-9a-zA-Z_-]+(\.[0-9a-zA-Z]+)*/;
    }
    if ($invalid) {
        $c->detach('/bad_request');
        return;
    }
    unless ($site->repo_is_under_git) {
        # can't be helped, it's a 404, nothing to show.
        $c->detach('/not_found');
        return;
    }
    # we show /git to users and require authentication if
    # cgit_integration is false.
    $self->check_login($c) unless $site->cgit_integration;

    my $cgit = $c->model('Cgit');
    unless ($cgit->enabled) {
        $c->detach('/not_found');
        return;
    }
    unless (@args) {
        push @args, $site->id;
    }
    if ($args[0] ne $site->id) {
        $c->detach('/not_found');
        return;
    }
    my $text;
    if (my @muse = grep { /[a-z0-9]\.muse$/ } @args) {
        my $file = pop @muse;
        $file =~ s/\.muse$//;
        my $f_class = 'text';
        if (grep { $_ eq 'specials' } @args) {
            $f_class = 'special';
        }
        $text = $site->titles->search({uri => $file, f_class => $f_class })->first;
    }


    my %params = %{ $c->request->params };
    my $res = $cgit->get([ @args ], { %params }, $c->request->env);

    # plack doesn't want it in the headers
    my ($status) = $res->headers->remove_header('Status');
    if ($status) {
        log_debug { "Status is $status" } ;
        if ($status =~ m/(\d{3})/a) {
            $c->response->status($1);
            unless ($status and $status =~ /^2/) {
                log_debug { "Body is $status" };
                $c->response->body($status);
                return;
            }
        }
    }

    my %headers = $res->headers->flatten;
    Dlog_debug { "Headers are $_" } \%headers;
    $c->response->header(%headers);

    if ($res->headers->header('Content-Disposition')) {
        # disable the encoding for this request, we're returning the
        # content verbatim.
        $c->clear_encoding;
        $c->response->body($res->content);
        $c->detach;
    }
    elsif ($res->content_type =~ m/text\/html/) {
        $c->stash(cgit_body => $res->decoded_content,
                  text => $text,
                  cgit_page => 1);
    }
    else {
        $c->detach('/not_found');
    }
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
