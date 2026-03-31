#!/usr/bin/env zsh

# ─── Configuration ─────────────────────────────────────────────────────────

# Default to docs directory in dotfiles if it exists
if [[ -z "$OBSIDIAN_VAULT" || "$OBSIDIAN_VAULT" == "." ]]; then
    if [[ -d "$DOTFILES/docs" ]]; then
        export OBSIDIAN_VAULT="$DOTFILES/docs"
    else
        export OBSIDIAN_VAULT="."
    fi
fi

export OBSIDIAN_SYSTEM=$(fs.dotfiles.path "assets/configs/obsidian/_system")
export OBSIDIAN_RULES="$OBSIDIAN_SYSTEM/rules"
export OBSIDIAN_NOTES="$OBSIDIAN_RULES/notes"
export OBSIDIAN_FIELDS="$OBSIDIAN_RULES/fields"
export OBSIDIAN_DATE_FORMAT="%Y-%m-%dT%H:%M:%S%z"

# ─── Rule Helpers ──────────────────────────────────────────────────────────


# @description Load a rule file for a specific note type or field
obsidian.rules.note() {
  local type="$1" field="$2" file
  if [[ -n "$field" ]]; then
    file="$OBSIDIAN_FIELDS/${field}.${type}.md"
    [[ ! -f "$file" ]] && file="$OBSIDIAN_FIELDS/${field}.md"
  else
    file="$OBSIDIAN_NOTES/${type}.md"
  fi
  [[ -f "$file" ]] && echo "$file"
}

# ─── Note Operations ───────────────────────────────────────────────────────

