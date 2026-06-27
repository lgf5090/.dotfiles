_github_api_base=https://api.github.com

_github_usage() {
  cat <<'EOF'
github - small GitHub REST API helper

usage:
  github -h | --help
  github [field ...]
  github -r OWNER/REPO [repo-option] [field ...]
  github -u USER [user-option] [field ...]
  github -o ORG [org-option] [field ...]
  github -g GIST_ID [field ...]
  github --api PATH [field ...]
  github -s QUERY [--limit N] [--pages N] [field ...]
  github --search-repos QUERY [field ...]
  github --search-users QUERY [field ...]
  github --search-issues QUERY [field ...]
  github --search-code QUERY [field ...]

authentication:
  If GITHUB_TOKEN is set, requests use:
    Authorization: Bearer $GITHUB_TOKEN
  Else if GH_TOKEN is set, requests use:
    Authorization: Bearer $GH_TOKEN
  Authenticated requests have a higher GitHub rate limit.

defaults:
  github
      curl https://api.github.com/repos/ollama/ollama
  github -r ollama/ollama
      curl https://api.github.com/repos/ollama/ollama

common options:
  -r, --repo OWNER/REPO       repo endpoint, default: ollama/ollama
  -u, --user USER             user endpoint
  -o, --org ORG               organization endpoint
  -g, --gist GIST_ID          gist endpoint
  -a, --api PATH              raw GitHub API path
  -s, --search QUERY          search repositories and show a ranked summary
  -q, --query KEY=VALUE       append query parameter, repeatable
  --limit N                   limit displayed search rows, default: 15
  --pages N                   fetch N search result pages before ranking, default: 1
  --jq FILTER                 run a raw jq filter against the response
  --url                       print the API URL instead of requesting it
  -h, --help                  show this help

repo options:
  github [-r OWNER/REPO] --issues [field ...]
      GET /repos/OWNER/REPO/issues
  github [-r OWNER/REPO] --issue NUMBER [field ...]
      GET /repos/OWNER/REPO/issues/NUMBER
  github [-r OWNER/REPO] --pulls [field ...]
      GET /repos/OWNER/REPO/pulls
  github [-r OWNER/REPO] --pull NUMBER [field ...]
      GET /repos/OWNER/REPO/pulls/NUMBER
  github [-r OWNER/REPO] --releases [field ...]
      GET /repos/OWNER/REPO/releases
  github [-r OWNER/REPO] --release TAG [field ...]
      GET /repos/OWNER/REPO/releases/tags/TAG
  github [-r OWNER/REPO] --latest-release [field ...]
      GET /repos/OWNER/REPO/releases/latest
  github [-r OWNER/REPO] --branches [field ...]
      GET /repos/OWNER/REPO/branches
  github [-r OWNER/REPO] --branch NAME [field ...]
      GET /repos/OWNER/REPO/branches/NAME
  github [-r OWNER/REPO] --commits [field ...]
      GET /repos/OWNER/REPO/commits
  github [-r OWNER/REPO] --commit SHA [field ...]
      GET /repos/OWNER/REPO/commits/SHA
  github [-r OWNER/REPO] --contents PATH [field ...]
      GET /repos/OWNER/REPO/contents/PATH
  github [-r OWNER/REPO] --contributors [field ...]
      GET /repos/OWNER/REPO/contributors
  github [-r OWNER/REPO] --languages [field ...]
      GET /repos/OWNER/REPO/languages
  github [-r OWNER/REPO] --tags [field ...]
      GET /repos/OWNER/REPO/tags
  github [-r OWNER/REPO] --topics [field ...]
      GET /repos/OWNER/REPO/topics
  github [-r OWNER/REPO] --stargazers [field ...]
      GET /repos/OWNER/REPO/stargazers
  github [-r OWNER/REPO] --subscribers [field ...]
      GET /repos/OWNER/REPO/subscribers
  github [-r OWNER/REPO] --forks [field ...]
      GET /repos/OWNER/REPO/forks
  github [-r OWNER/REPO] --workflows [field ...]
      GET /repos/OWNER/REPO/actions/workflows

user options:
  github -u USER [field ...]
      GET /users/USER
  github -u USER --repos [field ...]
      GET /users/USER/repos
  github -u USER --followers [field ...]
      GET /users/USER/followers
  github -u USER --following [field ...]
      GET /users/USER/following
  github -u USER --gists [field ...]
      GET /users/USER/gists
  github -u USER --starred [field ...]
      GET /users/USER/starred
  github -u USER --orgs [field ...]
      GET /users/USER/orgs
  github -u USER --events [field ...]
      GET /users/USER/events

org options:
  github -o ORG [field ...]
      GET /orgs/ORG
  github -o ORG --repos [field ...]
      GET /orgs/ORG/repos
  github -o ORG --members [field ...]
      GET /orgs/ORG/members
  github -o ORG --teams [field ...]
      GET /orgs/ORG/teams
  github -o ORG --events [field ...]
      GET /orgs/ORG/events

gist, raw api, and search:
  github -g GIST_ID [field ...]
      GET /gists/GIST_ID
  github --api PATH [field ...]
      GET /PATH, for example: github --api rate_limit
  github -s wsl
      Search repositories for wsl, fetch one page, rank by stars, updated_at,
      created_at, and show the first 15 rows.
  github -s wsl --limit 30 --pages 2
      Fetch two search pages, rank locally, and show the first 30 rows.
  github --search-repos QUERY [field ...]
      GET /search/repositories?q=QUERY
  github --search-users QUERY [field ...]
      GET /search/users?q=QUERY
  github --search-issues QUERY [field ...]
      GET /search/issues?q=QUERY
  github --search-code QUERY [field ...]
      GET /search/code?q=QUERY

query parameters:
  github --issues -q state=open -q per_page=100
  github -u USER --repos -q sort=updated -q direction=desc

fields:
  Field names are jq paths. One field prints that value. Multiple fields
  print a JSON object with those keys.

  github id
  github id name owner.login
  github -u lgf-136 login id created_at
  github --jq '.owner.login'

completion:
  Bash completion suggests options and common fields for repo, user, org,
  gist, search, issue, pull, release, branch, commit, and contents responses.
EOF
}

