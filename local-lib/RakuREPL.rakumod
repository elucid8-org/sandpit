use v6.d;
use RakuDoc::Render;

unit class Raku-Doc-Website::RakuREPL;
has %.config =
        :name-space<RakuREPL>,
        :version<0.1.0>,
        :license<Artistic-2.0>,
        :credit<finanalyst>,
        :authors<finanalyst>,
        :websocket-port<12345>,
        :websocket-host<0.0.0.0>,
        set-host-port => -> %final-config { self.set-host-port( %final-config ) },
        js => [ [self.repl-js,2], ],
        :scss([self.repl-scss,1],),
        ui-tokens => %(
            :REPL-label('Raku bar'),
            :REPL-label-tip('Enable a bar that evaluates Raku code'),
            :REPL-label-on('Enabled'),
            :REPL-label-off('Disabled'),
            :REPL-button-tip-on('Click to toggle eval panel'),
            :REPL-button-tip-off('No connection to eval server'),
            :REPL-output('Output'),
            :REPL-error('Errors'),
            :REPL-code('Raku code'),
            :REPL-code-tip("Type some Raku code, then click 'Shift Enter' or :sync icon to evaluate"),
            :REPL-code-evaluate('Evaluate Raku code'),
        );

method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-templates($.repl-templates, :source<Raku-doc-website plugin>)
}
method set-host-port( %final-config ) {
    my $js = qq:to/VARS/;
    var websocketPort =  '{ %final-config<RakuREPL><websocket-port> // %!config<websocket-port> }';
    var websocketHost =  '{ %final-config<RakuREPL><websocket-host> // %!config<websocket-host> }';
    VARS
    %!config<js>.push: [  $js, 1 ] ; # the script with host/port has to be before the repl-js script
}
method repl-js {
    q:to/JS/
        // Raku REPL
        // credit: This javascript file is adapted from
        // https://fjolt.com/article/javascript-websockets
        // @connect
        // Connect to the websocket
        let socket;
        // This will let us create a connection to our Server websocket.
        // For this to work, your websocket needs to be running with node index.js
        const connect = function() {
            // Return a promise, which will wait for the socket to open
            return new Promise((resolve, reject) => {
                // This calculates the link to the websocket.
                const socketProtocol = (window.location.protocol === 'https:' ? 'wss:' : 'ws:');
                const socketUrl = `${socketProtocol}//${websocketHost}:${websocketPort}/raku_repl`;
                socket = new WebSocket(socketUrl);

                // This will fire once the socket opens
                socket.onopen = (e) => {
                    // Send a little test data, which we can use on the server if we want
                    socket.send(JSON.stringify({ "loaded" : true }));
                    // Resolve the promise - we are connected
                    resolve();
                }

                // This will fire when the server sends the user a message
                socket.onmessage = (data) => {
                    let parsedData = JSON.parse(data.data);
                    if (parsedData.connection == 'Confirmed') {
                        document.getElementById('repl-toggle').dataset.openchannel = 'on';
                    }
                    const resOut = document.getElementById('raku-ws-stdout');
                    const resErr = document.getElementById('raku-ws-stderr');
                    resOut.textContent = parsedData.stdout;
                    resErr.textContent = parsedData.stderr;
                }
                // This will fire on error
                socket.onerror = (e) => {
                    // Return an error if any occurs
                    console.log(e);
                    document.getElementById('repl-toggle').dataset.openchannel = 'off';
                    document.getElementById('raku-toggle').click();
                    resolve();
                    // Try to connect again
                    connect();
                }
            });
        }

        // @isOpen
        // check if a websocket is open
        const isOpen = function(ws) {
            return ws.readyState === ws.OPEN
        }
        function sendCode() {
            let code = document.getElementById('raku-code').value;
            if(isOpen(socket)) {
                socket.send(JSON.stringify({
                    "code" : code
                }))
            }
        }
        // When the document has loaded
        document.addEventListener('DOMContentLoaded', function() {
            var replEnabled = false;
            var barVisible = false;
            replObject = document.getElementById('raku-repl');
            document.getElementById('repl-enable').checked = replEnabled;
            // And add our event listeners
            document.getElementById('repl-enable').addEventListener('change' , function(e) {
                replEnabled = e.target.checked;
                if ( replEnabled ) {
                    if ( socket == null ) {
                        // Connect to the websocket
                        connect();
                    }
                    replObject.classList.remove('is-hidden');
                }
                else {
                    replObject.classList.add('is-hidden');
                }
            });
            document.getElementById('raku-evaluate').addEventListener('click', function(e) {
                sendCode();
            });
            document.getElementById('raku-code').addEventListener('keydown', function(event, ui) {
                if (event.keyCode == 13 && event.shiftKey) {
                    event.stopPropagation();
                    sendCode();
                }
           });
            document.getElementById('repl-toggle').addEventListener('click', function() {
                if ( barVisible ) {
                    document.getElementById('repl-panel').classList.add('is-hidden') ;
                    barVisible = false;
                }
                else if (isOpen(socket) ) {
                    document.getElementById('repl-panel').classList.remove('is-hidden');
                    barVisible = true;
                }
            });
        });
        JS

}
method repl-templates { %(
my $old = q:to/REPL/;
        <div id="raku-repl" class="is-hidden">
            <div id="raku-code-icon" title="Click to get Raku evaluation bar">
                <i class="fas fa-laptop-code fa-2x"></i>
            </div>
            <div id="raku-input">
                <textarea rows="1" cols="40" id="raku-code" placeholder="Type some Raku code and Click 'Run'"></textarea>
                <button id="raku-evaluate" title="Evaluate Raku code" disabled>Run</button>
                <button id="raku-hide" title="Close evaluation bar">
                    <i class="far fa-times-circle fa-2x"></i>
                </button>
                <div id="raku-connection" title="Waiting for connection">
                    <i class="fas fa-sync fa-spin fa-2x fa-fw"></i>
                </div>
            </div>
            <fieldset id="raku-ws-headout"><legend>Output</legend>
                <div id="raku-ws-stdout"></div>
            </fieldset>
            <fieldset id="raku-ws-headerr"><legend>Errors</legend>
                <div id="raku-ws-stderr"></div>
            </fieldset>
        </div>
        REPL
    modal-container => -> %prm, $tmpl {
        $tmpl.prev ~ Q:c:to/REPL/;
            <div class="panel is-hidden" id="raku-repl">
                <div class="columns is-hidden" id="repl-panel">
                    <div class="column">
                        <span class="Elucid8-ui" data-UIToken="REPL-code">REPL-code</span>
                        <button id="raku-evaluate" class="tooltip has-text-primary">
                            <span class="icon">
                                <i class="fas fa-sync-alt"></i>
                            </span>
                            <span class="Elucid8-ui tooltiptext" data-UIToken="REPL-code-evaluate">REPL-code-evaluate</span>
                       </button>
                        <button id="raku-question" class="tooltip has-text-info">
                            <span class="icon">
                                <i class="fas fa-question"></i>
                            </span>
                            <span class="Elucid8-ui tooltiptext" data-UIToken="REPL-code-tip">REPL-code-tip</span>
                        </button>

                        <textarea rows="1" cols="40" id="raku-code"></textarea>
                    </div>
                    <div id="repl-output-panel" class="column">
                        <fieldset id="raku-ws-headout">
                            <legend>
                                <span class="Elucid8-ui" data-UIToken="REPL-output">REPL-output</span>
                            </legend>
                            <div id="raku-ws-stdout"></div>
                        </fieldset>
                    </div>
                    <div id="repl-error-panel" class="column">
                        <fieldset id="raku-ws-headerr">
                            <legend>
                                <span class="Elucid8-ui" data-UIToken="REPL-error">REPL-error</span>
                            </legend>
                            <div id="raku-ws-stderr"></div>
                        </fieldset>
                    </div>
                </div>
                <div id="repl-toggle" data-openchannel="off">
                    <div class="button repl-button tooltip">
                        <span class="icon">
                            <i class="fas fa-terminal is-medium"></i>
                        </span>
                        <span class="Elucid8-ui tooltiptext on" data-UIToken="REPL-button-tip-on">REPL-button-tip-on</span>
                        <span class="Elucid8-ui tooltiptext off" data-UIToken="REPL-button-tip-off">REPL-button-tip-off</span>
                    </div>
                </div>
            </div>
        REPL
    },
    drop-down-list => -> %prm, $tmpl {
        $tmpl.prev ~ Q:c:to/BLOCK/;
                <hr class="navbar-divider">
                <label class="tooltip optionToggle navbar-item">
                    <span class="Elucid8-ui text" data-UIToken="REPL-label">REPL-label</span>
                    <span class="tooltiptext Elucid8-ui" data-UIToken="REPL-label-tip">REPL-label-tip</span>
                    <input id="repl-enable" type="checkbox">
                    <span class="Elucid8-ui off" data-UIToken="REPL-label-off">REPL-label-off</span>
                    <span class="Elucid8-ui on" data-UIToken="REPL-label-on">REPL-label-on</span>
                </label>
        BLOCK
    }
)}
my $old = q:to/SCSS/;
        #raku-repl {
            position: fixed;
            bottom: 15vh;
            left: 1vw;
            width: 98vw;
            z-index: 60;
            opacity: 80%;
            display: grid;
            grid-template-columns: 1fr 1fr;
            grid-template-rows: auto;
            justify-content: stretch;
            grid-template-areas:
                "input input"
                "stdout stderr"
        }
        #raku-code-icon {
            visibility: hidden;
            width: 48px;
            height: 48px;
            grid-area: input-start;
            background-color: #004FB3;
            color: #fff;
            cursor: pointer;
            border-width: 1px;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        #raku-input {
            display: flex;
            flex-direction: row;
            grid-area: input;
            gap: 5px;
        }
        #raku-code {
            border-color: darkblue;
            border-width: 2px;
            border-radius: 10px;
            border-style: ridge;
            visibility: inherit;
            background-color: whitesmoke;
        }
        #raku-evaluate {
            visibility: inherit;
            border-width: 1px;
            padding: 1em;
            font-weight: bold;
            background-color: #004FB3;
            color: #fff;
            cursor: pointer;
            border-width: 1px;
            &:not([disabled]):hover {
                color: red;
            }
            &:disabled {
                background-color: grey;
            }
        }
        #raku-hide {
            visibility: inherit;
            background-color: #004FB3;
            color: #fff;
            img {
                width: 45px;
                position: fixed;
            }
        }
        #raku-connection {
            border-width: 1px;
            padding: 0.3em;
            align-self: center;
            font-weight: bold;
            background-color: #004FB3;
            color: #fff;
        }

        #raku-ws-headout {
            border-color: deepskyblue;
            border-width: 2px;
            border-radius: 10px;
            border-style: ridge;
            grid-area: stdout;
            display: flex;
            justify-content: start;
            background-color: whitesmoke;
            visibility: inherit;
            legend {
                color: darkblue;
            visibility: inherit;
            }
        }
        #raku-ws-headerr {
            border-color: deeppink;
            border-width: 2px;
            border-radius: 10px;
            border-style: ridge;
            grid-area: stderr;
            display: flex;
            justify-content: start;
            background-color: whitesmoke;
            visibility: inherit;
            legend {
                color: darkred;
            }
        }
    SCSS
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
            margin: 10px;
        }
        #repl-toggle {
            right: 1vw;
            position: fixed;
            top: 25vh;
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
        }
        #raku-ws-headout,  #raku-ws-headerr {
            border-color: var(--bulma-primary);
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
        }
        #raku-ws-headerr {
            border-color: var(--bulma-danger);
        }
        #raku-ws-stderr {
            padding: 0 10px;
        }
    }
    SCSS
}
