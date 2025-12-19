# Level A (Advanced): “Migration to systemd timers and security”

**Scenario:** The company is migrating to CentOS 8+ and requires migration from legacy schedulers to systemd timers to improve manageability and auditing.

**Tasks:**

1. **Reconstruct cron using systemd timers:**
   - Analyze the existing complex cron job (create it for example):

     ```bash
     # /etc/crontab
     */10 8-18 * * 1-5 root /usr/local/bin/business-hours-monitor.sh
     ```

   - Create a complete set of unit files for systemd:
      - Service `/etc/systemd/system/business-monitor.service` with restrictions (MemoryMax=100M, CPUQuota=20%)
      - Timer `/etc/systemd/system/business-monitor.timer` with exactly the same schedule (`OnCalendar=Mon..Fri 08..18:*:0/10`)
      - Add a randomized delay of 30 seconds (`RandomizedDelaySec=30`)
      - Ensure persistent execution (`Persistent=true`) and correct handling of skips
   - Enable the timer, check the status, and demonstrate the benefits via `systemctl list-timers` and logs (`journalctl -u business-monitor`)
   - Compare execution accuracy with cron (±1 minute vs. similar)

2. **Create a dynamic scheduler:**
   - Develop a system that:
      - Checks the root partition (`/`) for fullness every hour
      - When it exceeds 80%, it triggers immediate cleanup via `systemd-run` (temporary service and timer)
      - Cleanup includes: deleting old logs, clearing the package cache, archiving and deleting old backups
      - All actions are logged in `journalctl` with a `warning` level
   - Create a bash script coordinator `/usr/local/bin/disk-space-guard.sh`, which will be run via a permanent timer
   - Demonstrate operation by simulating high occupancy (by creating a large file)

3. **Audit and security of schedulers:**
   - Implement a system for monitoring unauthorized tasks:
      - Create a script `/usr/local/bin/audit-schedulers.sh` that performs the following daily:
          - Collects all user crontabs (`for user in $(cut -f1 -d: /etc/passwd); do crontab -u $user -l 2>/dev/null; done`)
          - Checks the contents of `/var/spool/at/`, `/var/spool/cron/`
          - Identifies all active systemd timers (`systemctl list-timers --all --no-pager`)
          - Compares cron file hashes with reference hashes (create `/etc/security/cron.digest` with `sha256sum`)
          - Sends a report to the administrator (use `mail -s “Scheduler Audit Report” root < /tmp/audit_report`)
      - Configure systemd timer to run this script at 06:00 daily
   - Add protection: create `/etc/cron.allow`, allowing only root and your user
   - Demonstrate detection of a “suspicious” task (manually add a cron entry on behalf of testuser)

**Key performance indicators:**

- systemd timer shows `NEXT` and `LEFT` with accuracy to the second
- `journalctl -u business-monitor` contains records of each launch with resource restrictions
- When >80% is filled, immediate cleanup is triggered, visible in `systemctl list-jobs`
- The audit report contains all 4 types of schedulers and a warning about an unauthorized task