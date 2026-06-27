#!/usr/bin/env fish

# Claude Code 多供应商切换工具（fish 版本）
#
# 用法：
#   mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
#   mcc -l | --list                 显示供应商表
#   mcc -h | --help                 显示完整帮助（含场景示例与注意事项）
#
# 新增供应商：在 _MCC_PROVIDERS 中添加一行即可，补全自动生效。

# ============================================================
# 供应商配置（唯一数据源）
# 每条："name|default_url|api_key_env|base_url_env|big_model|small_model"
# （fish 无关联数组，用「以 | 分隔的结构化条目列表」+ 首字段为主键代替）
#
# big_model   → ANTHROPIC_MODEL / DEFAULT_OPUS / DEFAULT_SONNET
# small_model → DEFAULT_HAIKU / CLAUDE_CODE_SUBAGENT_MODEL
# 留空       → 不设置模型变量（适用于透传代理）
# ============================================================
set -g _MCC_PROVIDERS \
    "agentrouter|https://agentrouter.org|AGENTROUTER_API_KEY|AGENTROUTER_BASE_URL||" \
    "anyrouter|https://anyrouter.top|ANYROUTER_API_KEY|ANYROUTER_BASE_URL||" \
    "deepseek|https://api.deepseek.com/anthropic|DEEPSEEK_API_KEY|DEEPSEEK_BASE_URL|deepseek-v4-pro[1m]|deepseek-v4-flash" \
    "moonshot|https://api.moonshot.cn/anthropic|MOONSHOT_API_KEY|MOONSHOT_BASE_URL|kimi-k2.6|kimi-k2.6" \
    "glm|https://open.bigmodel.cn/api/anthropic|GLM_API_KEY|GLM_BASE_URL|GLM-5.1|GLM-5.1" \
    "siliconflow|https://api.siliconflow.cn/|SILICONFLOW_API_KEY|SILICONFLOW_BASE_URL|deepseek-ai/DeepSeek-V4-Pro|deepseek-ai/DeepSeek-V4-Flash"

# 别名 → 规范名（每条："alias|canonical"）
set -g _MCC_ALIASES \
    "tr|agentrouter" \
    "yr|anyrouter" \
    "ds|deepseek" \
    "km|moonshot" \
    "kimi|moonshot" \
    "sf|siliconflow"

# --effort 合法取值（首项为默认值；fish 数组 1-based）
set -g _MCC_EFFORT_LEVELS max normal min

# 由 mcc 托管的环境变量（每次调用都会先清理，避免上一次设置残留）
set -g _MCC_MANAGED_VARS \
    ANTHROPIC_MODEL \
    ANTHROPIC_DEFAULT_OPUS_MODEL \
    ANTHROPIC_DEFAULT_SONNET_MODEL \
    ANTHROPIC_DEFAULT_HAIKU_MODEL \
    ANTHROPIC_SMALL_FAST_MODEL \
    CLAUDE_CODE_SUBAGENT_MODEL \
    CLAUDE_CODE_EFFORT_LEVEL \
    API_TIMEOUT_MS \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC

# ============================================================
# 内部工具函数
# ============================================================

# 输出错误到 stderr（调用方负责 return 退出码）
function _mcc_err
    echo "Error: $argv" >&2
end

# 掩码显示 API key（仅展示前 8 位）
function _mcc_mask -a key
    printf '%s****' (string sub -l 8 -- $key)
end

# 若指定的环境变量已被赋值，返回 "  (from $VAR)" 标记
function _mcc_origin -a varname
    test -n "$$varname"
    and printf '  (from $%s)' $varname
end

# 别名解析：传入 $1 是别名则回显规范名，否则原样回显
function _mcc_resolve_alias -a name
    for entry in $_MCC_ALIASES
        set -l parts (string split "|" -- $entry)
        if test "$parts[1]" = "$name"
            echo $parts[2]
            return 0
        end
    end
    echo $name
end

# 检查 provider 是否存在（仅检查规范名，需先 _mcc_resolve_alias）
function _mcc_provider_exists -a name
    for entry in $_MCC_PROVIDERS
        string match -q "$name|*" -- $entry
        and return 0
    end
    return 1
end

# 解析 provider 配置到全局 _MCC_* 变量
function _mcc_parse_config -a name
    for entry in $_MCC_PROVIDERS
        set -l parts (string split "|" -- $entry)
        if test "$parts[1]" = "$name"
            set -g _MCC_DEFAULT_URL    $parts[2]
            set -g _MCC_KEY_ENV        $parts[3]
            set -g _MCC_URL_ENV        $parts[4]
            set -g _MCC_BIG_MODEL      $parts[5]
            set -g _MCC_SMALL_MODEL    $parts[6]
            set -l prefix (string replace -r '_API_KEY$' '' -- $_MCC_KEY_ENV)
            set -g _MCC_BIG_MODEL_ENV   $prefix"_BIG_MODEL"
            set -g _MCC_SMALL_MODEL_ENV $prefix"_SMALL_MODEL"
            return 0
        end
    end
    return 1
