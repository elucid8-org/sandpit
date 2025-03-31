use v6.d;
use RakuDoc::Render;

unit class Raku-Doc-Website::Edit-In-Browser;
has %.config =
        :name-space<Edit-In-Browser>,
        :version<0.1.0>,
        :license<Artistic-2.0>,
        :credit<finanalyst>,
        :authors<finanalyst>,
        :scss([self.edit-scss,1],[self.modal-scss,1]),
        :js-link(
        ['src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.39.1/ace.js" integrity="sha512-tGc7XQXpQYGpFGmdQCEaYhGdJ8B64vyI9c8zdEO4vjYaWRCKYnLy+HkudtawJS3ttk/Pd7xrkRjK8ijcMMyauw==" crossorigin="anonymous" referrerpolicy="no-referrer"', 1],
        ),
        :js( [[self.browser-js,2], ] ),
        set-host-port => -> %final-config { self.set-host-port( %final-config ) },
        ui-tokens => %(
            :EditButtonTip('Edit this page. Modified&#13; '),
            :EditButtonModalOff('Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.'),
            :EditorPanel('Editor panel'),
            :RefreshPreview('Refresh preview'),
            :RevertOriginal('Revert to Original'),
        );

method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-templates( self.templates, :source<Edit-In-Browser plugin>);
}
method set-host-port( %final-config ) {
    my $js = qq:to/VARS/;
    var renderWebsocketHost =  '{ %final-config<plugin-options><Edit-In-Browser><websocket-host> }';
    VARS
    %!config<js>.push: [  $js, 1 ] ; # the script with host/port has to be before the repl-js script
}
method templates {
    %(
        page-edit => -> %prm, $tmpl {
            my %sd := %prm<source-data>;
            given %sd<type> {
                when <primary glue info>.any {
                    my $commit-time = '<i class="fa fa-ban"></i>';
                    $commit-time = %sd<modified>.yyyy-mm-dd if %sd<modified>:exists;
                    my $repo-path = %sd<path>;
                    $repo-path = $_ with %sd<repo-raw-content-path>;
                    $repo-path = $tmpl.globals.escape.( $repo-path );
                    qq:to/BLOCK/
                      <div class="page-edit">
                        <a id="Edit-browser-activate" class="button page-edit-button js-modal-trigger tooltip"
                            data-editurl="$repo-path"
                            data-target="page-browser-editor">
                            <span class="icon">
                                <i class="fas fa-pen-alt is-medium"></i>
                            </span>
                            <p class="tooltiptext">
                                <span class="Elucid8-ui" data-UIToken="EditButtonTip">EditButtonTip</span>
                                $commit-time
                            </p>
                        </a>
                      </div>
                    <div id="page-browser-editor" class="modal">
                        <div class="modal-background"></div>
                        <div class="modal-content">
                            <div class="box">
                                <div class="edit-preview-box">
                                    <div id="editor-panel">
                                        <div class="Elucid8-ui" data-UIToken="EditorPanel">Editor panel</div>
                                        <div class="buttonPanel">
                                            <button id="getHTML" class="button Elucid8-ui" data-UIToken="RefreshPreview">Refresh preview</button>
                                            <button id="revertToContent" class="button Elucid8-ui" data-UIToken="RevertOriginal">Revert to Original</button>
                                        </div>
                                        <div id="editor"></div>
                                    </div>
                                    <div id="preview-panel">
                                        <div id="socketIndicator" data-openchannel="off">Preview</div>
                                    <iframe id="preview"></iframe>
                                    </div>
                                </div>
                                <p><span class="Elucid8-ui" data-UIToken="EditButtonModalOff">EditButtonModalOff</span></p>
                            </div>
                        </div>
                        <button class="modal-close is-large" aria-label="close"></button>
                    </div>
                    BLOCK
                }
                when 'composite'  {
                    qq:to/BLOCK/
                    <div class="page-edit">
                        <a class="button page-edit-button js-modal-trigger tooltip"
                            data-target="page-edit-info">
                            <span class="icon">
                                <i class="fas fa-pen-alt is-medium"></i>
                            </span>
                        </a>
                    </div>
                    <div id="page-edit-info" class="modal">
                        <div class="modal-background"></div>
                        <div class="modal-content">
                            <div class="box">
                                <p><span class="Elucid8-ui" data-UIToken="EditButtonModal">EditButtonModal</span></p>
                                <p><span class="Elucid8-ui" data-UIToken="EditButtonModalOff">EditButtonModalOff</span></p>
                            </div>
                        </div>
                        <button class="modal-close is-large" aria-label="close"></button>
                    </div>
                    BLOCK
                }
                default {''}
            }
        },
    )
}
method edit-scss {
    q:to/SCSS/;
        .page-edit {
            right: 1vw;
            position: fixed;
            top: 15vh;
            z-index: 10;

            .page-edit-button.tooltip {
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
        }
    SCSS
}
method modal-scss {
    q:to/SCSS/;
        #page-browser-editor .modal-content {
            width: 80vw;
            .box { height: 80vh; }
            p { text-align: center; }
        }
        .edit-preview-box {
            height: 95%;
            #editor-panel, #preview-panel {
                display: flex;
                flex-direction: column;
                div:first-child { align-self: center; }
            }
            #editor, #preview {
                border: gray solid 1px;
                border-radius: 5px;
                margin-bottom: 1.5em;
            }
        }
        @media screen and (min-width: 1024px){
            .edit-preview-box {
                display: flex;
                flex-direction: row;
                padding-bottom: 10px;
                gap: 5px;
                #editor-panel, #preview-panel { flex-grow: 1; }
                #editor { height: 60vh; }
                #preview { height: 90%; width: 100%; }
            }
        }
        @media screen and (max-width: 1023px){
            .edit-preview-box {
                display: flex;
                flex-direction: column;
                #editor { height: 30vh; }
                #preview { width: 100%; }
            }
        }
        .buttonPanel {
            display: flex;
            flex-direction: row;
            margin-bottom: 10px;
            justify-content: space-around;
            .button {
                width: fit-content;
            }
        }
        #socketIndicator {
            padding:0 3px;
            margin-bottom: 10px;
            border: double 2px;
            border-radius: 5px;
            width:fit-content;
            padding:10px;
            &[data-openchannel="off"] {
                border-color: red;
            }
            &[data-openchannel="on"] {
                border-color: green;
            }
        }
    SCSS
}
method browser-js {
    q:to/JS/;
        var url;
        var editor;
        var preview;
        var socketIndicator;
        var renderSocket;
        // check if a websocket is open
        const renderIsOpen = function(ws) {
            return ws.readyState === ws.OPEN
        }
        function sendSource() {
            let source = editor.session.getValue();
            if(renderIsOpen(renderSocket)) {
                renderSocket.send(JSON.stringify({
                    "source" : source
                }))
            }
        }
        function fetchText(url) {
            fetch(url)
                .then( (response) => response.text() )
                .then( (text) => {
                    editor.session.setValue( text );
                    sendSource();
                });
        }
        document.addEventListener('DOMContentLoaded', function () {
            preview = document.getElementById('preview');
            renderContent = document.getElementById('getHTML');
            revert = document.getElementById('revertToContent');
            socketIndicator = document.getElementById('socketIndicator');
            editActivate = document.getElementById('Edit-browser-activate');
            editActivate.addEventListener('click', (activated) => {
                url = activated.currentTarget.dataset.editurl;
                // credit: This javascript file is adapted from
                // https://fjolt.com/article/javascript-websockets
                // Connect to the websocket
                // This will let us create a connection to our Server websocket.
                const connect = function() {
                    // Return a promise, which will wait for the socket to open
                    return new Promise((resolve, reject) => {
                        // This calculates the link to the websocket.
                        const socketUrl = `wss://${renderWebsocketHost}/rakudoc_render`;
                        renderSocket = new WebSocket(socketUrl);

                        // This will fire once the socket opens
                        renderSocket.onopen = (e) => {
                            // Send a little test data, which we can use on the server if we want
                            renderSocket.send(JSON.stringify({ "loaded" : true }));
                            // Resolve the promise - we are connected
                            resolve();
                        }

                        // This will fire when the server sends the user a message
                        renderSocket.onmessage = (data) => {
                            let parsedData = JSON.parse(data.data);
                            if (parsedData.connection == 'Confirmed') {
                                socketIndicator.dataset.openchannel = 'on';
                            }
                            else {
                                preview.srcdoc = parsedData.html;
                            }
                        }
                        // This will fire on error
                        renderSocket.onerror = (e) => {
                            // Return an error if any occurs
                            console.log(e);
                            socketIndicator.dataset.openchannel = 'off';
                            resolve();
                            // Try to connect again
                            connect();
                        }
                    });
                }
                editor = ace.edit("editor");
                editor.setOptions({
                   fontSize: "100%",
                   behavioursEnabled: true,
                   autoScrollEditorIntoView: true
                });
                fetchText(url);
                connect();
            });
            renderContent.addEventListener('click', () => {
                sendSource();
            });
            revert.addEventListener('click', () => {
                fetchText(url);
            });
        });
    JS
}
