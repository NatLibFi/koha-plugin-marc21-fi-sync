[% WRAPPER 'sub-header.inc' %]
    [% WRAPPER breadcrumbs %]
        [% WRAPPER breadcrumb_item %]
            <a href="/cgi-bin/koha/plugins/plugins-home.pl">Plugins</a>
        [% END %]
        [% WRAPPER breadcrumb_item %]
            [% IF NOT metadata.plugin_default_method %]
                <span>[% metadata.plugin_name %]</span>
            [% ELSE %]
            <a href="/cgi-bin/koha/plugins/run.pl?class=[% CLASS | uri %]&method=[% metadata.plugin_default_method %]">[% metadata.plugin_name %]</a>
            [% END %]
            [%- IF metadata.plugin_default_method != 'configure' && METHOD != 'configure' -%]
            (<a href="/cgi-bin/koha/plugins/run.pl?class=[% CLASS | uri %]&method=configure">configure</a>)
            [%- END %]
        [% END %]
        [% WRAPPER breadcrumb_item bc_active= 1 %]
            <span>[% active_text %]</span>
        [% END %]
    [% END #/ WRAPPER breadcrumbs %]
[% END #/ WRAPPER sub-header.inc %]
