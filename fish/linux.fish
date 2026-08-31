if command -v systemctl >/dev/null 2>/dev/null
    function syctl --description "alias: sudo systemcl"
        command sudo systemctl $argv
    end

    function usyctl --description "alias: systemctl --user"
        command systemctl --user $argv
    end

    function suspendme
        command sudo systemctl suspend
    end
end

function reslimit -d "start program in memory limiting cgroup 'building' and with lowest nice possible"
    # use cgroup to restrict memory usage of all processes and
    # nice to create low cpu scheduling priority
    #
    # cgroup v1 + libcgroup solution:
    #cgexec -g 'memory:building' nice -n 20 sh -c "$argv"

    # custom cgroup v2 solution:
    #set -l cgroupfs (mount | grep cgroup | awk '{print $3}')
    #set -l uid (id -u)
    #set -l cgname "reslimit"
    #set -l usercgroup "/user.slice/user-$uid.slice/user@$uid.service/"
    #set -l cg "$cgroupfs/$usercgroup/$cgname"
    #if mkdir -p "$cg";
    #    echo '24g' > "$cg/memory.max"
    #    bash -c "echo \$\$ > $cg/cgroup.procs && $argv"
    #else
    #    echo "ERROR: Failed to create cgroup '$cg' (mkdir fail)"
    #end

    # using systemd-run
    #set -l cmd
    command systemd-run --user --same-dir --collect --scope \
        -p MemoryMax=42G \
        -p IOWeight=1 \
        -p CPUWeight=1 \
        fish -c "$argv"
    #echo $cmd
    #command $cmd
end


function beep
    paplay /usr/share/sounds/gnome/default/alerts/drip.ogg
end



function inotifyrun
    set FORMAT (echo -e "\033[1;33m%w%f\033[0m written")
    eval "$argv"
    while inotifywait -qre close_write --format "$FORMAT" .
        eval "$argv"
    end
end
