if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    alias lg lazygit
    alias ls 'eza --icons --group-directories-first'
end
