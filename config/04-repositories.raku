%(
    :repository-store<repos>,
    repositories => %(
        raku-docs-en => %(
            repo-name => 'Raku/doc',
            source-entry => 'doc/',
            destination => 'en',
            description => 'documentation of the Raku language',
        ),
        rakudoc-en => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            source-entry => '/',
            destination => 'en/language',
            description => 'Rakudoc specification document',
            :ignore<README compliance-document/rakudociem-ipsum compliance-files/bootiful-disclaimer>,
        ),
        doc-website => %(
            destination => 'en',
            description => 'website sources',
            repo-name => '',
            source-entry => 'sources/en',
        )
    ),
)
