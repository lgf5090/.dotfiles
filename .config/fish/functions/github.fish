set -g _github_api_base https://api.github.com

function _github_usage
    printf '%s\n' \
        'github - small GitHub REST API helper' \
        '' \
        'usage:' \
        '  github -h | --help' \
        '  github [field ...]' \
        '  github -r OWNER/REPO [repo-option] [field ...]' \
        '  github -u USER [user-option] [field ...]' \
        '  github -o ORG [org-option] [field ...]' \
        '  github -g GIST_ID [field ...]' \
        '  github --api PATH [field ...]' \
        '  github -s QUERY [--limit N] [--pages N] [field ...]' \
        '  github --search-repos QUERY [field ...]' \
        '  github --search-users QUERY [field ...]' \
        '  github --search-issues QUERY [field ...]' \
        '  github --search-code QUERY [field ...]' \
        '' \
        'authentication:' \
        '  Uses GITHUB_TOKEN as Authorization: Bearer $GITHUB_TOKEN when set.' \
        '  Else uses GH_TOKEN as Authorization: Bearer $GH_TOKEN when set.' \
        '' \
        'defaults:' \
        '  github' \
        '      curl https://api.github.com/repos/ollama/ollama' \
        '  github -r ollama/ollama' \
        '      curl https://api.github.com/repos/ollama/ollama' \
        '' \
        'common options:' \
        '  -r, --repo OWNER/REPO       repo endpoint, default: ollama/ollama' \
        '  -u, --user USER             user endpoint' \
        '  -o, --org ORG               organization endpoint' \
        '  -g, --gist GIST_ID          gist endpoint' \
        '  -a, --api PATH              raw GitHub API path' \
        '  -s, --search QUERY          search repositories and show a ranked summary' \
        '  -q, --query KEY=VALUE       append query parameter, repeatable' \
        '  --limit N                   limit displayed search rows, default: 15' \
        '  --pages N                   fetch N search result pages before ranking, default: 1' \
        '  --jq FILTER                 run a raw jq filter against the response' \
        '  --url                       print the API URL instead of requesting it' \
        '  -h, --help                  show this help' \
        '' \
        'repo options:' \
        '  --issues, --issue NUMBER, --pulls, --pull NUMBER' \
        '  --releases, --release TAG, --latest-release' \
        '  --branches, --branch NAME, --commits, --commit SHA' \
        '  --contents PATH, --contributors, --languages, --tags, --topics' \
        '  --stargazers, --subscribers, --forks, --workflows' \
        '' \
        'user options:' \
        '  --repos, --followers, --following, --gists, --starred, --orgs, --events' \
        '' \
        'org options:' \
        '  --repos, --members, --teams, --events' \
        '' \
        'search options:' \
        '  -s, --search QUERY          ranked repo search, default: --limit 15 --pages 1' \
        '  github -s wsl --limit 30 --pages 2' \
        '      Fetch two search pages, rank locally by stars, updated_at, created_at.' \
        '  --search-repos QUERY, --search-users QUERY, --search-issues QUERY, --search-code QUERY' \
        '' \
        'fields:' \
        '  Field names are jq paths. Examples: id, name, owner.login, created_at'
end

function _github_urlencode --argument-names value
    string escape --style=url -- "$value"
end

function _github_json_string --argument-names value
    jq -Rn --arg value "$value" '$value'
end

function _github_jq_expr --argument-names selector
    if string match -qr '^(\.|\[)' -- "$selector"
        printf '%s' "$selector"
        return 0
    end

    set -l expr .
    for segment in (string split . -- "$selector")
        if test -z "$segment"
            return 2
        end
        set -l quoted (_github_json_string "$segment")
        set expr (string join '' -- "$expr" '[' "$quoted" ']')
    end

    printf '%s' "$expr"
end

function _github_join_query --argument-names url query
    if test -z "$query"
        printf '%s' "$url"
    else if string match -q '*\?*' -- "$url"
        printf '%s&%s' "$url" "$query"
    else
        printf '%s?%s' "$url" "$query"
    end
end

