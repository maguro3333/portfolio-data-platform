select
  {{ string_cast('content_id') }} as content_id,
  {{ string_cast('title') }} as title,
  lower({{ string_cast('content_type') }}) as content_type,
  {{ string_cast('author') }} as author,
  {{ timestamp_cast('published_at') }} as published_at,
  {{ string_cast('content_group') }} as content_group,
  {{ nullable_string('target_category') }} as target_category,
  {{ nullable_string('page_path') }} as page_path,
  {{ bool_cast('is_active') }} as is_active,
  {{ timestamp_cast('created_at') }} as created_at,
  {{ timestamp_cast('updated_at') }} as updated_at
from {{ raw_relation('dim_content') }}
