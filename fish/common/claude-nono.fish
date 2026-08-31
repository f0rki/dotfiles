if command -v nono >/dev/null ^/dev/null;
    set CLAUDE_DEFAULT_NONO_PROFILE "claude-code"
    if test -e ~/.config/nono/profiles/claude1.json
        set CLAUDE_DEFAULT_NONO_PROFILE "claude1"
    end

    function claude-with-nono -a nonoflags claudeflags -d "run claude in a sandbox; configure nono"
        nono run --profile $CLAUDE_DEFAULT_NONO_PROFILE --allow-cwd (string split ' ' -- "$nonoflags") -- env CLAUDE_CODE_CERT_STORE=system claude (string split ' ' -- "$claudeflags")
    end

    function claude-yolo-with-nono -a nonoflags claudeflags -d "run claude in nono sandbox with configurable nono flags"
        set -p claudeflags "--dangerously-skip-permissions"
        claude-with-nono "$nonoflags" "$claudeflags"
    end

    function claude -d "run claude in a sandbox"
        if test "$PWD" != "$HOME"
            set nonoargs "--allow-cwd"
        end
        claude-with-nono "$nonoargs" "$argv"
    end

    function claude-yolo -d "run claude in a sandbox; yolo mode"
        set -p argv "--dangerously-skip-permissions"
        if test "$PWD" != "$HOME"
            set nonoargs "--allow-cwd"
        end
        claude-with-nono "$nonoargs" "$argv"
    end

    function claude-unsafe -d "run unsandboxed claude"
        command claude $argv
    end
end
