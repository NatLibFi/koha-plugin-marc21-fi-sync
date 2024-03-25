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

    my $table_name = C4::Context->dbh->quote_identifier($self->{tables}{templates});
    $success &&= C4::Context->dbh->do("
        CREATE TABLE IF NOT EXISTS $table_name (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(150) NOT NULL,
            `description` TEXT,
            `content` LONGTEXT,
            `style` LONGTEXT,
            `created` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    return $success;
}

## ----------------------------------------
## Plugin uninstall phase
## ----------------------------------------

sub init_uninstall_plugin {
    my ( $self, $args ) = @_;
    my $success = 1;

    my $table_name = C4::Context->dbh->quote_identifier($self->{tables}{templates});
    $success &&= C4::Context->dbh->do("DROP TABLE IF EXISTS $table_name");

    return $success;
}

1;
