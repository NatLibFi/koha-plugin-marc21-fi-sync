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

our $MAX_LOG_LENGTH = 200_000;

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
    $self->{config} = {
        ( map { $_->{name} => $_->{value} } @{$self->{configuration}} ),
        log_level => $plugin->retrieve_data('log_level') // 1,
        log_preserve => $plugin->retrieve_data('log_preserve') // 3,
    };
    return $self;
}

sub configure_plugin {
    my ( $self, $args ) = @_;
    my $cgi = $self->{plugin}{cgi};
    if ( $cgi->param('save') ) {
        foreach my $config ( @{$self->{configuration}} ) {
            $self->store_data( { $config->{name} => scalar $cgi->param( $config->{name} ) } );
        }
        $self->store_data( { log_level => scalar $cgi->param('log_level') } );
        $self->store_data( { log_preserve => scalar $cgi->param('log_preserve') } );
        Koha::Caches->get_instance('plugins')->clear_from_cache($self->{config_cache_key});
        $self->go_home();
    } elsif ( $cgi->param('restore_defaults') ) {
        foreach my $config ( @{$self->{configuration}} ) {
            $self->store_data( { $config->{name} => $config->{default} } );
        }
        $self->store_data( { log_level => 1 } );
        $self->store_data( { log_preserve => 3 } );
        Koha::Caches->get_instance('plugins')->clear_from_cache($self->{config_cache_key});
        $self->go_home();
    } elsif ( $cgi->param('clean_logs_now') ) {
        $self->store_data( { last_logs => '' } );
        $self->go_configure();
        # my $redirect_uri = $cgi->url( -full => 1, -query => 1 ); - this gives forever redirect because has POST params inside
        # my $redirect_uri = $cgi->url( -absolute => 1, -path => 1 );
        # if ( defined $ENV{QUERY_STRING} && length $ENV{QUERY_STRING} ) {
        #     $redirect_uri .= '?' . $ENV{QUERY_STRING}; - this makes URI correct but not encoded
        # }
        # warn "Logs cleaned by user action, Redirecting to $redirect_uri\n";
        # print $cgi->redirect( -uri => $redirect_uri, -status => 302 );    } else {
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

sub trim_log {
    my ($self) = @_;

    my $log_text = $self->retrieve_data('last_logs') // return;
    my $preserve_days = $self->{config}{log_preserve} // 2;
    my $date = DateTime->now( time_zone => 'local' )->subtract( days => $preserve_days );
    my $date_s = $date->ymd('-') . 'T' . $date->hms(':');      # YYYY-MM-DDTHH:MM:SS

    my @out;
    my $keep = 0; # до першого валідного timestamp рядка (добре проти “обрізаних” початків)

    for my $line (split /\n/, $log_text, -1) {
        if ( $line =~ /^\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\]/ ) {
            $keep = ($1 ge $date_s);     # string compare працює для ISO-формату
            push @out, $line if $keep;
        } else {
            push @out, $line if $keep; # рядки без timestamp = продовження попереднього запису
        }
    }

    while (@out && $out[-1] eq '') { pop @out }
    $self->store_data({ last_logs => (@out ? join("\n", @out)."\n" : '') });

    return;
}

sub logf {
    my ($self, $level, $fmt, @args) = @_;
    state %log_levels = (
        'DEBUG'  => 4,
        'NOTICE' => 3,
        'INFO'   => 2,
        'WARN'   => 1,
        'ERROR'  => 0,
    );
    $level = $log_levels{uc $level} // int($level); # prevent non-ints by wars for unknown levels
    return if $level > ($self->{config}{log_level} // 1); # default to WARN

    @args = map { ref($_) eq 'CODE' ? $_->() : $_ } @args; # support list context for arguments,
        # so you can pass sub { (localtime)[2,1,0] } and sprintf "%02d:%02d:%02d"

    my $dbh = C4::Context->dbh;

    my $date = DateTime->now( time_zone => 'local' );
    my $date_s = $date->ymd('-') . 'T' . $date->hms(':');      # YYYY-MM-DDTHH:MM:SS
    my $log_text = '[' . $date . '] ' . sprintf($fmt, @args) . "\n";

    # Hacky way to update log without bring whole line back to Perl from MySQL:
    $dbh->do('SET @new := ?, @max := ?', undef, $log_text, $MAX_LOG_LENGTH);
    $dbh->do(q{
        INSERT INTO plugin_data (plugin_class, plugin_key, plugin_value)
        VALUES (?, ?, @new)
        ON DUPLICATE KEY UPDATE
          plugin_value =
            IF(
              CHAR_LENGTH(@all := CONCAT(IFNULL(plugin_value,''), @new)) <= @max,
              @all,
              IF(
                (@p := LOCATE( (CHAR(10 USING utf8mb4) COLLATE utf8mb4_bin),
                              (@tail := RIGHT(@all, @max)) )) IN (0, @max),
                @tail,
                SUBSTRING(@tail, @p + 1)
              )
            )
    }, undef, $self->{plugin}{metadata}{class}, 'last_logs');

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
            plugin_log_level => $self->retrieve_data('log_level') // 1,
            plugin_log_preserve => $self->retrieve_data('log_preserve') // 3,
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
