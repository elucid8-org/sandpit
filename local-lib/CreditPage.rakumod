use v6.d;
use RakuDoc::Render;
# Expects the js & css links from DataTable

unit class Raku-Doc-Website::CreditPage;
has %.config =
    :name-space<CreditPage>,
    :version<0.1.0>,
    :license<Artistic-2.0>,
    :credit<finanalyst>,
    :authors<finanalyst>,
    set-host-port => -> %final-config { self.get-repo-data( %final-config ) },
    ui-tokens => %(
#        :REPL-label('Raku bar'),
    );

method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-templates($.credit-templates, :source<CreditPage plugin>)
}
method get-repo-data( %final-config ) {
    my @repos = %final-config<repositories>.keys;
    my $repo-dir := %final-config<repository-store>;
    my %repo-data;
    for @repos {
        my $repo = ($repo-dir ~ '/' ~ %final-config<repositories>{ $_ }<repo-name>).IO;
    }
}
method credit-templates { %(
    DataTable => -> %prm, $tmpl {
        my $rv;
        my %d := $tmpl.globals.data.hash;
        if %d<CreditPage>:exists {
            my %sd := %d<CreditPage>.hash;
            if %sd<definitions>{ %prm<data> }:exists && %sd<definitions>{ %prm<data> }.elems {
                #| definition is Hash <routine syntax operator> of Hash
                #| each has keys sh-name = Array of Hash
                #| of name, subkind, snip, source(filename), src-ref, targ-in-fn
                my %defns := %sd<definitions>{ %prm<data> }.hash;
                # convert options in DataTable to js options
                # keep RakuDoc metadata
                my %table-options = %prm.pairs
                        .grep({ .key ~~ / ^ 'dt-' / })
                        .map({ .key.substr(3) => .value })
                        .hash;
                my $table-id = '__' ~ %prm<caption> ~ '_Data_Table';
                my $options = JSON::Fast::to-json( %table-options );
                my $js = qq:to/JS/;
                        <script>
                        let dataTable = new simpleDatatables.DataTable("#$table-id", $options);
                        </script>
                    JS
                $rv ~= qq:to/TABLE/;
                        <table id="$table-id" class="elucid8-datatable table is-striped is-bordered is-hoverable">
                        <thead>
                        <tr><th>{ %prm<header1> // 'Type'}\</th><th>{ %prm<header2> // 'Name' }\</th><th>{ %prm<header3> // 'Described in'}\</th>\</tr>
                        </thead>
                        <tbody>
                    TABLE
                $rv ~= %defns.pairs.map({
                    qq:to/LN/
                        <tr><td>{ .value[0]<subkind> }</td>
                            <td>{ .key }</td>
                            <td>{   .value
                            .map({ '<a href="' ~ .<source> ~ '.html' ~ ( .<targ-in-fn> ?? ('#' ~ .<targ-in-fn> ) !! '' ) ~ '">' ~ .<src-caption> ~ '</a>' })
                            .join('<br>')
                    }</td>
                        </tr>
                    LN
                });
                $rv ~= "\n</tbody></table>\n$js";
            }
            else {
                $rv ~= qq:to/ERR/;
                <div class="Elucid8-error">
                <span class="Elucid8-ui" data-UIToken="DataTableNoData">DataTableNoData</span>\<span>{ %prm<data> }\</span>
                </div>
                ERR
            }
        }
        else {
            $rv ~= q:to/ERR/;
            <div class="Elucid8-error">
            <span class="Elucid8-ui" data-UIToken="DataTableError">DataTableError</span>
            </div>
            ERR
        }
        $rv
    },
)}
method repl-scss {
    Q:to/SCSS/;
    #raku-repl {
        position: fixed;
        bottom: 15vh;
        left: 1vw;
        width: 98vw;
        z-index: 60;
        background: var(--bulma-light);
        opacity: 90%;
        #raku-evaluate, #raku-question {
        .tooltiptext {
                width: fit-content;
                min-width: 10rem;
                left: -5rem;
            }
        }
        #raku-panel {
            margin: 0.5rem 1.5rem;
        }
        #repl-toggle {
            right: 1vw;
            position: fixed;
            top: 28vh;
            .repl-button.tooltip {
                background: var(--bulma-scheme-main);
                border-color: var(--bulma-border);
                color: var(--bulma-info);
                span.icon {
                    margin-inline-end: calc(var(--bulma-button-padding-horizontal)*-.5);
                }
                &:hover {
                    background: var(--bulma-background-hover);
                    color: var(--bulma-danger);
                    .tooltiptext {
                        width:fit-content;
                        padding: 5px;
                        .Elucid8-ui {
                            padding: 0;
                        }
                    }
                }
            }
            &[data-openchannel="on"] :hover {
                .tooltiptext.on {
                    visibility: visible;
                    opacity: 1;
                }
                .tooltiptext.off {
                    visibility: hidden;
                    opacity: 0;
                }
            }
            &[data-openchannel="off"]:hover {
                .tooltiptext.off {
                    visibility: visible;
                    opacity: 1;
                }
                .tooltiptext.on {
                    visibility: hidden;
                    opacity: 0;
                }
            }
        }
        #raku-code {
            padding: 0 10px;
            width: 100%;
            border: none;
        }
        fieldset {
            border-width: 2px;
            border-radius: 5px;
            border-style: ridge;
            display: flex;
            justify-content: start;
            background-color: var(--bulma-scheme-main);
            height: 100%;
        }
        #raku-ws-stdout {
            padding: 0 10px;
            min-height: 1rem;
        }
        #raku-ws-stderr {
            padding: 0 10px;
            min-height: 1rem;
        }
        #raku-ws-headin {
            border-color: var(--bulma-link);
        }
        #raku-ws-headout {
            border-color: var(--bulma-primary);
        }
        #raku-ws-headerr {
            border-color: var(--bulma-danger);
        }
    }
    SCSS
}
