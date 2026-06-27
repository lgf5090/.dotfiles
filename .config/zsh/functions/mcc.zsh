#!/usr/bin/env zsh

# Claude Code 多供应商切换工具（zsh 版本）
#
# 用法：
#   mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
#   mcc -l | --list                 显示供应商表
#   mcc -h | --help                 显示完整帮助（含场景示例与注意事项）
#
# 新增供应商：在 _MCC_PROVIDERS 中添加一行即可，补全自动生效。

# ============================================================
# 供应商配置（唯一数据源）
# 字段：default_url | api_key_env | base_url_env | big_model | small_model
#
# big_model   → ANTHROPIC_MODEL / DEFAULT_OPUS / DEFAULT_SONNET
# small_model → DEFAULT_HAIKU / CLAUDE_CODE_SUBAGENT_MODEL
# 留空       → 不设置模型变量（适用于透传代理）
# ============================================================
typeset -gA _MCC_PROVIDERS=(
    [agentrouter]="https://agentrouter.org|AGENTROUTER_API_KEY|AGENTROUTER_BASE_URL||"
    [anyrouter]="https://anyrouter.top|ANYROUTER_API_KEY|ANYROUTER_BASE_URL||"
    [deepseek]="https://api.deepseek.com/anthropic|DEEPSEEK_API_KEY|DEEPSEEK_BASE_URL|deepseek-v4-pro[1m]|deepseek-v4-flash"
    [moonshot]="https://api.moonshot.cn/anthropic|MOONSHOT_API_KEY|MOONSHOT_BASE_URL|kimi-k2.6|kimi-k2.6"
    [glm]="https://open.bigmodel.cn/api/anthropic|GLM_API_KEY|GLM_BASE_URL|GLM-5.1|GLM-5.1"
    [siliconflow]="https://api.siliconflow.cn/|SILICONFLOW_API_KEY|SILICONFLOW_BASE_URL|deepseek-ai/DeepSeek-V4-Pro|deepseek-ai/DeepSeek-V4-Flash"
)

# 别名 → 规范名（新增别名只需在此添加一行）
typeset -gA _MCC_ALIASES=(
    [tr]=agentrouter
    [yr]=anyrouter
    [ds]=deepseek
    [km]=moonshot
    [kimi]=moonshot
    [sf]=siliconflow
)

# --effort 合法取值（首项为默认值；zsh 数组 1-based）
typeset -ga _MCC_EFFORT_LEVELS=(max normal min)

# 由 mcc 托管的环境变量（每次调用都会先清理，避免上一次设置残留）
# 含已废弃变量（如 ANTHROPIC_SMALL_FAST_MODEL）以防新旧版混用
typeset -ga _MCC_MANAGED_VARS=(
    ANTHROPIC_MODEL
    ANTHROPIC_DEFAULT_OPUS_MODEL
    ANTHROPIC_DEFAULT_SONNET_MODEL
    ANTHROPIC_DEFAULT_HAIKU_MODEL
    ANTHROPIC_SMALL_FAST_MODEL
    CLAUDE_CODE_SUBAGENT_MODEL
    CLAUDE_CODE_EFFORT_LEVEL
    API_TIMEOUT_MS
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
)

# ============================================================
# 内部工具函数
# ============================================================

# 解析供应商配置到 _MCC_* 变量
_mcc_parse_config() {
    IFS='|' read -r _MCC_DEFAULT_URL _MCC_KEY_ENV _MCC_URL_ENV _MCC_BIG_MODEL _MCC_SMALL_MODEL \
        <<< "${_MCC_PROVIDERS[$1]}"
    # 模型环境变量名按约定派生：<PREFIX>_BIG_MODEL / <PREFIX>_SMALL_MODEL
    # 其中 <PREFIX> 取自 _MCC_KEY_ENV 去掉 _API_KEY 后缀（如 DEEPSEEK_API_KEY → DEEPSEEK）
    local prefix="${_MCC_KEY_ENV%_API_KEY}"
    _MCC_BIG_MODEL_ENV="${prefix}_BIG_MODEL"
    _MCC_SMALL_MODEL_ENV="${prefix}_SMALL_MODEL"
}

