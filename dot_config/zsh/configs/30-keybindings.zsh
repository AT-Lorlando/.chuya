# Key bindings for word movement
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Key bindings for word deletion
bindkey "^[[3;5~" kill-word # Ctrl+Delete - delete word forward
bindkey "^H" backward-kill-word # Ctrl+Backspace - delete word backward
