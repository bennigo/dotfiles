# Recovering from DNS / name-resolution failures

## Quick recovery after a work VPN timeout

1. Disconnect the Cisco work VPN fully. Keep Wi-Fi/Ethernet connected.
2. Try the normal resolver repair:

   ```bash
   sudo systemctl reset-failed systemd-resolved
   sudo systemctl restart systemd-resolved
   systemctl is-active systemd-resolved
   dig @127.0.0.53 example.com +time=2 +tries=1
   getent ahostsv4 example.com
   ```

   A successful restart regenerates the stub file. Normally `/etc/resolv.conf`
   is a symlink to `/run/systemd/resolve/stub-resolv.conf`, whose nameserver is
   `127.0.0.53`. Do not hand-edit that generated file.

3. If startup fails or DNS still does not work, use the emergency file below.
4. Once public DNS works, reconnect the work VPN and test a known private work
   hostname. Public DNS alone cannot resolve private work names.

## Emergency public DNS (no internet download needed)

The installed contingency file is `/etc/resolv.conf.contingency`. Its tracked
source is `~/.dotfiles/system/etc/resolv.conf.contingency`.
It uses Google (`8.8.8.8`) and Cloudflare (`1.1.1.1`).

**Disconnect the work VPN before activating this fallback.** It sends DNS queries
outside the work resolver, cannot resolve private work names, and may be blocked
by VPN policy. It is a temporary workaround, not a permanent VPN DNS setting.

```bash
# Only necessary after reinstall / if the contingency file is missing:
sudo install -m0644 ~/.dotfiles/system/etc/resolv.conf.contingency /etc/resolv.conf.contingency

# Preserve both the link/file and its current contents before changing it:
stamp=$(date +%Y%m%d-%H%M%S)
sudo cp -a /etc/resolv.conf "/etc/resolv.conf.before-recovery-$stamp"
sudo cp -L /etc/resolv.conf "/etc/resolv.conf.contents-$stamp"

# IMPORTANT: replace the symlink, rather than writing through it into /run.
sudo cp --remove-destination /etc/resolv.conf.contingency /etc/resolv.conf
getent ahostsv4 example.com
```

The existing `resolv-fallback` watchdog may put `1.1.1.1` first while the VPN is
down; that is expected. Do not make the file immutable (`chattr +i`): Cisco and
the normal network stack need to update DNS.

## Return to normal DNS

**Automatic since 2026-10-29:** `resolv-fallback` (path trigger + 5 min timer) restores
the stub symlink by itself once the tunnel is down, systemd-resolved is active, and
`dig @127.0.0.53 example.com` returns an address. It recognises the contingency file
by its `# EMERGENCY ONLY` header, so keep that line. Check with
`journalctl -t resolv-fallback`, looking for "contingency retired". The manual steps
below are still valid if you want to restore it sooner, or while the VPN is up.

If work NFS mounts are unreachable and the resolver cannot start, reconnect the
VPN using the working public-DNS workaround first. Then:

```bash
sudo systemctl reset-failed systemd-resolved
sudo systemctl restart systemd-resolved
systemctl is-active systemd-resolved
resolvectl status
dig @127.0.0.53 example.com +time=2 +tries=1
```

**Only after the service is active AND the direct stub query succeeds**, restore
the managed symlink (preferably while disconnected from the VPN, so Cisco is not
simultaneously rewriting it):

```bash
sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
getent ahostsv4 example.com
```

Reconnect the work VPN if disconnected. Test a known private hostname, e.g.
`getent ahostsv4 granit.vedur.is`, as well as a public hostname. Cisco may replace
the resolver file with its own VPN DNS configuration; that is expected while
connected. Do not add public DNS to the live VPN configuration as a substitute
for restoring private DNS.

## Diagnose before changing more settings

```bash
ls -l /etc/resolv.conf
systemctl is-active systemd-resolved
nmcli -f GENERAL.DEVICE,GENERAL.STATE,IP4.DNS device show
ip -brief link
ip route show default
dig @8.8.8.8 example.com +time=2 +tries=1
dig @127.0.0.53 example.com +time=2 +tries=1
getent ahostsv4 example.com
journalctl -u systemd-resolved -b -n 40 --no-pager
```

- Direct public query works, stub query fails: local resolver/service problem.
- Both direct queries fail: check connectivity, routes, captive portal, firewall,
  or VPN policy; changing `resolv.conf` may not help.
