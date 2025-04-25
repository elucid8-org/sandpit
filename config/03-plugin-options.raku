%(
    plugin-options => %(
        SiteMap => %(
            :root-domain<https://new-raku.finanalyst.org>,
        ),
        RakuREPL => %(
            :repl-websocket('wss://finanalyst.org/raku_repl'),
        ),
        Edit-In-Browser => %(
            :render-websocket('wss://finanalyst.org/rakudoc_render'),
            :suggestion-websocket('wss:finanalyst.org/suggestion_box'),
            :patch-limit(5120), # limit on length of patch 5k chars
        ),
    ),
)