_github_urlencode() {
  local value=$1 i char out=
  local LC_ALL=C

  for (( i = 0; i < ${#value}; i++ )); do
    char=${value:i:1}
    case $char in
      [a-zA-Z0-9.~_-]) out+=$char ;;
      ' ') out+=%20 ;;
      *) printf -v out '%s%%%02X' "$out" "'$char" ;;
    esac
  done

  printf '%s' "$out"
}

_github_json_string() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '"%s"' "$value"
}

_github_jq_expr() {
  local selector=$1 segment expr=.

  case $selector in
    .* | \[*)
      printf '%s' "$selector"
      return 0
      ;;
  esac

  while [[ $selector == *.* ]]; do
    segment=${selector%%.*}
    selector=${selector#*.}
    [[ -n $segment ]] || return 2
    expr+="[$(_github_json_string "$segment")]"
  done

  [[ -n $selector ]] || return 2
  expr+="[$(_github_json_string "$selector")]"
  printf '%s' "$expr"
}

_github_join_query() {
  local url=$1 query=$2

  if [[ -z $query ]]; then
    printf '%s' "$url"
  elif [[ $url == *\?* ]]; then
    printf '%s&%s' "$url" "$query"
  else
    printf '%s?%s' "$url" "$query"
  fi
}

github() {
  local kind=repo target=ollama/ollama path= raw_path= jq_filter= print_url=0
  local query= key value encoded_key encoded_value response
  local search_display=0 search_limit=15 search_pages=1
  local -a fields=() curl_args=()

  while (($#)); do
    case $1 in
      -h | --help)
        _github_usage
        return 0
        ;;
      -r | --repo)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires OWNER/REPO\n' "$1" >&2; return 2; }
        kind=repo
        target=$2
        path=
        shift 2
        ;;
      -u | --user)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires USER\n' "$1" >&2; return 2; }
        kind=user
        target=$2
        path=
        shift 2
        ;;
      -o | --org)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires ORG\n' "$1" >&2; return 2; }
        kind=org
        target=$2
        path=
        shift 2
        ;;
      -g | --gist)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires GIST_ID\n' "$1" >&2; return 2; }
        kind=gist
        target=$2
        path=
        shift 2
        ;;
      -a | --api)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires PATH\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=${2#/}
        path=
        shift 2
        ;;
      -s | --search)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires QUERY\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=search/repositories
        path=
        search_display=1
        encoded_value=$(_github_urlencode "$2")
        query="${query:+$query&}q=$encoded_value"
        shift 2
        ;;
      --search-repos)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires QUERY\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=search/repositories
        encoded_value=$(_github_urlencode "$2")
        query="${query:+$query&}q=$encoded_value"
        shift 2
        ;;
      --search-users)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires QUERY\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=search/users
        encoded_value=$(_github_urlencode "$2")
        query="${query:+$query&}q=$encoded_value"
        shift 2
        ;;
      --search-issues)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires QUERY\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=search/issues
        encoded_value=$(_github_urlencode "$2")
        query="${query:+$query&}q=$encoded_value"
        shift 2
        ;;
      --search-code)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: %s requires QUERY\n' "$1" >&2; return 2; }
        kind=raw
        raw_path=search/code
        encoded_value=$(_github_urlencode "$2")
        query="${query:+$query&}q=$encoded_value"
        shift 2
        ;;
      -q | --query)
        [[ $# -ge 2 && $2 == *=* ]] || { printf 'github: %s requires KEY=VALUE\n' "$1" >&2; return 2; }
        key=${2%%=*}
        value=${2#*=}
        encoded_key=$(_github_urlencode "$key")
        encoded_value=$(_github_urlencode "$value")
        query="${query:+$query&}$encoded_key=$encoded_value"
        shift 2
        ;;
      --limit)
        [[ $# -ge 2 && $2 =~ ^[0-9]+$ && $2 -gt 0 ]] || { printf 'github: --limit requires a positive integer\n' >&2; return 2; }
        search_limit=$2
        shift 2
        ;;
      --pages)
        [[ $# -ge 2 && $2 =~ ^[0-9]+$ && $2 -gt 0 ]] || { printf 'github: --pages requires a positive integer\n' >&2; return 2; }
        search_pages=$2
        shift 2
        ;;
      --jq)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --jq requires FILTER\n' >&2; return 2; }
        jq_filter=$2
        shift 2
        ;;
      --url)
        print_url=1
        shift
        ;;
      --issues)
        kind=repo
        path=issues
        shift
        ;;
      --issue)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --issue requires NUMBER\n' >&2; return 2; }
        kind=repo
        path="issues/$2"
        shift 2
        ;;
      --pulls)
        kind=repo
        path=pulls
        shift
        ;;
      --pull)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --pull requires NUMBER\n' >&2; return 2; }
        kind=repo
        path="pulls/$2"
        shift 2
        ;;
      --releases)
        kind=repo
        path=releases
        shift
        ;;
      --release)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --release requires TAG\n' >&2; return 2; }
        kind=repo
        path="releases/tags/$2"
        shift 2
        ;;
      --latest-release)
        kind=repo
        path=releases/latest
        shift
        ;;
      --branches)
        kind=repo
        path=branches
        shift
        ;;
      --branch)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --branch requires NAME\n' >&2; return 2; }
        kind=repo
        path="branches/$2"
        shift 2
        ;;
      --commits)
        kind=repo
        path=commits
        shift
        ;;
      --commit)
        [[ $# -ge 2 && -n $2 ]] || { printf 'github: --commit requires SHA\n' >&2; return 2; }
        kind=repo
        path="commits/$2"
        shift 2
        ;;
      --contents)
        [[ $# -ge 2 ]] || { printf 'github: --contents requires PATH\n' >&2; return 2; }
        kind=repo
        path="contents/${2#/}"
        shift 2
        ;;
      --contributors | --languages | --tags | --topics | --stargazers | --subscribers | --forks)
        kind=repo
        path=${1#--}
        shift
        ;;
      --workflows)
        kind=repo
        path=actions/workflows
        shift
        ;;
      --repos | --followers | --following | --gists | --starred | --orgs | --events | --members | --teams)
        path=${1#--}
        shift
        ;;
      --)
        shift
        fields+=("$@")
        break
        ;;
      -*)
        printf 'github: unknown option: %s\n' "$1" >&2
        return 2
        ;;
      *)
        fields+=("$1")
        shift
        ;;
    esac
  done

  case $kind in
    repo)
      [[ $target == */* ]] || { printf 'github: repo must be OWNER/REPO: %s\n' "$target" >&2; return 2; }
      raw_path="repos/$target${path:+/$path}"
      ;;
    user)
      raw_path="users/$target${path:+/$path}"
      ;;
    org)
      raw_path="orgs/$target${path:+/$path}"
      ;;
    gist)
      raw_path="gists/$target${path:+/$path}"
      ;;
  esac

  raw_path=${raw_path#/}
  local url="$_github_api_base/$raw_path"
  local url_query=$query
  if (( search_display )); then
    url_query="${query:+$query&}per_page=100&page=1"
  fi
  url=$(_github_join_query "$url" "$url_query")

  if (( print_url )); then
    printf '%s\n' "$url"
    return 0
  fi

  curl_args=(-fsSL)
  curl_args+=(-H 'Accept: application/vnd.github+json')
  curl_args+=(-H 'X-GitHub-Api-Version: 2022-11-28')
  if [[ -n ${GITHUB_TOKEN:-} ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  elif [[ -n ${GH_TOKEN:-} ]]; then
    curl_args+=(-H "Authorization: Bearer $GH_TOKEN")
  fi

  if (( search_display )); then
    command -v jq >/dev/null 2>&1 || { printf 'github: jq is required for formatted search output\n' >&2; return 127; }

    local page page_query page_url page_response field expr sep search_field
    local -a search_responses=()

    for (( page = 1; page <= search_pages; page++ )); do
      page_query="${query:+$query&}per_page=100&page=$page"
      page_url=$(_github_join_query "$_github_api_base/$raw_path" "$page_query")
      page_response=$(curl "${curl_args[@]}" "$page_url") || return
      search_responses+=("$page_response")
    done

    response=$(
      printf '%s\n' "${search_responses[@]}" |
        jq -s '{total_count: ((map(.total_count // 0) | max) // 0), incomplete_results: (map(.incomplete_results // false) | any), items: (map(.items // []) | add)}'
    ) || return

    if [[ -n $jq_filter ]]; then
      jq -r "$jq_filter" <<< "$response"
      return
    fi

    if (( ${#fields[@]} > 0 )); then
      if (( ${#fields[@]} == 1 )); then
        search_field=${fields[0]}
        [[ $search_field == items.* ]] && search_field=${search_field#items.}
        if [[ $search_field == items ]]; then
          expr=.
        else
          expr=$(_github_jq_expr "$search_field") || { printf 'github: invalid field: %s\n' "${fields[0]}" >&2; return 2; }
        fi
        jq_filter=".items | sort_by([(.stargazers_count // 0), (.updated_at // \"\"), (.created_at // \"\")]) | reverse | .[:\$limit][] | $expr"
      else
        jq_filter='.items | sort_by([(.stargazers_count // 0), (.updated_at // ""), (.created_at // "")]) | reverse | .[:$limit][] | {'
        sep=
        for field in "${fields[@]}"; do
          search_field=$field
          [[ $search_field == items.* ]] && search_field=${search_field#items.}
          [[ $search_field != items ]] || { printf 'github: invalid field with other fields: %s\n' "$field" >&2; return 2; }
          expr=$(_github_jq_expr "$search_field") || { printf 'github: invalid field: %s\n' "$field" >&2; return 2; }
          jq_filter+="$sep$(_github_json_string "$field"): $expr"
          sep=', '
        done
        jq_filter+='}'
      fi
      jq -r --argjson limit "$search_limit" "$jq_filter" <<< "$response"
      return
    fi

    jq -r --argjson limit "$search_limit" '(["stars","updated","created","repo","url","description"], (.items | sort_by([(.stargazers_count // 0), (.updated_at // ""), (.created_at // "")]) | reverse | .[:$limit][] | [((.stargazers_count // 0) | tostring), ((.updated_at // "")[0:10]), ((.created_at // "")[0:10]), (.full_name // ""), (.html_url // ""), ((.description // "") | gsub("[\t\r\n]+"; " "))])) | @tsv' <<< "$response"
    return
  fi

  if [[ -n $jq_filter || ${#fields[@]} -gt 0 ]]; then
    command -v jq >/dev/null 2>&1 || { printf 'github: jq is required when selecting fields\n' >&2; return 127; }

    if [[ -z $jq_filter ]]; then
      local field expr sep=
      if (( ${#fields[@]} == 1 )); then
        jq_filter=$(_github_jq_expr "${fields[0]}") || { printf 'github: invalid field: %s\n' "${fields[0]}" >&2; return 2; }
      else
        jq_filter='{'
        for field in "${fields[@]}"; do
          expr=$(_github_jq_expr "$field") || { printf 'github: invalid field: %s\n' "$field" >&2; return 2; }
          jq_filter+="$sep$(_github_json_string "$field"): $expr"
          sep=', '
        done
        jq_filter+='}'
      fi
    fi

    response=$(curl "${curl_args[@]}" "$url") || return
    jq -r "$jq_filter" <<< "$response"
    return
  fi

  curl "${curl_args[@]}" "$url"
}

_github_complete() {
  local cur prev word kind=repo sub= fields=repo
  local -a words
  local repo_options user_options org_options global_options search_options
  local repo_fields user_fields org_fields gist_fields issue_fields pull_fields release_fields branch_fields commit_fields contents_fields search_fields

  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  global_options='-h --help -r --repo -u --user -o --org -g --gist -a --api -s --search -q --query --limit --pages --jq --url'
  repo_options='--issues --issue --pulls --pull --releases --release --latest-release --branches --branch --commits --commit --contents --contributors --languages --tags --topics --stargazers --subscribers --forks --workflows'
  user_options='--repos --followers --following --gists --starred --orgs --events'
  org_options='--repos --members --teams --events'
  search_options='-s --search --search-repos --search-users --search-issues --search-code'

  repo_fields='id node_id name full_name owner private html_url description fork url forks_url keys_url collaborators_url teams_url hooks_url issue_events_url events_url assignees_url branches_url tags_url blobs_url git_tags_url git_refs_url trees_url statuses_url languages_url stargazers_url contributors_url subscribers_url subscription_url commits_url git_commits_url comments_url issue_comment_url contents_url compare_url merges_url archive_url downloads_url issues_url pulls_url milestones_url notifications_url labels_url releases_url deployments_url created_at updated_at pushed_at git_url ssh_url clone_url svn_url homepage size stargazers_count watchers_count language has_issues has_projects has_downloads has_wiki has_pages has_discussions forks_count mirror_url archived disabled open_issues_count license allow_forking is_template web_commit_signoff_required topics visibility forks open_issues watchers default_branch network_count subscribers_count organization parent source owner.login owner.id owner.node_id owner.avatar_url owner.html_url owner.type license.key license.name license.spdx_id'
  user_fields='login id node_id avatar_url gravatar_id url html_url followers_url following_url gists_url starred_url subscriptions_url organizations_url repos_url events_url received_events_url type site_admin name company blog location email hireable bio twitter_username public_repos public_gists followers following created_at updated_at plan'
  org_fields='login id node_id url repos_url events_url hooks_url issues_url members_url public_members_url avatar_url description name company blog location email twitter_username is_verified has_organization_projects has_repository_projects public_repos public_gists followers following html_url created_at updated_at type total_private_repos owned_private_repos private_gists disk_usage collaborators billing_email default_repository_permission members_can_create_repositories two_factor_requirement_enabled'
  gist_fields='url forks_url commits_url id node_id git_pull_url git_push_url html_url files public created_at updated_at description comments user comments_url owner truncated owner.login owner.id owner.avatar_url'
  issue_fields='url repository_url labels_url comments_url events_url html_url id node_id number title user labels state locked assignee assignees milestone comments created_at updated_at closed_at author_association active_lock_reason body closed_by reactions timeline_url performed_via_github_app state_reason user.login user.id pull_request'
  pull_fields='url id node_id html_url diff_url patch_url issue_url commits_url review_comments_url review_comment_url comments_url statuses_url number state locked title user body labels milestone active_lock_reason created_at updated_at closed_at merged_at merge_commit_sha assignee assignees requested_reviewers requested_teams head base author_association draft merged mergeable rebaseable mergeable_state merged_by comments review_comments maintainer_can_modify commits additions deletions changed_files user.login head.ref head.sha head.repo base.ref base.sha base.repo'
  release_fields='url html_url assets_url upload_url tarball_url zipball_url id node_id tag_name target_commitish name body draft prerelease created_at published_at author assets author.login author.id'
  branch_fields='name commit protected protection protection_url commit.sha commit.url'
  commit_fields='sha node_id commit url html_url comments_url author committer parents stats files commit.author.name commit.author.email commit.author.date commit.committer.name commit.committer.email commit.committer.date commit.message commit.tree commit.url commit.comment_count author.login committer.login'
  contents_fields='type encoding size name path content sha url git_url html_url download_url links _links.self _links.git _links.html'
  search_fields='total_count incomplete_results items items.id items.node_id items.name items.full_name items.login items.html_url items.description items.stargazers_count items.updated_at items.created_at items.language items.score'

  for word in "${COMP_WORDS[@]:1:COMP_CWORD-1}"; do
    case $word in
      -r | --repo) kind=repo ;;
      -u | --user) kind=user ;;
      -o | --org) kind=org ;;
      -g | --gist) kind=gist ;;
      -a | --api) kind=raw ;;
      --issues | --issue) sub=issue ;;
      --pulls | --pull) sub=pull ;;
      --releases | --release | --latest-release) sub=release ;;
      --branches | --branch) sub=branch ;;
      --commits | --commit) sub=commit ;;
      --contents) sub=contents ;;
      -s | --search | --search-*) kind=search ;;
    esac
  done

  case $prev in
    -r | --repo)
      COMPREPLY=($(compgen -W 'ollama/ollama cli/cli torvalds/linux kubernetes/kubernetes' -- "$cur"))
      return 0
      ;;
    -u | --user)
      COMPREPLY=($(compgen -W 'lgf-136 torvalds github actions' -- "$cur"))
      return 0
      ;;
    -o | --org)
      COMPREPLY=($(compgen -W 'github kubernetes openai microsoft' -- "$cur"))
      return 0
      ;;
    -g | --gist)
      return 0
      ;;
    -a | --api)
      COMPREPLY=($(compgen -W 'repos/ollama/ollama users/lgf-136 orgs/github gists search/repositories search/users search/issues search/code rate_limit meta' -- "$cur"))
      return 0
      ;;
    -q | --query)
      COMPREPLY=($(compgen -W 'per_page=100 page=1 state=open state=closed state=all sort=updated direction=desc type=owner type=member' -- "$cur"))
      return 0
      ;;
    --issue | --pull)
      COMPREPLY=($(compgen -W '1 2 3 4 5 10 100' -- "$cur"))
      return 0
      ;;
    --release)
      COMPREPLY=($(compgen -W 'latest v1.0.0' -- "$cur"))
      return 0
      ;;
    --branch)
      COMPREPLY=($(compgen -W 'main master develop' -- "$cur"))
      return 0
      ;;
    --contents)
      COMPREPLY=($(compgen -f -- "$cur"))
      return 0
      ;;
    --limit)
      COMPREPLY=($(compgen -W '15 30 50 100' -- "$cur"))
      return 0
      ;;
    --pages)
      COMPREPLY=($(compgen -W '1 2 3 5' -- "$cur"))
      return 0
      ;;
    --jq | -s | --search | --search-repos | --search-users | --search-issues | --search-code)
      return 0
      ;;
  esac

  if [[ $cur == -* ]]; then
    case $kind in
      user) COMPREPLY=($(compgen -W "$global_options $user_options $search_options" -- "$cur")) ;;
      org) COMPREPLY=($(compgen -W "$global_options $org_options $search_options" -- "$cur")) ;;
      *) COMPREPLY=($(compgen -W "$global_options $repo_options $user_options $org_options $search_options" -- "$cur")) ;;
    esac
    return 0
  fi

  case $kind:$sub in
    user:*) fields=$user_fields ;;
    org:*) fields=$org_fields ;;
    gist:*) fields=$gist_fields ;;
    search:*) fields=$search_fields ;;
    *:issue) fields=$issue_fields ;;
    *:pull) fields=$pull_fields ;;
    *:release) fields=$release_fields ;;
    *:branch) fields=$branch_fields ;;
    *:commit) fields=$commit_fields ;;
    *:contents) fields=$contents_fields ;;
    *) fields=$repo_fields ;;
  esac

  COMPREPLY=($(compgen -W "$fields" -- "$cur"))
}

complete -F _github_complete github 2>/dev/null || true
