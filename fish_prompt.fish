#   Based on Pista
# - Virtualenv name (if applicable, see https://github.com/adambrenecki/virtualfish)
# - Shorten current directory name
# - Git information (if inside a git repo)
# - Number of tasks from t.py (if non-zero)

# Shorten PWD
set -g fish_prompt_pwd_dir_length 1

# disable venv default prompt
set -g VIRTUAL_ENV_DISABLE_PROMPT 0

# disable vim mode prompt
function fish_mode_prompt --description 'Displays the current mode'
  # Do nothing if not in vi mode
end

function _print_in_color
  set -l string $argv[1]
  set -l color  $argv[2]

  set_color $color
  printf $string
  set_color normal
end

# Error aware prompt character
function _prompt_char_for_status
  if test $argv[1] -eq 0
    _print_in_color "\n\e[1m▲\e[0m " brgreen
  else
    _print_in_color "\n\e[1m▼\e[0m " brred
  end
end

# Virtual Env Prompt
function fish_right_prompt
  if set -q VIRTUAL_ENV
    set -l venv (basename $VIRTUAL_ENV)
    _print_in_color "\e[1m$venv\e[0m" cyan
  end
end

# Branch name
function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

# Modified 
function _is_git_modified
  echo (command git diff --exit-code)
end

# Untracked
function _is_git_untracked
  echo (command git ls-files --other --exclude-standard --directory)
end

# Untracked or unstaged
function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

# Staged
function _is_git_staged
  echo (command git diff --cached --exit-code)
end

function fish_prompt
  # last status
  set -l last_status $status

  # Directory
  _print_in_color "\n"(prompt_pwd) brwhite

  # tasks count from t.py, NB: m and s are aliased commands to call t.py for
  # two separate task lists
  #
  set -l  _tasks_symbol 'τ'
  set -l  _tasks (math (m | wc -l | sed -e"s/ *//") + (s | wc -l | sed -e"s/ *//"))

  # Tasks
  if [ $_tasks != 0 ]
    _print_in_color " $_tasks_symbol $_tasks" green
  end

  # Git
  set -l _git_untracked_symbol "×"
  set -l _git_staged_symbol "±"
  set -l _git_clean_symbol "·"
  set -l _git_behind_upstream_symbol "-"
  set -l _git_ahead_upstream_symbol "+"

  if [ (_git_branch_name) ]
    set -l git_branch (_git_branch_name)
    _print_in_color " $git_branch" brgrey

    if [ (_is_git_untracked) ]
      _print_in_color " $_git_untracked_symbol" brred
    end

    if [ (_is_git_modified) ]
      _print_in_color " $_git_untracked_symbol" bryellow
    end

    if [ (_is_git_staged) ]
      _print_in_color " $_git_staged_symbol" bryellow
    end

    if [ -z (_is_git_dirty) ]
      _print_in_color " $_git_clean_symbol" brgreen
    end

    set -l commits (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)

    if [ $status != 0 ]
      _prompt_char_for_status $last_status
      return
    end

    set -l behind (count (for arg in $commits; echo $arg; end | grep '^<'))
    set -l ahead  (count (for arg in $commits; echo $arg; end | grep -v '^<'))
    switch "$ahead $behind"
      case ''     # no upstream
      case '0 0'  # equal to upstream
        _print_in_color '' white
      case '* 0'  # ahead of upstream
        _print_in_color " $_git_ahead_upstream_symbol" brblue
      case '0 *'  # behind upstream
        _print_in_color " $_git_behind_upstream_symbol" brred
      case '*'    # diverged from upstream
        _print_in_color " $_git_ahead_upstream_symbol" brblue
        _print_in_color "$_git_ahead_upstream_symbol" brred
    end
  end

  # Prompt char
  _prompt_char_for_status $last_status
end