# 检测 $1 是否在剩余参数中（用于校验受限取值集合）
_mcc_in() {
    local needle="$1"; shift
    local item
    for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
    return 1
}

# 输出错误到 stderr（调用方负责 return 退出码）
_mcc_err() { echo "Error: $*" >&2; }

# 若指定的环境变量已设置（即用户覆盖了配置默认值），返回 "  (from $VAR)" 标记
# 注：zsh 用 ${(P)name} 实现 bash 的 ${!name} 间接展开
_mcc_origin() {
    [[ -n "${(P)1}" ]] && printf '  (from $%s)' "$1"
}

# 掩码显示 API key（仅展示前8位）
_mcc_mask() { echo "${1[1,8]}****"; }

# 打印供应商列表及用法说明
_mcc_list() {
    emulate -L zsh
    echo "Providers:"
    echo "----------"
    local p a aliases display
    # (@ko) = 关联数组的键，按字典序排序，作为独立词展开
    for p in "${(@ko)_MCC_PROVIDERS}"; do
        _mcc_parse_config "$p"
        # 收集该规范名的所有别名
        aliases=""
        for a in "${(@k)_MCC_ALIASES}"; do
            [[ "${_MCC_ALIASES[$a]}" == "$p" ]] && aliases+="$a, "
        done
        display="$p"
        [[ -n "$aliases" ]] && display+=" (${aliases%, })"
        local url="${(P)_MCC_URL_ENV:-$_MCC_DEFAULT_URL}"
        local from_env="$(_mcc_origin "$_MCC_URL_ENV")"
        local model_info=""
        local cfg_big="${(P)_MCC_BIG_MODEL_ENV:-$_MCC_BIG_MODEL}"
        local cfg_small="${(P)_MCC_SMALL_MODEL_ENV:-$_MCC_SMALL_MODEL}"
        if [[ -n "$cfg_big" || -n "$cfg_small" ]]; then
            [[ -z "$cfg_big"   ]] && cfg_big="$cfg_small"
            [[ -z "$cfg_small" ]] && cfg_small="$cfg_big"
            model_info="  big=${cfg_big}$(_mcc_origin "$_MCC_BIG_MODEL_ENV")"
            [[ "$cfg_small" != "$cfg_big" || -n "${(P)_MCC_SMALL_MODEL_ENV}" ]] && \
                model_info+=" / small=${cfg_small}$(_mcc_origin "$_MCC_SMALL_MODEL_ENV")"
        fi
        printf "  %-20s %s%s%s\n" "$display" "$url" "$from_env" "$model_info"
    done
    cat <<'EOF'

Usage:
  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
  mcc -l|--list
  mcc -h|--help

Examples:
  mcc tr                              # 默认 key
  mcc yr 5433                         # ANYROUTER_API_KEY_5433
  mcc ds -m deepseek-v4-pro[1m]      # 覆盖模型（big + small 均设为该值）
  mcc ds -e normal                    # 指定 effort level
  mcc kimi 1234 --resume              # 带 key 后缀 + 恢复会话

Override base URL / model (env var prefix matches the provider's *_API_KEY):
  export DEEPSEEK_BASE_URL='https://custom.host'
  export DEEPSEEK_BIG_MODEL='custom-pro'
  export DEEPSEEK_SMALL_MODEL='custom-flash'

Model env vars applied (when model is configured):
  ANTHROPIC_MODEL
  ANTHROPIC_DEFAULT_OPUS_MODEL   ← big_model
  ANTHROPIC_DEFAULT_SONNET_MODEL ← big_model
  ANTHROPIC_DEFAULT_HAIKU_MODEL  ← small_model
  CLAUDE_CODE_SUBAGENT_MODEL     ← small_model
  CLAUDE_CODE_EFFORT_LEVEL       ← max (default) | normal | min

Run 'mcc -h' for full help with all scenarios and caveats.
EOF
}

# 打印完整帮助（详细使用场景 + 注意事项）
_mcc_help() {
    cat <<'EOF'
mcc - Claude Code 多供应商切换工具

SYNOPSIS
  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort <level>]
  mcc -l | --list                   显示供应商表
  mcc -h | --help                   显示本帮助

ARGUMENTS
  <provider>                        供应商规范名或别名（运行 mcc -l 查看完整列表）
  [key_suffix]                      可选，API key 后缀；将选用 <PREFIX>_API_KEY_<suffix>

OPTIONS
  -r, --resume                      恢复上次会话（向 claude 传 --resume）
  -m, --model <model>               临时覆盖 big & small model（同时生效，仅本次）
  -e, --effort <max|normal|min>     设置努力等级（默认 max）
  -l, --list                        显示供应商表
  -h, --help                        显示本帮助

ENVIRONMENT VARIABLES
  约定：<PREFIX> 为 *_API_KEY 中 _API_KEY 之前的部分（如 DEEPSEEK_API_KEY → DEEPSEEK）。

  <PREFIX>_API_KEY                  必填，主 API key
  <PREFIX>_API_KEY_<suffix>         可选，备用 key（通过 [key_suffix] 选择）
  <PREFIX>_BASE_URL                 可选，覆盖配置的默认 URL
  <PREFIX>_BIG_MODEL                可选，覆盖配置的默认 big model
  <PREFIX>_SMALL_MODEL              可选,覆盖配置的默认 small model

PRIORITY
  模型:    -m  >  <PREFIX>_BIG/SMALL_MODEL  >  供应商配置默认值
  URL:     <PREFIX>_BASE_URL                >  供应商配置默认值
  API key: 由 [key_suffix] 选定具体的 KEY 变量

SCENARIOS (参数顺序任意，可自由组合)

  # 1) 基础调用（默认 key + 默认 URL + 默认模型）
  mcc deepseek
  mcc ds                            # 别名等价 mcc deepseek

  # 2) 多账号切换：备用 key
  mcc yr 5433                       # 用 ANYROUTER_API_KEY_5433
  mcc deepseek work                 # 用 DEEPSEEK_API_KEY_work

  # 3) 恢复上次会话
  mcc ds -r
  mcc ds --resume

  # 4) 临时换模型（仅本次有效）
  mcc ds -m deepseek-v4-pro[1m]     # big + small 都设为该值

  # 5) 调整努力等级
  mcc ds -e normal                  # max | normal | min（默认 max）
  mcc ds -e min

  # 6) 持久化覆盖模型（影响所有 mcc ds 调用）
  export DEEPSEEK_BIG_MODEL=my-pro
  export DEEPSEEK_SMALL_MODEL=my-flash
  mcc ds

  # 7) 透传代理启用模型（agentrouter / anyrouter 默认无模型配置）
  export AGENTROUTER_BIG_MODEL=foo
  mcc tr                            # big=foo，small 回退至 foo

  # 8) 自定义 URL（自建代理或私有部署）
  export DEEPSEEK_BASE_URL=https://my-proxy.example.com
  mcc ds

  # 9) 组合：suffix + resume + 临时模型 + 努力等级
  mcc ds 5433 --resume -m custom-model -e min

  # 10) 仅命令行覆盖一边：通过环境变量分别控制
  export DEEPSEEK_BIG_MODEL=big-only
  mcc ds                            # small 走配置默认值 deepseek-v4-flash

NOTES
  · -m 同时覆盖 big & small；若需分别控制请改用 <PREFIX>_BIG_MODEL / <PREFIX>_SMALL_MODEL
  · 优先级是 CLI > 环境变量 > 配置默认；启动摘要中的 (from $VAR) 标记表示该值来自环境覆盖
  · 透传代理（agentrouter / anyrouter）配置中无模型，需 -m 或 *_BIG_MODEL 才会导出模型变量
  · big / small 任一为空时会复用另一个，避免导出空字符串到 claude
  · CLAUDE_CODE_EFFORT_LEVEL 仅在最终有模型时才导出；纯透传代理场景下 -e 无效
  · 每次 mcc 调用会先 unset 之前由 mcc 设置的所有变量（见代码 _MCC_MANAGED_VARS）
  · claude 启动时固定附加 --dangerously-skip-permissions
  · API key 在摘要中只显示前 8 位，其余以 **** 掩码，便于安全分享截屏
  · 未识别的 provider 会报错；运行 mcc -l 查看可用列表

SEE ALSO
  mcc -l                            供应商表（含别名 / 默认 URL / 默认模型）
EOF
}