end

# 解析运行时的 URL / big_model / small_model
# 前置：调用方必须先调用 _mcc_parse_config 以填充 _MCC_* 全局
# 规则：
#   url   ← $$_MCC_URL_ENV ≫ $_MCC_DEFAULT_URL
#   big   ← $$_MCC_BIG_MODEL_ENV ≫ $_MCC_BIG_MODEL
#   small ← $$_MCC_SMALL_MODEL_ENV ≫ $_MCC_SMALL_MODEL
#   big / small 互补：任一为空时复用另一个（仅当至少一个非空时触发）
# 输出："url|big|small"，调用方用 `string split -m 2 "|"` 解码
function _mcc_resolve_runtime
    set -l url $_MCC_DEFAULT_URL
    test -n "$$_MCC_URL_ENV"; and set url $$_MCC_URL_ENV

    set -l big $_MCC_BIG_MODEL
    set -l small $_MCC_SMALL_MODEL
    test -n "$$_MCC_BIG_MODEL_ENV";   and set big   $$_MCC_BIG_MODEL_ENV
    test -n "$$_MCC_SMALL_MODEL_ENV"; and set small $$_MCC_SMALL_MODEL_ENV
    if test -n "$big" -o -n "$small"
        test -z "$big";   and set big   $small
        test -z "$small"; and set small $big
    end

    printf '%s|%s|%s' $url $big $small
end

# 打印供应商列表及用法说明
function _mcc_list
    echo "Providers:"
    echo "----------"
    for entry in (printf '%s\n' $_MCC_PROVIDERS | sort)
        set -l parts (string split "|" -- $entry)
        set -l name $parts[1]
        set -l aliases
        for ae in $_MCC_ALIASES
            set -l ap (string split "|" -- $ae)
            test "$ap[2]" = "$name"; and set -a aliases $ap[1]
        end
        set -l display $name
        test (count $aliases) -gt 0
        and set display "$name ("(string join ', ' $aliases)")"

        _mcc_parse_config $name

        set -l rt (_mcc_resolve_runtime | string split -m 2 "|")
        set -l url $rt[1]
        set -l cfg_big $rt[2]
        set -l cfg_small $rt[3]
        set -l from_env (_mcc_origin $_MCC_URL_ENV)

        set -l model_info ""
        if test -n "$cfg_big"
            set model_info "  big="$cfg_big(_mcc_origin $_MCC_BIG_MODEL_ENV)
            if test "$cfg_small" != "$cfg_big" -o -n "$$_MCC_SMALL_MODEL_ENV"
                set model_info $model_info" / small="$cfg_small(_mcc_origin $_MCC_SMALL_MODEL_ENV)
            end
        end

        printf "  %-20s %s%s%s\n" $display $url $from_env $model_info
    end

    echo "
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

Run 'mcc -h' for full help with all scenarios and caveats."
end

# 打印完整帮助
function _mcc_help
    echo 'mcc - Claude Code 多供应商切换工具

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
  <PREFIX>_SMALL_MODEL              可选，覆盖配置的默认 small model

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
  set -gx DEEPSEEK_BIG_MODEL my-pro     # fish: set -gx 等同 bash 的 export
  set -gx DEEPSEEK_SMALL_MODEL my-flash
  mcc ds

  # 7) 透传代理启用模型（agentrouter / anyrouter 默认无模型配置）
  set -gx AGENTROUTER_BIG_MODEL foo
  mcc tr                            # big=foo，small 回退至 foo

  # 8) 自定义 URL（自建代理或私有部署）
  set -gx DEEPSEEK_BASE_URL https://my-proxy.example.com
  mcc ds

  # 9) 组合：suffix + resume + 临时模型 + 努力等级
  mcc ds 5433 --resume -m custom-model -e min

  # 10) 仅命令行覆盖一边：通过环境变量分别控制
  set -gx DEEPSEEK_BIG_MODEL big-only
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
  mcc -l                            供应商表（含别名 / 默认 URL / 默认模型）'
end

# ============================================================
# Fish 补全（动态读取 _MCC_PROVIDERS / _MCC_ALIASES）
# ============================================================

function _mcc_complete_dynamic
    set -l tokens (commandline -opc)
    set -l positional 0
    set -l first_pos
    set -l skip_next 0

    for i in (seq 2 (count $tokens))
        if test $skip_next -eq 1
            set skip_next 0
            continue
        end
        switch $tokens[$i]
            case -m --model -e --effort
                set skip_next 1
            case '-*'
                # 其他选项，不增加位置参数计数
            case '*'
                set positional (math $positional + 1)
                test $positional -eq 1; and set first_pos $tokens[$i]
        end
    end

    if test $positional -eq 0
        # 候选：provider 规范名 + 别名
        for entry in $_MCC_PROVIDERS
            printf '%s\n' (string split -m 1 "|" -- $entry)[1]
        end
        for entry in $_MCC_ALIASES
            printf '%s\n' (string split -m 1 "|" -- $entry)[1]
        end
    else if test $positional -eq 1
        # 候选：该 provider 对应的 key_suffix（从环境变量中提取）
        set -l prov (_mcc_resolve_alias $first_pos)
        if _mcc_provider_exists $prov
            _mcc_parse_config $prov
            if set -q _MCC_KEY_ENV
                for var in (set --names)
                    if string match -q $_MCC_KEY_ENV"_*" -- $var
                        # 去除前缀，保留后缀（纯文本替换，避免正则元字符问题）
                        string replace "$_MCC_KEY_ENV"_ "" -- $var
                    end
                end
            end
        end
    end
    # 其他情况不提供补全，让 fish 使用静态选项补全或留空
