
alias upd='sudo apt update; sudo apt upgrade -y'
alias top='htop'
alias log='tail -f storage/logs/laravel-$(date +%F).log'
alias logs='tmux \
  new-session  "tail -f storage/logs/laravel-$(date +%F).log ; read" \; \
  split-window "tail -f storage/logs/worker.log ; read" \; \
  select-layout even-vertical'

# git give up
nah () {
    git reset --hard
    git clean -df
    if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then
        git rebase --abort
    fi
}

_nvmrc_hook() {
  if [[ $PWD == $PREV_PWD ]]; then
    return
  fi
  
  PREV_PWD=$PWD
  [[ -f ".nvmrc" ]] && nvm use
}

if ! [[ "${PROMPT_COMMAND:-}" =~ _nvmrc_hook ]]; then
  PROMPT_COMMAND="_nvmrc_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi
