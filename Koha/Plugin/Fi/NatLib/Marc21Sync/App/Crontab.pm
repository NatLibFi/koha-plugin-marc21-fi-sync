package Koha::Plugin::Fi::NatLib::Marc21Sync::App::Crontab;
use Modern::Perl; use utf8; use open qw(:utf8);

## ----------------------------------------
## Plugin CRONTAB element
## ----------------------------------------

sub cronjob_nightly {
    my ( $self ) = @_;

    $self->set_log("") unless $self->{config}{log_preserve};

    # we will not do anything if nightly cron is not enabled
    return
        unless $self->{config}{nightly_cron_enabled};

    # 4: Debug, 3: Notice, 2: Info, 1: Warn, 0: Error
    $self->log("Nightly cronjob STARTED.") if $self->{config}{log_level} >= 2;

    ###

    print "Remember to put some sane code here :)\n";

    ###

    $self->log("Nightly cronjob ENDED.") if $self->{config}{log_level} >= 2;

    return;
}

1;
