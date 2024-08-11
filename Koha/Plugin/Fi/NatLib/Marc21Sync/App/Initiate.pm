package Koha::Plugin::Fi::NatLib::Marc21Sync::App::Initiate;
use Modern::Perl; use utf8; use open qw(:utf8);


## ----------------------------------------
## Plugin update phase
## ----------------------------------------

sub init_upgrade_plugin {
    my ( $self, $args ) = @_;
    my $success = 1;

    return $success;
}

## ----------------------------------------
## Plugin install phase
## ----------------------------------------

sub init_install_plugin {
    my ( $self, $args ) = @_;
    my $success = 1;

    return $success;
}

## ----------------------------------------
## Plugin uninstall phase
## ----------------------------------------

sub init_uninstall_plugin {
    my ( $self, $args ) = @_;
    my $success = 1;

    # remnants of old tables, we still need to remove those on those servers which had it eventually:
    my $table_name = C4::Context->dbh->quote_identifier($self->{tables}{templates});
    $success &&= C4::Context->dbh->do("DROP TABLE IF EXISTS $table_name");

    return $success;
}

1;