function github --description 'GitHub REST API helper'
    set -l kind repo
    set -l target ollama/ollama
    set -l endpoint_path
    set -l raw_path
    set -l jq_filter
    set -l print_url 0
    set -l search_display 0
    set -l search_limit 15
    set -l search_pages 1
    set -l query
    set -l fields

    while test (count $argv) -gt 0
        switch $argv[1]
            case -h --help
                _github_usage
                return 0
            case -r --repo
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires OWNER/REPO" >&2
                    return 2
                end
                set kind repo
                set target $argv[2]
                set endpoint_path
                set -e argv[1..2]
            case -u --user
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires USER" >&2
                    return 2
                end
                set kind user
                set target $argv[2]
                set endpoint_path
                set -e argv[1..2]
            case -o --org
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires ORG" >&2
                    return 2
                end
                set kind org
                set target $argv[2]
                set endpoint_path
                set -e argv[1..2]
            case -g --gist
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires GIST_ID" >&2
                    return 2
                end
                set kind gist
                set target $argv[2]
                set endpoint_path
                set -e argv[1..2]
            case -a --api
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires PATH" >&2
                    return 2
                end
                set kind raw
                set raw_path (string replace -r '^/+' '' -- "$argv[2]")
                set endpoint_path
                set -e argv[1..2]
            case -s --search
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires QUERY" >&2
                    return 2
                end
                set kind raw
                set raw_path search/repositories
                set endpoint_path
                set search_display 1
                set -l encoded_value (_github_urlencode "$argv[2]")
                if test -n "$query"
                    set query "$query&q=$encoded_value"
                else
                    set query "q=$encoded_value"
                end
                set -e argv[1..2]
            case --search-repos
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires QUERY" >&2
                    return 2
                end
                set kind raw
                set raw_path search/repositories
                set -l encoded_value (_github_urlencode "$argv[2]")
                if test -n "$query"
                    set query "$query&q=$encoded_value"
                else
                    set query "q=$encoded_value"
                end
                set -e argv[1..2]
            case --search-users
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires QUERY" >&2
                    return 2
                end
                set kind raw
                set raw_path search/users
                set -l encoded_value (_github_urlencode "$argv[2]")
                if test -n "$query"
                    set query "$query&q=$encoded_value"
                else
                    set query "q=$encoded_value"
                end
                set -e argv[1..2]
            case --search-issues
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires QUERY" >&2
                    return 2
                end
                set kind raw
                set raw_path search/issues
                set -l encoded_value (_github_urlencode "$argv[2]")
                if test -n "$query"
                    set query "$query&q=$encoded_value"
                else
                    set query "q=$encoded_value"
                end
                set -e argv[1..2]
            case --search-code
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo "github: $argv[1] requires QUERY" >&2
                    return 2
                end
                set kind raw
                set raw_path search/code
                set -l encoded_value (_github_urlencode "$argv[2]")
                if test -n "$query"
                    set query "$query&q=$encoded_value"
                else
                    set query "q=$encoded_value"
                end
                set -e argv[1..2]
            case -q --query
                if test (count $argv) -lt 2; or not string match -q '*=*' -- "$argv[2]"
                    echo "github: $argv[1] requires KEY=VALUE" >&2
                    return 2
                end
                set -l key (string split -m1 = -- "$argv[2]")[1]
                set -l value (string split -m1 = -- "$argv[2]")[2]
                set -l encoded_key (_github_urlencode "$key")
                set -l encoded_value (_github_urlencode "$value")
                if test -n "$query"
                    set query "$query&$encoded_key=$encoded_value"
                else
                    set query "$encoded_key=$encoded_value"
                end
                set -e argv[1..2]
            case --limit
                if test (count $argv) -lt 2; or not string match -qr '^[0-9]+$' -- "$argv[2]"; or test "$argv[2]" -le 0
                    echo 'github: --limit requires a positive integer' >&2
                    return 2
                end
                set search_limit "$argv[2]"
                set -e argv[1..2]
            case --pages
                if test (count $argv) -lt 2; or not string match -qr '^[0-9]+$' -- "$argv[2]"; or test "$argv[2]" -le 0
                    echo 'github: --pages requires a positive integer' >&2
                    return 2
                end
                set search_pages "$argv[2]"
                set -e argv[1..2]
            case --jq
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --jq requires FILTER' >&2
                    return 2
                end
                set jq_filter "$argv[2]"
                set -e argv[1..2]
            case --url
                set print_url 1
                set -e argv[1]
            case --issues
                set kind repo
                set endpoint_path issues
                set -e argv[1]
            case --issue
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --issue requires NUMBER' >&2
                    return 2
                end
                set kind repo
                set endpoint_path issues/$argv[2]
                set -e argv[1..2]
            case --pulls
                set kind repo
                set endpoint_path pulls
                set -e argv[1]
            case --pull
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --pull requires NUMBER' >&2
                    return 2
                end
                set kind repo
                set endpoint_path pulls/$argv[2]
                set -e argv[1..2]
            case --releases
                set kind repo
                set endpoint_path releases
                set -e argv[1]
            case --release
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --release requires TAG' >&2
                    return 2
                end
                set kind repo
                set endpoint_path releases/tags/$argv[2]
                set -e argv[1..2]
            case --latest-release
                set kind repo
                set endpoint_path releases/latest
                set -e argv[1]
            case --branches
                set kind repo
                set endpoint_path branches
                set -e argv[1]
            case --branch
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --branch requires NAME' >&2
                    return 2
                end
                set kind repo
                set endpoint_path branches/$argv[2]
                set -e argv[1..2]
            case --commits
                set kind repo
                set endpoint_path commits
                set -e argv[1]
            case --commit
                if test (count $argv) -lt 2; or test -z "$argv[2]"
                    echo 'github: --commit requires SHA' >&2
                    return 2
                end
                set kind repo
                set endpoint_path commits/$argv[2]
                set -e argv[1..2]
            case --contents
                if test (count $argv) -lt 2
                    echo 'github: --contents requires PATH' >&2
                    return 2
                end
                set kind repo
                set endpoint_path contents/(string replace -r '^/+' '' -- "$argv[2]")
                set -e argv[1..2]
            case --contributors --languages --tags --topics --stargazers --subscribers --forks
                set kind repo
                set endpoint_path (string replace -- -- '' "$argv[1]")
                set -e argv[1]
            case --workflows
                set kind repo
                set endpoint_path actions/workflows
                set -e argv[1]
            case --repos --followers --following --gists --starred --orgs --events --members --teams
                set endpoint_path (string replace -- -- '' "$argv[1]")
                set -e argv[1]
            case --
                set -e argv[1]
                set fields $fields $argv
                break
            case '-*'
                echo "github: unknown option: $argv[1]" >&2
                return 2
            case '*'
                set fields $fields $argv[1]
                set -e argv[1]
        end
    end

    switch $kind
        case repo
            if not string match -q '*/*' -- "$target"
                echo "github: repo must be OWNER/REPO: $target" >&2
                return 2
            end
            set raw_path repos/$target
        case user
            set raw_path users/$target
        case org
            set raw_path orgs/$target
        case gist
            set raw_path gists/$target
    end

    if test -n "$endpoint_path"
        set raw_path "$raw_path/$endpoint_path"
    end
    set raw_path (string replace -r '^/+' '' -- "$raw_path")

    set -l url $_github_api_base/$raw_path
    set -l url_query "$query"
    if test $search_display -eq 1
        if test -n "$url_query"
            set url_query "$url_query&per_page=100&page=1"
        else
            set url_query 'per_page=100&page=1'
        end
    end
    set url (_github_join_query "$url" "$url_query")

    if test $print_url -eq 1
        printf '%s\n' "$url"
        return 0
    end

    set -l curl_args -fsSL
    set curl_args $curl_args -H 'Accept: application/vnd.github+json'
    set curl_args $curl_args -H 'X-GitHub-Api-Version: 2022-11-28'
    if set -q GITHUB_TOKEN; and test -n "$GITHUB_TOKEN"
        set curl_args $curl_args -H "Authorization: Bearer $GITHUB_TOKEN"
    else if set -q GH_TOKEN; and test -n "$GH_TOKEN"
        set curl_args $curl_args -H "Authorization: Bearer $GH_TOKEN"
    end

    if test $search_display -eq 1
        command -q jq; or begin
            echo 'github: jq is required for formatted search output' >&2
            return 127
        end

        set -l responses
        for page in (seq 1 $search_pages)
            set -l page_query "$query"
            if test -n "$page_query"
                set page_query "$page_query&per_page=100&page=$page"
            else
                set page_query "per_page=100&page=$page"
            end
            set -l page_url (_github_join_query "$_github_api_base/$raw_path" "$page_query")
            set -l page_response (curl $curl_args "$page_url" | string collect)
            set -l curl_status $pipestatus[1]
            if test $curl_status -ne 0
                return $curl_status
            end
            set responses $responses "$page_response"
        end

        set -l response (printf '%s\n' $responses | jq -c -s '{total_count: ((map(.total_count // 0) | max) // 0), incomplete_results: (map(.incomplete_results // false) | any), items: (map(.items // []) | add)}' | string collect)
        set -l statuses $pipestatus
        if test $statuses[1] -ne 0
            return $statuses[1]
        end
        if test $statuses[2] -ne 0
            return $statuses[2]
        end

        if test -n "$jq_filter"
            printf '%s\n' "$response" | jq -r "$jq_filter"
            set statuses $pipestatus
            if test $statuses[1] -ne 0
                return $statuses[1]
            end
            return $statuses[2]
        end

        if test (count $fields) -gt 0
            if test (count $fields) -eq 1
                set -l search_field "$fields[1]"
                if string match -q 'items.*' -- "$search_field"
                    set search_field (string replace -r '^items\.' '' -- "$search_field")
                end
                if test "$search_field" = items
                    set jq_filter '.items | sort_by([(.stargazers_count // 0), (.updated_at // ""), (.created_at // "")]) | reverse | .[:$limit][] | .'
                else
                    set -l expr (_github_jq_expr "$search_field")
                    or begin
                        echo "github: invalid field: $fields[1]" >&2
                        return 2
                    end
                    set jq_filter ".items | sort_by([(.stargazers_count // 0), (.updated_at // \"\"), (.created_at // \"\")]) | reverse | .[:\$limit][] | $expr"
                end
            else
                set jq_filter '.items | sort_by([(.stargazers_count // 0), (.updated_at // ""), (.created_at // "")]) | reverse | .[:$limit][] | {'
                set -l sep
                for field in $fields
                    set -l search_field "$field"
                    if string match -q 'items.*' -- "$search_field"
                        set search_field (string replace -r '^items\.' '' -- "$search_field")
                    end
                    if test "$search_field" = items
                        echo "github: invalid field with other fields: $field" >&2
                        return 2
                    end
                    set -l expr (_github_jq_expr "$search_field")
                    or begin
                        echo "github: invalid field: $field" >&2
                        return 2
                    end
                    set -l key (_github_json_string "$field")
                    set jq_filter "$jq_filter$sep$key: $expr"
                    set sep ', '
                end
                set jq_filter "$jq_filter}"
            end

            printf '%s\n' "$response" | jq -r --argjson limit "$search_limit" "$jq_filter"
            set statuses $pipestatus
            if test $statuses[1] -ne 0
                return $statuses[1]
            end
            return $statuses[2]
        end

        printf '%s\n' "$response" | jq -r --argjson limit "$search_limit" '(["stars","updated","created","repo","url","description"], (.items | sort_by([(.stargazers_count // 0), (.updated_at // ""), (.created_at // "")]) | reverse | .[:$limit][] | [((.stargazers_count // 0) | tostring), ((.updated_at // "")[0:10]), ((.created_at // "")[0:10]), (.full_name // ""), (.html_url // ""), ((.description // "") | gsub("[\t\r\n]+"; " "))])) | @tsv'
        set statuses $pipestatus
        if test $statuses[1] -ne 0
            return $statuses[1]
        end
        return $statuses[2]
    end

    if test -n "$jq_filter"; or test (count $fields) -gt 0
        command -q jq; or begin
            echo 'github: jq is required when selecting fields' >&2
            return 127
        end

        if test -z "$jq_filter"
            if test (count $fields) -eq 1
                set jq_filter (_github_jq_expr "$fields[1]")
                or begin
                    echo "github: invalid field: $fields[1]" >&2
                    return 2
                end
            else
                set jq_filter '{'
                set -l sep
                for field in $fields
                    set -l expr (_github_jq_expr "$field")
                    or begin
                        echo "github: invalid field: $field" >&2
                        return 2
                    end
                    set -l key (_github_json_string "$field")
                    set jq_filter "$jq_filter$sep$key: $expr"
                    set sep ', '
                end
                set jq_filter "$jq_filter}"
            end
        end

        curl $curl_args "$url" | jq -r "$jq_filter"
        set -l statuses $pipestatus
        if test $statuses[1] -ne 0
            return $statuses[1]
        end
        return $statuses[2]
    end

    curl $curl_args "$url"
