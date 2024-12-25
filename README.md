
# A distribution intended for testing Elucid8

----

## Table of Contents

<a href="#Assumptions">Assumptions</a>   


<div id="Assumptions"></div>

## Assumptions
<span class="para" id="e7ea0bd"></span>The Build component of Elucid8 assumes the following structure. 


```
sandpit                      # a test bed for a web site built with elucid8
    - config/                 # contains the website configuration
    - L10N/                  # contains the dictionaries from the canonical to derived languages
    - sources/
      - canonical/          # RakuDoc content in canonical language
      - xx/                     # content in language with code xx
      - xx-YY/               # regional content in language with code xx-YY
```
<span class="para" id="48e6de8"></span>All names in the structure, except for `config/`, may be modified by changing fields in the files in `config/`.



----

----

Rendered from docs/README.rakudoc/README at 12:39 UTC on 2024-12-25

Source last modified at 12:36 UTC on 2024-12-25

