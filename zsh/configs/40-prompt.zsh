export PROMPT_LOAD=1

# Custom prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %b%c%u'
zstyle ':vcs_info:git:*' actionformats ' %b|%a%c%u'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' unstagedstr ' *'
zstyle ':vcs_info:*' enable git

# Python virtual environment info
python_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo " $(basename "$VIRTUAL_ENV")"
    fi
}

# Color definitions
local user_color='%F{81}' # Light blue (#4FC3F7)
local path_color='%F{white}' # White (#E6E6E6)
local git_color='%F{81}' # Light blue (#4FC3F7)
local python_color='%F{215}' # Orange (#FFB74D)
local prompt_color='%F{76}' # Green (#4CAF50)
local error_color='%F{196}' # Red (#F44336)
local reset_color='%f'

PROMPT='qsdqsdqs${user_color}%n${reset_color}@%m${path_color} %~${reset_color}${git_color}${vcs_info_msg_0_}${reset_color}${python_color}$(python_info)${reset_color}
%(?.${prompt_color}.${error_color})>${reset_color} '
setopt prompt_subst