end

function _github_complete_fields
    set -l tokens (commandline -opc)
    set -l kind repo
    set -l sub

    for word in $tokens[2..-1]
        switch $word
            case -r --repo
                set kind repo
            case -u --user
                set kind user
            case -o --org
                set kind org
            case -g --gist
                set kind gist
            case -a --api
                set kind raw
            case --issues --issue
                set sub issue
            case --pulls --pull
                set sub pull
            case --releases --release --latest-release
                set sub release
            case --branches --branch
                set sub branch
            case --commits --commit
                set sub commit
            case --contents
                set sub contents
            case -s --search '--search-*'
                set kind search
        end
    end

    set -l repo_fields id node_id name full_name owner private html_url description fork url forks_url keys_url collaborators_url teams_url hooks_url issue_events_url events_url assignees_url branches_url tags_url blobs_url git_tags_url git_refs_url trees_url statuses_url languages_url stargazers_url contributors_url subscribers_url subscription_url commits_url git_commits_url comments_url issue_comment_url contents_url compare_url merges_url archive_url downloads_url issues_url pulls_url milestones_url notifications_url labels_url releases_url deployments_url created_at updated_at pushed_at git_url ssh_url clone_url svn_url homepage size stargazers_count watchers_count language has_issues has_projects has_downloads has_wiki has_pages has_discussions forks_count mirror_url archived disabled open_issues_count license allow_forking is_template web_commit_signoff_required topics visibility forks open_issues watchers default_branch network_count subscribers_count organization parent source owner.login owner.id owner.node_id owner.avatar_url owner.html_url owner.type license.key license.name license.spdx_id
    set -l user_fields login id node_id avatar_url gravatar_id url html_url followers_url following_url gists_url starred_url subscriptions_url organizations_url repos_url events_url received_events_url type site_admin name company blog location email hireable bio twitter_username public_repos public_gists followers following created_at updated_at plan
    set -l org_fields login id node_id url repos_url events_url hooks_url issues_url members_url public_members_url avatar_url description name company blog location email twitter_username is_verified has_organization_projects has_repository_projects public_repos public_gists followers following html_url created_at updated_at type total_private_repos owned_private_repos private_gists disk_usage collaborators billing_email default_repository_permission members_can_create_repositories two_factor_requirement_enabled
    set -l gist_fields url forks_url commits_url id node_id git_pull_url git_push_url html_url files public created_at updated_at description comments user comments_url owner truncated owner.login owner.id owner.avatar_url
    set -l issue_fields url repository_url labels_url comments_url events_url html_url id node_id number title user labels state locked assignee assignees milestone comments created_at updated_at closed_at author_association active_lock_reason body closed_by reactions timeline_url performed_via_github_app state_reason user.login user.id pull_request
    set -l pull_fields url id node_id html_url diff_url patch_url issue_url commits_url review_comments_url review_comment_url comments_url statuses_url number state locked title user body labels milestone active_lock_reason created_at updated_at closed_at merged_at merge_commit_sha assignee assignees requested_reviewers requested_teams head base author_association draft merged mergeable rebaseable mergeable_state merged_by comments review_comments maintainer_can_modify commits additions deletions changed_files user.login head.ref head.sha head.repo base.ref base.sha base.repo
    set -l release_fields url html_url assets_url upload_url tarball_url zipball_url id node_id tag_name target_commitish name body draft prerelease created_at published_at author assets author.login author.id
    set -l branch_fields name commit protected protection protection_url commit.sha commit.url
    set -l commit_fields sha node_id commit url html_url comments_url author committer parents stats files commit.author.name commit.author.email commit.author.date commit.committer.name commit.committer.email commit.committer.date commit.message commit.tree commit.url commit.comment_count author.login committer.login
    set -l contents_fields type encoding size name path content sha url git_url html_url download_url links _links.self _links.git _links.html
    set -l search_fields total_count incomplete_results items items.id items.node_id items.name items.full_name items.login items.html_url items.description items.stargazers_count items.updated_at items.created_at items.language items.score

    switch "$kind:$sub"
        case 'user:*'
            printf '%s\n' $user_fields
        case 'org:*'
            printf '%s\n' $org_fields
        case 'gist:*'
            printf '%s\n' $gist_fields
        case 'search:*'
            printf '%s\n' $search_fields
        case '*:issue'
            printf '%s\n' $issue_fields
        case '*:pull'
            printf '%s\n' $pull_fields
        case '*:release'
            printf '%s\n' $release_fields
        case '*:branch'
            printf '%s\n' $branch_fields
        case '*:commit'
            printf '%s\n' $commit_fields
        case '*:contents'
            printf '%s\n' $contents_fields
        case '*'
            printf '%s\n' $repo_fields
    end