end

# 清除已有的 mcc 补全，确保全新安装
complete -e mcc 2>/dev/null

# 静态选项补全
complete -c mcc -s r -l resume -d 'Resume last session'
complete -c mcc -s m -l model  -x -d 'Override big & small model'
complete -c mcc -s e -l effort -xa 'max normal min' -d 'Effort level'
complete -c mcc -s l -l list   -d 'Show provider list'
complete -c mcc -s h -l help   -d 'Show full help'

# 动态位置参数补全（provider、key_suffix）
complete -c mcc -f -a '(_mcc_complete_dynamic)'

# ============================================================
# 主函数
# ============================================================
function mcc
    argparse 'r/resume' 'm/model=' 'e/effort=' 'l/list' 'h/help' -- $argv
    or return

    if set -q _flag_list
        _mcc_list
        return 0
    end

    if set -q _flag_help
        _mcc_help
        return 0
    end

    if test (count $argv) -eq 0
        _mcc_err "provider required"
        echo
        _mcc_list
        return 1
    end

    if test (count $argv) -gt 2
        _mcc_err "unexpected argument '$argv[3]'"
        return 1
    end

    set -l provider $argv[1]
    set -l key_suffix ""
    test (count $argv) -eq 2; and set key_suffix $argv[2]

    set provider (_mcc_resolve_alias $provider)

    if not _mcc_provider_exists $provider
        _mcc_err "unknown provider '$provider'"
        echo "       Run 'mcc --list' to see available providers." >&2
        return 1
    end

    _mcc_parse_config $provider

    if set -q _flag_effort
        if not contains -- $_flag_effort $_MCC_EFFORT_LEVELS
            _mcc_err "--effort must be one of: $_MCC_EFFORT_LEVELS"
            return 1
        end
    end

    set -l key_var $_MCC_KEY_ENV
    test -n "$key_suffix"; and set key_var $key_var"_"$key_suffix
    if test -z "$$key_var"
        _mcc_err "'$key_var' is not set"
        echo "       set -gx $key_var your_api_key" >&2
        return 1
    end

    set -l rt (_mcc_resolve_runtime | string split -m 2 "|")
    set -l base_url $rt[1]
    set -l big_model $rt[2]
    set -l small_model $rt[3]
    if set -q _flag_model
        set big_model   $_flag_model
        set small_model $_flag_model
    end

    printf "Provider  : %s\n"   $provider
    printf "Base URL  : %s%s\n" $base_url (_mcc_origin $_MCC_URL_ENV)
    printf "API Key   : %s  (%s)\n" (_mcc_mask $$key_var) $key_var
    if test -n "$big_model"
        set -l big_tag ""
        set -l small_tag ""
        if not set -q _flag_model
            set big_tag   (_mcc_origin $_MCC_BIG_MODEL_ENV)
            set small_tag (_mcc_origin $_MCC_SMALL_MODEL_ENV)
        end
        printf "Big Model : %s%s\n" $big_model $big_tag
        printf "Sm Model  : %s%s\n" $small_model $small_tag
        if set -q _flag_effort
            printf "Effort    : %s\n" $_flag_effort
        else
            printf "Effort    : %s\n" $_MCC_EFFORT_LEVELS[1]
        end
    end
    set -q _flag_resume; and printf "Mode      : resume\n"
    echo

    set -e $_MCC_MANAGED_VARS

    set -gx ANTHROPIC_BASE_URL   $base_url
    set -gx ANTHROPIC_AUTH_TOKEN $$key_var

    if test -n "$big_model"
        set -gx ANTHROPIC_MODEL                $big_model
        set -gx ANTHROPIC_DEFAULT_OPUS_MODEL   $big_model
        set -gx ANTHROPIC_DEFAULT_SONNET_MODEL $big_model
        set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL  $small_model
        set -gx CLAUDE_CODE_SUBAGENT_MODEL     $small_model
        if set -q _flag_effort
            set -gx CLAUDE_CODE_EFFORT_LEVEL $_flag_effort
        else
            set -gx CLAUDE_CODE_EFFORT_LEVEL $_MCC_EFFORT_LEVELS[1]
        end
        set -gx API_TIMEOUT_MS 600000
        set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
    end

    set -l cmd claude --dangerously-skip-permissions
    set -q _flag_resume; and set cmd $cmd --resume
    $cmd
end