# @description Find notes where an attribute matches any provided values
obsidian.find.byAttribute() {
  local attribute_name="$1"
  shift
  local -a search_values=($@)
  [[ ${#search_values} -eq 0 ]] && return 0

  # Discover candidate files first for speed
  local -a candidate_files=(${(f)"$(grep -rlE "^${attribute_name}\s*:" "$OBSIDIAN_VAULT" --include="*.md" 2>/dev/null)"})
  candidate_files=(${candidate_files:#})
  [[ ${#candidate_files} -eq 0 ]] && return 0

  # Export search values as env vars for yq
  export ATTR="$attribute_name"
  local match_expr=""
  for i in {1..${#search_values}}; do
    export "MATCH_VAL_${i}=${search_values[$i]}"
    match_expr+=". == strenv(MATCH_VAL_${i})"
    [[ $i -lt ${#search_values} ]] && match_expr+=' or '
  done

  markdown.frontmatter.get.all "${candidate_files[@]}" | yq -r -N "
    select(
      [ .[strenv(ATTR)] ] | flatten | .[] | select(. != null) |
      ((select(tag == \"!!str\") | sub(\"^\\\\\\\[\\\\\\\[\", \"\") | sub(\"\\\\\\\]\\\\\\\]$\", \"\")) // .) |
      select($match_expr)
    ) | .path
  " 2>/dev/null | sort -u
}

# @description List all note filenames of specific types
obsidian.type.filenames() {
  local -a paths=(${(f)"$(obsidian.find.byAttribute "type" "$@")"})
  [[ ${#paths} -eq 0 ]] && return 0
  printf "%s\n" "${paths[@]}" | xargs -n1 basename -s .md -- | sort -u
}

# @description Collect unique values for a frontmatter attribute
obsidian.attribute.values() {
  local attribute_name="$1"
  local -a candidate_files=(${(f)"$(grep -rlE "^${attribute_name}\s*:" "$OBSIDIAN_VAULT" --include="*.md" 2>/dev/null)"})
  candidate_files=(${candidate_files:#}) 
  [[ ${#candidate_files} -eq 0 ]] && return 0

  export ATTR="$attribute_name"
  markdown.frontmatter.get.all "${candidate_files[@]}" | yq -r -N '
    [ .[strenv(ATTR)] ] | flatten | .[] | select(. != null) |
    (select(tag == "!!str") | sub("^\\\[\\\[", "") | sub("\\\]\\\]$", "")) // .
  ' 2>/dev/null | sort -u
}

obsidian.note.resolve_path() {
  local input_path="$1"
  
  # 1. Handle folder-prefixed paths (e.g., Folder/Note)
  if [[ "$input_path" == */* ]]; then
    local absolute_path="$OBSIDIAN_VAULT/$input_path.md"
    [[ -f "$absolute_path" ]] && { echo "$absolute_path"; return 0; }
  fi

  # 2. Exact filename match anywhere in vault (fast)
  # Strip folder prefix if present for the find command
  local base_name="${input_path##*/}"
  local filename_match=$(find "$OBSIDIAN_VAULT" -name "$base_name.md" | head -n 1)
  [[ -n "$filename_match" ]] && { echo "$filename_match"; return 0; }

  # 3. Search by title attribute in frontmatter
  obsidian.find.byAttribute "title" "$base_name" | head -n 1
}

# ─── Field Prompting ───────────────────────────────────────────────────────

# @description Prompt for a field based on rules
obsidian.rules.field() {
  local -a flags=()
  local field_name="$1"
  local note_type="$2"
  local is_optional="${3:-false}"
  
  # Load rule and determine UI type
  local rule_file=$(obsidian.rules.note "$note_type" "$field_name")
  local rule_fm=$(markdown.frontmatter.get "$rule_file" 2>/dev/null)
  local field_type=$(echo "$rule_fm" | yq -r '.type // "text"')
  
  [[ "$is_optional" == "true" ]] && flags+=("-o")

  case "$field_type" in
    select|multi-select)
      [[ "$field_type" == "multi-select" ]] && flags+=("-m")
      [[ "$(echo "$rule_fm" | yq -r '.values_allow_custom // "false"')" == "true" ]] && flags+=("-c")
      
      # Aggregate values from all configured sources
      local -a selection_values=()
      
      # 1. Hardcoded static values
      selection_values+=(${(f)"$(echo "$rule_fm" | yq -r '.values[]' 2>/dev/null)"})
      
      # 2. Dynamic values from existing note attributes
      local -a from_attrs=(${(f)"$(echo "$rule_fm" | yq -r '.values_from_attr[]' 2>/dev/null)"})
      for attr in "${from_attrs[@]}"; do
        selection_values+=(${(f)"$(obsidian.attribute.values "$attr")"})
      done
      
      # 3. Dynamic values from specific note types
      local -a from_note_types=(${(f)"$(echo "$rule_fm" | yq -r '.values_from_note_type[]' 2>/dev/null)"})
      if [[ ${#from_note_types} -gt 0 ]]; then
        selection_values+=(${(f)"$(obsidian.type.filenames "${from_note_types[@]}")"})
      fi

      # Clean up selection list: unique, no nulls, no empty strings
      selection_values=(${(u)selection_values#null})
      selection_values=(${selection_values:#})
      
      local -a picked=(${(f)"$(tui.select "${flags[@]}" "$field_name" "${selection_values[@]}")"}) || return 1
      [[ ${#picked} -eq 0 ]] && return 0
      
      local is_link=$(echo "$rule_fm" | yq -r '.is_link // "false"')
      if [[ "$is_link" == "true" ]]; then
        # Specialized manual formatting for Obsidian links
        local -l processed_links=()
        for p in "${picked[@]}"; do processed_links+=("\"[[$p]]\""); done
        local formatted
        [[ "$field_type" == "multi-select" ]] && formatted="[${(j:, :)processed_links}]" || formatted="${processed_links[1]}"
        printf "%s: %s" "$field_name" "$formatted"
      else
        # Use yq for robust YAML encoding of standard values
        if [[ "$field_type" == "multi-select" ]]; then
          local json_arr=$(printf "%s\n" "${picked[@]}" | yq -R '.' | yq -s '.' | yq -rc '.')
          printf "%s: %s" "$field_name" "$json_arr"
        else
          local yaml_val=$(V="${picked[1]}" yq -n 'strenv(V)' | yq -rc '.')
          printf "%s: %s" "$field_name" "$yaml_val"
        fi
      fi
      ;;
    *)
      # Default: Text input (with special handling for date)
      local default_value=$( [[ "$field_type" == "date" ]] && date +"$OBSIDIAN_DATE_FORMAT" )
      [[ -n "$default_value" ]] && flags+=("-d" "$default_value")
      
      local user_input=$(tui.input "${flags[@]}" "$field_name") || return 1
      [[ -z "$user_input" ]] && return 0
      
      # Use yq for robust YAML encoding of standard text input
      local yaml_val=$(V="$user_input" yq -n 'strenv(V)' | yq -rc '.')
      printf "%s: %s" "$field_name" "$yaml_val"
      ;;
  esac
}

# ─── Main Note Creation ────────────────────────────────────────────────────

# @description Core workflow to create a new note
obsidian.note.new() {
  # 1. Validation: Ensure we are in a valid Obsidian environment
  if [[ ! -d "$OBSIDIAN_NOTES" ]]; then
    echo "❌ Error: Notes rules directory not found at '$OBSIDIAN_NOTES'." >&2
    echo "   Ensure \$DOTFILES is set correctly and the rules exist in assets/configs/obsidian/_system." >&2
    return 1
  fi

  # 1. Selection: Note Type
  local -a available_note_types=($OBSIDIAN_NOTES/*.md(N:t:r))
  if [[ ${#available_note_types} -eq 0 ]]; then
    echo "❌ Error: No note type rules found in '$OBSIDIAN_NOTES'." >&2
    return 1
  fi

  local chosen_note_type=$(tui.select "Type" "${available_note_types[@]}") || return 1
  
  # 2. Extract configuration from the chosen rule file
  local rule_fm=$(markdown.frontmatter.get "$(obsidian.rules.note "$chosen_note_type")")
  local note_type_identifier=$(echo "$rule_fm" | yq -r '.for')
  
  local -a required_fields=(${(f)"$(echo "$rule_fm" | yq -r '.required_fields[]' 2>/dev/null)"})
  local -a optional_fields=(${(f)"$(echo "$rule_fm" | yq -r '.optional_fields[]' 2>/dev/null)"})
  local -a require_one_parents=(${(f)"$(echo "$rule_fm" | yq -r '.require_one[]' 2>/dev/null)"})
  local -a one_or_none_parents=(${(f)"$(echo "$rule_fm" | yq -r '.one_or_none[]' 2>/dev/null)"})
  local -a write_preferences=(${(f)"$(echo "$rule_fm" | yq -r '.write_preference[]' 2>/dev/null)"})
  local base_folder=$(echo "$rule_fm" | yq -r '.folder' 2>/dev/null)

  # 3. Interactive Input: Core Metadata
  local note_title=$(tui.input "Title") || return 1
  
  local -a frontmatter_lines=()
  frontmatter_lines+=("type: $note_type_identifier")
  frontmatter_lines+=("title: $(V="$note_title" yq -n 'strenv(V)')")
  frontmatter_lines+=("created: $(date +"$OBSIDIAN_DATE_FORMAT")")

  # 4. Parent Type Selection (Inject into field lists)
  if [[ ${#require_one_parents} -gt 0 ]]; then
    local pt
    pt=$(tui.select "Parent Type" "${require_one_parents[@]}") || return 1
    required_fields=("$pt" "${(@)required_fields:#$pt}")
  fi

  if [[ ${#one_or_none_parents} -gt 0 ]]; then
    local pt=$(tui.select -o "Optional Parent Type" "${one_or_none_parents[@]}") || true
    [[ -n "$pt" ]] && optional_fields=("$pt" "${(@)optional_fields:#$pt}")
  fi

  # 5. Metadata Collection Loop
  local field_output
  for field in "${required_fields[@]}"; do 
    field_output=$(obsidian.rules.field "$field" "$note_type_identifier" "false") || return 1
    frontmatter_lines+=("$field_output")
  done
  
  for field in "${optional_fields[@]}"; do 
    field_output=$(obsidian.rules.field "$field" "$note_type_identifier" "true") || return 1
    [[ -n "$field_output" ]] && frontmatter_lines+=("$field_output")
  done

  # 6. Folder Resolution Logic
  # prioritized 'write_preference' search in the final frontmatter
  local target_folder_path="$OBSIDIAN_VAULT/$base_folder"
  
  for preference in "${write_preferences[@]}"; do
    local match_val=$(printf "%s\n" "${frontmatter_lines[@]}" | ATTR="$preference" yq -r '
      [ .[strenv(ATTR)] ] | flatten | .[0] | select(. != null) |
      (select(tag == "!!str") | sub("^\\\[\\\[", "") | sub("\\\]\\\]$", "")) // .
    ' 2>/dev/null)
    
    if [[ -n "$match_val" ]]; then
       local resolved_path=$(obsidian.note.resolve_path "$match_val")
       if [[ -n "$resolved_path" ]]; then
          target_folder_path="$(dirname "$resolved_path")/$match_val/$base_folder"
          break
       fi
    fi
  done
  
  # 7. Finalize: Create directory and write file
  mkdir -p "$target_folder_path"
  local final_note_path="$target_folder_path/${note_title// /-}.md"
  
  {
    echo "---"
    printf "%s\n" "${frontmatter_lines[@]}"
    echo "---"
    echo ""
  } > "$final_note_path"
  
  echo "Created: $final_note_path"
}

# Aliases
alias onn='obsidian.note.new'
alias ofa='obsidian.find.byAttribute'
alias oav='obsidian.attribute.values'