end

complete -e github 2>/dev/null
complete -c github -s h -l help -d 'Show help'
complete -c github -s r -l repo -x -a 'ollama/ollama cli/cli torvalds/linux kubernetes/kubernetes' -d 'Repository endpoint'
complete -c github -s u -l user -x -a 'lgf-136 torvalds github actions' -d 'User endpoint'
complete -c github -s o -l org -x -a 'github kubernetes openai microsoft' -d 'Organization endpoint'
complete -c github -s g -l gist -x -d 'Gist endpoint'
complete -c github -s a -l api -x -a 'repos/ollama/ollama users/lgf-136 orgs/github gists search/repositories search/users search/issues search/code rate_limit meta' -d 'Raw API path'
complete -c github -s s -l search -x -d 'Ranked repository search'
complete -c github -s q -l query -x -a 'per_page=100 page=1 state=open state=closed state=all sort=updated direction=desc type=owner type=member' -d 'Query parameter'
complete -c github -l limit -x -a '15 30 50 100' -d 'Search result limit'
complete -c github -l pages -x -a '1 2 3 5' -d 'Search pages to fetch'
complete -c github -l jq -x -d 'jq filter'
complete -c github -l url -d 'Print URL'
complete -c github -l issues -d 'Repo issues'
complete -c github -l issue -x -a '1 2 3 4 5 10 100' -d 'Repo issue'
complete -c github -l pulls -d 'Repo pulls'
complete -c github -l pull -x -a '1 2 3 4 5 10 100' -d 'Repo pull'
complete -c github -l releases -d 'Repo releases'
complete -c github -l release -x -a 'latest v1.0.0' -d 'Repo release tag'
complete -c github -l latest-release -d 'Latest repo release'
complete -c github -l branches -d 'Repo branches'
complete -c github -l branch -x -a 'main master develop' -d 'Repo branch'
complete -c github -l commits -d 'Repo commits'
complete -c github -l commit -x -d 'Repo commit SHA'
complete -c github -l contents -r -d 'Repo contents path'
complete -c github -l contributors -d 'Repo contributors'
complete -c github -l languages -d 'Repo languages'
complete -c github -l tags -d 'Repo tags'
complete -c github -l topics -d 'Repo topics'
complete -c github -l stargazers -d 'Repo stargazers'
complete -c github -l subscribers -d 'Repo subscribers'
complete -c github -l forks -d 'Repo forks'
complete -c github -l workflows -d 'Repo workflows'
complete -c github -l repos -d 'User or org repos'
complete -c github -l followers -d 'User followers'
complete -c github -l following -d 'User following'
complete -c github -l gists -d 'User gists'
complete -c github -l starred -d 'User starred repos'
complete -c github -l orgs -d 'User orgs'
complete -c github -l events -d 'User or org events'
complete -c github -l members -d 'Org members'
complete -c github -l teams -d 'Org teams'
complete -c github -l search-repos -x -d 'Search repositories'
complete -c github -l search-users -x -d 'Search users'
complete -c github -l search-issues -x -d 'Search issues'
complete -c github -l search-code -x -d 'Search code'
complete -c github -f -a '(_github_complete_fields)'
