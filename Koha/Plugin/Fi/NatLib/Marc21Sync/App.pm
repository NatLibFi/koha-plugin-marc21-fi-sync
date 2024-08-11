package Koha::Plugin::Fi::NatLib::Marc21Sync::App;
use Modern::Perl; use utf8; use open qw(:utf8);

use Carp;
use DateTime;
use Koha::Cache;
use Koha::Token;
use Koha::Cache::Memory::Lite;

use Try::Tiny;

use base qw(
    Koha::Plugin::Fi::NatLib::Marc21Sync::App::Initiate
    Koha::Plugin::Fi::NatLib::Marc21Sync::App::Crontab
    Koha::Plugin::Fi::NatLib::Marc21Sync::App::Defaults
);

sub new {
    my $class = shift;
    my $args = shift;
    my $self = bless {
        configuration => $args->{configuration},
        config_cache_key => __PACKAGE__ . '::configuration',
    }, $class;
    return $self;
}

sub preconfig {
    my ( $self, $plugin ) = @_;
    return if $self->{plugin};
    $self->{plugin} = $plugin;
    $self->{tables} = {
        templates => $plugin->get_qualified_table_name('templates'),
    };
    # Check cached value:
    my $cache = Koha::Caches->get_instance('plugins');
    my $cached_value = $cache->get_from_cache($self->{config_cache_key});
    if ( ! $cached_value || ! @$cached_value ) {
        # preload configuration (so it available in all ):
        foreach my $config ( @{$self->{configuration}} ) {
            $config->{value} = $plugin->retrieve_data( $config->{name} ) // $config->{default};
        }
        $cache->set_in_cache($self->{config_cache_key}, $self->{configuration}, { expiry => 0 });
    }
    else {
        $self->{configuration} = $cached_value;
    }
    # also make hash of configuration in $self->{config}:
    $self->{config} = { map { $_->{name} => $_->{value} } @{$self->{configuration}} };
    return $self;
}

sub configure_plugin {
    my ( $self, $args ) = @_;
    my $cgi = $self->{plugin}{cgi};
    if ( $cgi->param('save') ) {
        foreach my $config ( @{$self->{configuration}} ) {
            $self->store_data( { $config->{name} => scalar $cgi->param( $config->{name} ) } );
        }
        Koha::Caches->get_instance('plugins')->clear_from_cache($self->{config_cache_key});
        $self->go_home();
    } elsif ( $cgi->param('restore_defaults') ) {
        foreach my $config ( @{$self->{configuration}} ) {
            $self->store_data( { $config->{name} => $config->{default} } );
        }
        Koha::Caches->get_instance('plugins')->clear_from_cache($self->{config_cache_key});
        $self->go_home();
    } else {
        my $template = $self->get_template({ file => 'templates/base/configure.tt' });
        $self->output_html( $template->output() );
    }
    return;
}

sub get_log {
    my $self = shift;
    return $self->retrieve_data('last_logs') // '';
}

sub set_log {
    my ( $self, $log_text ) = @_;
    $self->store_data( { last_logs => $log_text } );
    return;
}

sub log {
    my ( $self, $message ) = @_;

    # TODO: fix race conditions when two processes writes to the log var by locking SQL table plugin_data:
    my $dbh = C4::Context->dbh;
    $dbh->do('LOCK TABLES plugin_data WRITE');

    my $log_text = $self->retrieve_data('last_logs') // '';
    $log_text .= '[' . DateTime->now->iso8601 . '] ' . $message . "\n";
    $self->store_data( { last_logs => $log_text } );

    $dbh->do('UNLOCK TABLES');

    return;
}

sub GenerateCSRF {
    my ( $self ) = @_;

    my $memory_cache = Koha::Cache::Memory::Lite->get_instance;
    my $cache_key    = "CSRF-TOKEN";
    my $cached       = $memory_cache->get_from_cache($cache_key);
    return $cached if $cached;

    # NOTE: this is hacky way to obtain session_id from the context directly!
    my $session_id = $C4::Context::context->{activeuser};
    my $csrf_token = Koha::Token->new->generate_csrf( { session_id => scalar $session_id } );
    $memory_cache->set_in_cache( $cache_key, $csrf_token );
    return $csrf_token;
}


## no critic (Subroutines::RequireArgUnpacking);
sub get_qualified_table_name { return shift->{plugin}->get_qualified_table_name(@_); }
sub get_plugin_http_path     { return shift->{plugin}->get_plugin_http_path(@_); }
sub bundle_path              { return shift->{plugin}->bundle_path(@_); }
sub get_metadata             { return shift->{plugin}->get_metadata(@_); }
sub output_html              { return shift->{plugin}->output_html(@_); }
sub output                   { return shift->{plugin}->output(@_); }
sub retrieve_data            { return shift->{plugin}->retrieve_data(@_); }
sub store_data               { return shift->{plugin}->store_data(@_); }
sub go_home                  { return shift->{plugin}->go_home(@_); }
sub get_template {
    my $self = shift;
    my $template = $self->{plugin}->get_template(@_);
    $template->param(
        koha_version => C4::Context->preference('Version'),
        configuration => $self->{configuration},
        metadata => {
            plugin_name => $self->{plugin}{metadata}{name},
            plugin_version => $self->{plugin}{metadata}{version},
            plugin_description => $self->{plugin}{metadata}{description},
            plugin_author => $self->{plugin}{metadata}{author},
            plugin_homepage => $self->{plugin}{metadata}{homepage},
            plugin_last_upgraded => $self->retrieve_data('last_upgraded'),
            plugin_last_logs => $self->retrieve_data('last_logs'),
            plugin_default_method => $self->{plugin}{metadata}{default_method},
        },
    );
    return $template;
}

sub go_configure {
    my $self = shift;
    print $self->{plugin}{cgi}->redirect("/cgi-bin/koha/plugins/run.pl?class=" . $self->{plugin}{metadata}{class} . "&method=configure");
}

1;
