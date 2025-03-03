%(
    rakuast-rakudoc-plugins => <
      Hilite
      ListFiles
      Graphviz FontAwesome Latex LeafletMaps
      SCSS
    >,
    plugins => <
        UISwitcher
        Raku-Doc-Website
        AutoIndex
        SiteData
        DataTable
        Search
    >,
    pre-file-render => ( # sequence because order matters
        SiteData => 'initialise',
    ),
    post-file-render => %(),
    post-all-content-files => ( # sequence because order matters
        SiteData => 'gen-composites',
        Search => 'prepare-search-data',
    ),
    post-all-files => ( # sequence because order matters
    )
)