# ============================================================
# Zsh 补全（动态读取 _MCC_PROVIDERS / _MCC_ALIASES）
#
# 设计要点：
#   1) 用"已完成的位置参数计数"而非 $CURRENT 决定补什么 —— 这样
#      `mcc -r ds <TAB>`、`mcc -e normal ds <TAB>` 等"选项穿插在位置
#      参数中"的场景都能正确识别 `ds` 是第 1 个位置参数。
#   2) 短选项 -m/-e 紧跟值，扫描时要 skip_next 跳过那个值，避免它
#      被误算成位置参数。
#   3) cw_prev 优先：如果光标前的 token 是 -e/--effort，直接给 effort
#      候选；-m/--model 后是模型名（用户自由输入），不给候选。
# ============================================================
_mcc_completion() {
    emulate -L zsh
    setopt local_options no_aliases

    local cw_prev="${words[CURRENT-1]}"

    # 光标前一个 token 是带值选项：给该选项的候选
    case "$cw_prev" in
        -m|--model) return 0 ;;
        -e|--effort)
            _values 'effort level' "${_MCC_EFFORT_LEVELS[@]}"
            return 0
            ;;
    esac

    # 扫描 words[2..CURRENT-1]，跳过选项及其值，统计已完成的位置参数
    local -i pos_count=0 skip_next=0 i
    local first_pos=""
    for (( i=2; i < CURRENT; i++ )); do
        if (( skip_next )); then
            skip_next=0
            continue
        fi
        case "${words[i]}" in
            -m|--model|-e|--effort) skip_next=1 ;;
            -*) ;;  # 其他选项（-r/-l/-h/--resume 等）忽略
            *)
                (( pos_count++ ))
                (( pos_count == 1 )) && first_pos="${words[i]}"
                ;;
        esac
    done

    local -a providers opts suffixes
    opts=(-l --list -h --help -r --resume -m --model -e --effort)

    if (( pos_count == 0 )); then
        # 当前光标是第 1 个位置参数：provider 名 + 别名
        providers=("${(@k)_MCC_PROVIDERS}" "${(@k)_MCC_ALIASES}")
        _describe -t providers 'provider' providers
    elif (( pos_count == 1 )); then
        # 当前光标是第 2 个位置参数：key_suffix（基于已设置的 env vars）
        local p="${_MCC_ALIASES[$first_pos]:-$first_pos}"
        if (( ${+_MCC_PROVIDERS[$p]} )); then
            _mcc_parse_config "$p"
            local var
            # zsh 内置 $parameters 关联数组保存了所有已定义变量名；按前缀过滤即可，
            # 不需要 bash 的 compgen -v
            for var in ${(k)parameters}; do
                [[ "$var" == "${_MCC_KEY_ENV}_"* ]] && \
                    suffixes+=("${var#${_MCC_KEY_ENV}_}")
            done
            (( ${#suffixes} )) && _describe -t suffixes 'key suffix' suffixes
        fi
    fi

    # 无论位置如何，始终提供选项候选
    _describe -t options 'option' opts
}

_mcc_register_completion() {
    (( ${+functions[compdef]} )) || return 0
    compdef _mcc_completion mcc 2>/dev/null
}
_mcc_register_completion

# ============================================================
# 主函数
# ============================================================
mcc() {
    emulate -L zsh

    if (( $# == 0 )); then
        _mcc_err "provider required"; echo
        _mcc_list; return 1
    fi

    if [[ "$1" == "-l" || "$1" == "--list" ]]; then
        _mcc_list; return 0
    fi

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        _mcc_help; return 0
    fi

    local provider="$1"; shift
    # 规范化别名
    provider="${_MCC_ALIASES[$provider]:-$provider}"

    if (( ! ${+_MCC_PROVIDERS[$provider]} )); then
        _mcc_err "unknown provider '$provider'"
        echo "       Run 'mcc --list' to see available providers." >&2
        return 1
    fi

    _mcc_parse_config "$provider"

    # 解析剩余参数（顺序任意）
    local key_suffix="" custom_model="" effort="" resume=false
    while (( $# > 0 )); do
        case "$1" in
            -r|--resume) resume=true; shift ;;
            -m|--model)
                (( $# < 2 )) && { _mcc_err "--model requires a value"; return 1; }
                custom_model="$2"; shift 2
                ;;
            -e|--effort)
                (( $# < 2 )) && { _mcc_err "--effort requires a value (${_MCC_EFFORT_LEVELS[*]})"; return 1; }
                _mcc_in "$2" "${_MCC_EFFORT_LEVELS[@]}" || {
                    _mcc_err "--effort must be one of: ${_MCC_EFFORT_LEVELS[*]}"; return 1
                }
                effort="$2"; shift 2
                ;;
            -*)
                _mcc_err "unknown option '$1'"; return 1
                ;;
            *)
                [[ -n "$key_suffix" ]] && { _mcc_err "unexpected argument '$1'"; return 1; }
                key_suffix="$1"; shift
                ;;
        esac
    done

    # 确定 API key
    local key_var="${_MCC_KEY_ENV}${key_suffix:+_$key_suffix}"
    if [[ -z "${(P)key_var}" ]]; then
        _mcc_err "'$key_var' is not set"
        echo "       export $key_var=your_api_key" >&2
        return 1
    fi

    # 确定 base URL（环境变量优先）
    local base_url="${(P)_MCC_URL_ENV:-$_MCC_DEFAULT_URL}"

    # 确定模型（优先级：--model > 环境变量 > 配置默认；任一为空则复用另一个）
    local big_model small_model
    if [[ -n "$custom_model" ]]; then
        big_model="$custom_model"
        small_model="$custom_model"
    else
        big_model="${(P)_MCC_BIG_MODEL_ENV:-$_MCC_BIG_MODEL}"
        small_model="${(P)_MCC_SMALL_MODEL_ENV:-$_MCC_SMALL_MODEL}"
        [[ -z "$big_model"   ]] && big_model="$small_model"
        [[ -z "$small_model" ]] && small_model="$big_model"
    fi

    # 打印启动摘要（key 掩码）
    printf "Provider  : %s\n"   "$provider"
    printf "Base URL  : %s%s\n" "$base_url" "$(_mcc_origin "$_MCC_URL_ENV")"
    printf "API Key   : %s  (%s)\n" "$(_mcc_mask "${(P)key_var}")" "$key_var"
    if [[ -n "$big_model" ]]; then
        local big_tag="" small_tag=""
        if [[ -z "$custom_model" ]]; then
            big_tag="$(_mcc_origin "$_MCC_BIG_MODEL_ENV")"
            small_tag="$(_mcc_origin "$_MCC_SMALL_MODEL_ENV")"
        fi
        printf "Big Model : %s%s\n" "$big_model" "$big_tag"
        printf "Sm Model  : %s%s\n" "$small_model" "$small_tag"
        printf "Effort    : %s\n" "${effort:-${_MCC_EFFORT_LEVELS[1]}}"
    fi
    $resume && printf "Mode      : resume\n"
    echo

    # 清理上次会话留下的相关环境变量（变量列表见 _MCC_MANAGED_VARS）
    unset "${_MCC_MANAGED_VARS[@]}"

    export ANTHROPIC_BASE_URL="$base_url"
    export ANTHROPIC_AUTH_TOKEN="${(P)key_var}"

    if [[ -n "$big_model" ]]; then
        export ANTHROPIC_MODEL="$big_model"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="$big_model"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="$big_model"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="$small_model"
        export CLAUDE_CODE_SUBAGENT_MODEL="$small_model"
        export CLAUDE_CODE_EFFORT_LEVEL="${effort:-${_MCC_EFFORT_LEVELS[1]}}"
        export API_TIMEOUT_MS=600000
        export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    fi

    # 启动（数组传参，避免 eval）
    local -a cmd=(claude --dangerously-skip-permissions)
    $resume && cmd+=(--resume)
    "${cmd[@]}"
}