- Public names work, private names fail: check VPN connection and work DNS.
- Resolver startup repeatedly times out: inspect its process, not just DNS:

  ```bash
  pid=$(systemctl show systemd-resolved -p MainPID --value)
  if [ "$pid" != 0 ]; then
      sudo ps -p "$pid" -o pid,stat,wchan:40,comm
      sudo head -30 "/proc/$pid/stack"
  fi
  ```

  `D` state with `rpc_wait_bit_killable` indicates blocked kernel RPC/NFS I/O,
  not an incorrect nameserver. Re-establishing the VPN may unblock access to
  mounted work servers. Do not forcibly unmount work shares while jobs use them,
  disable service sandboxing, or restart all networking as the first response.

## Incident observed 2026-10-27

- `/etc/resolv.conf` was still the normal systemd-resolved stub symlink, but the
  generated file had been manually changed to `nameserver 8.8.8.8`.
- `systemd-resolved` was failed with repeated 15-second startup timeouts.
- Wi-Fi remained connected with DHCP DNS `192.168.50.1`; no Cisco tunnel existed.
- Public lookups via the manual Google workaround succeeded.
- A restart still timed out; during a retry, its pre-exec process was observed in
  `D` state waiting in `rpc_wait_bit_killable`. Work NFS mounts remained mounted.
  This suggests unavailable work storage was blocking startup, though a complete
  kernel stack trace was not captured to establish the exact startup dependency.
- After the user reconnected the VPN, systemd-resolved became active and
  regenerated its stub with `nameserver 127.0.0.53`. Cisco replaced
  `/etc/resolv.conf` with a regular file using `10.170.255.230` and
  `10.170.255.240`, with the `vedur.is` search domain. That VPN-owned file was
  deliberately left in place rather than forcing a symlink during the session.
- Verified public resolution (`example.com`), private resolution
  (`granit.vedur.is` → `10.170.10.10`), and a direct query to the local stub.
- Emergency file installed; existing recovery automation left unchanged.

The existing automatic `resolv-fallback` handles stale VPN DNS in a **regular**
`/etc/resolv.conf` when the tunnel is down. It intentionally skips symlinks and
therefore does not repair a failed systemd-resolved service in this incident.

## Incident observed 2026-10-28 (repeat)

Same mechanism as 10-27, now traced from the journal:

1. **19:47:15** The VPN gateway ended the session ("Max time exceeded", reason 21).
   As Cisco restored the OS configuration, it **restarted systemd-resolved**.
2. All NFS mounts (`clientaddr` = the VPN address) became unreachable. The kernel
   logged `nfs: server … not responding` from 19:47:30.
3. The new resolved process never logged a single line. Every start hit the 15 s
   `TimeoutStartSec` until 20:07:47 (start-limit-hit). It started cleanly at 20:08:37,
   with the VPN still down. Why it was released at that moment is unknown.
   Likely mechanism: resolved's sandbox (`ProtectSystem=strict`, `ProtectHome`,
   `PrivateTmp`) builds a mount namespace that touches every mount, and each dead
   **soft** NFS op takes about `timeo=50` × `retrans=2`. That matches the 10-27
   `rpc_wait_bit_killable` observation.
4. With DNS down, Cisco could not resolve `vpn.vedur.is` to reconnect (20:00, 20:04),
   and `dotfiles-sync` / `epos-rerinex-watch` failed.
5. **20:05:23** The emergency file was activated per this runbook. The "Return to
   normal DNS" step was never done. Public-only DNS stayed in place until 10-29 13:57,
   which broke `tosGPS` (`vi-api.vedur.is` NameResolutionError).

Changes made after it: auto-retire of the contingency file (above), and the
5 min timer actually deployed (it had drifted at 30 s).

**Root-cause mitigation (applied 2026-10-29):** 12 of the 15 NFS automounts in
`system/etc/fstab` had no `x-systemd.idle-timeout`, so once they had been touched
they stayed mounted forever and all went dead together on a VPN drop. All 15 now
carry `x-systemd.idle-timeout=600`, so idle shares fall back to bare autofs points,
which should not block namespace setup. A share in active use at the moment of a
drop can still hang resolved, so this narrows the window; it does not close it.
How it was applied: back up `/etc/fstab` (to `/etc/fstab.bak-20261029-idle-timeout`),
install the new file, run `daemon-reload`, then for each idle share run `umount`
followed by `systemctl restart <unit>.automount`. A running autofs point keeps its
old timeout until its automount unit restarts. Verify the setting with
`findmnt /mnt_data/<share>` (look for `timeout=600` on the autofs line).
