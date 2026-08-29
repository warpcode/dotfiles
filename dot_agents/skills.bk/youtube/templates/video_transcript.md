# {{ title }}

**URL:** {{ url }}
**Channel:** {{ uploader }}
**Published:** {{ upload_date }}
**Duration:** {{ duration_string }}

## Description

{{ description }}

## Transcript

{% for s in transcript -%}
[{{ s.start_display }}] {{ s.text }}
{% endfor -%}
