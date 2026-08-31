#!/usr/bin/python3
"""
Generate a seccomp-BPF blocklist filter for the Claude bwrap sandbox.

  /usr/bin/python3 gen-claude-seccomp.py [output.bpf]     (default: claude-seccomp.bpf)

Point the launcher at the result:  set -x X_CLAUDE_SECCOMP /path/to/claude-seccomp.bpf
The .bpf is the raw program bwrap loads via `--seccomp <fd>`; regenerate it if you
edit this file. Requires python3-libseccomp (module `seccomp`); use the SYSTEM python
(/usr/bin/python3), the Nix python does not have the binding here.

Design: default action ALLOW, then deny a curated set of dangerous syscalls with EPERM
(so programs get a clean error instead of dying). Modelled on flatpak's setup_seccomp()
blocklist, plus two mitigations specific to SANDBOX-ASSESSMENT.md:
  - deny unshare/clone with CLONE_NEWUSER  -> shuts the nested-userns kernel-LPE path
  - deny ioctl TIOCSTI / TIOCLINUX         -> terminal command injection
clone3 is forced to ENOSYS so glibc falls back to clone() (which we arg-filter); without
this, newer glibc could create namespaces via clone3 and bypass the clone() rule.
io_uring_setup is denied (large async kernel attack surface). The filter carries only the
x86_64 ABI; any syscall via a foreign ABI (i386 / x32) is KILLED (SIGSYS, whole process).
"""

import errno
import sys

import seccomp

# clone/unshare namespace flags (identical across arches)
CLONE_NEWUSER = 0x10000000

# ioctl request numbers (identical across arches)
TIOCSTI = 0x5412  # fake terminal input -> command injection into the parent tty
TIOCLINUX = 0x541C  # selection/paste ioctl, another injection vector

EPERM = errno.EPERM
ENOSYS = errno.ENOSYS

# for reference:
# https://github.com/flatpak/flatpak/blob/70011ab5d4c3349b835ebd10434c70c2fb71885e/common/flatpak-run.c#L2035
# Plain syscalls denied outright with EPERM.
BLOCK_EPERM = [
    # kernel keyring
    "add_key",
    "keyctl",
    "request_key",
    # loadable kernel modules
    "init_module",
    "finit_module",
    "delete_module",
    # replace the running kernel
    "kexec_load",
    "kexec_file_load",
    # tracing / privileged perf / bpf
    "ptrace",
    "perf_event_open",
    "bpf",
    # io_uring: large async kernel attack surface; deny ring creation
    "io_uring_setup",
    # accounting / quota / kernel log / obsolete
    "acct",
    "quotactl",
    "syslog",
    "uselib",
    "nfsservctl",
    "_sysctl",
    # NUMA / scary VM
    "move_pages",
    "mbind",
    "get_mempolicy",
    "set_mempolicy",
    "migrate_pages",
    # wall-clock / time manipulation
    "settimeofday",
    "stime",
    "clock_settime",
    "clock_adjtime",
    "adjtimex",
    # swap
    "swapon",
    "swapoff",
    # mount / rootfs manipulation (container-escape primitives)
    "mount",
    "umount2",
    "pivot_root",
    "chroot",
    "mount_setattr",
    "open_tree",
    "move_mount",
    "fsopen",
    "fsconfig",
    "fsmount",
    "fspick",
    # join existing namespaces
    "setns",
    # x86 io-port privilege
    "iopl",
    "ioperm",
    # misc host-affecting
    "reboot",
    "vhangup",
]


def build():
    f = seccomp.SyscallFilter(defaction=seccomp.ALLOW)
    # Native ABI only: the filter carries ONLY x86_64. Any syscall issued under a
    # foreign ABI (i386, or the x32 sub-ABI, which libseccomp guards when its arch
    # is absent) hits the bad-arch action below. We set that to KILL_PROCESS, so a
    # process trying to reach the kernel via a non-x86_64 ABI is killed outright
    # (SIGSYS), not merely given an error -- closes ABI-switching bypasses.
    f.set_attr(seccomp.Attr.ACT_BADARCH, seccomp.KILL_PROCESS)

    def rule(action, name, *args):
        try:
            f.add_rule(action, name, *args)
        except Exception as e:
            # syscall may not exist on every arch/kernel; skip it, keep going
            print(f"  skip {name}: {e}", file=sys.stderr)

    for name in BLOCK_EPERM:
        rule(seccomp.ERRNO(EPERM), name)

    # Force clone3 -> ENOSYS so libc retries with clone(), which we filter below.
    rule(seccomp.ERRNO(ENOSYS), "clone3")

    # Deny creating a new USER namespace (the LPE lever), but allow ordinary
    # thread/process creation: match only when the CLONE_NEWUSER bit is set.
    #   clone(flags=arg0, ...)   unshare(flags=arg0)
    rule(
        seccomp.ERRNO(EPERM),
        "clone",
        seccomp.Arg(0, seccomp.MASKED_EQ, CLONE_NEWUSER, CLONE_NEWUSER),
    )
    rule(
        seccomp.ERRNO(EPERM),
        "unshare",
        seccomp.Arg(0, seccomp.MASKED_EQ, CLONE_NEWUSER, CLONE_NEWUSER),
    )

    # Deny terminal-injection ioctls: ioctl(fd, request=arg1, ...)
    rule(seccomp.ERRNO(EPERM), "ioctl", seccomp.Arg(1, seccomp.EQ, TIOCSTI))
    rule(seccomp.ERRNO(EPERM), "ioctl", seccomp.Arg(1, seccomp.EQ, TIOCLINUX))
    return f


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "seccomp.bpf"
    f = build()
    with open(out, "wb") as fh:
        f.export_bpf(fh)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
