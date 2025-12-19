# Level B (Intermediate): “Server Performance Optimization”

**Scenario:** On a high-load production server, you need to configure intelligent scheduling of resource-intensive operations.

**Tasks:**

1. **Adaptive scheduling with `batch`:**
    - Create a script `/usr/local/bin/heavy_task.sh` that:
        - Writes the current load average to `/var/log/load_before_task.log` (I'll use `/tmp/load_before_task.log` to bypass rights restrictions)
        - Performs synthetic load: `stress-ng --cpu 2 --timeout 30s` (pre-install)
        - Writes the load after execution to `/var/log/load_after_task.log` (I'll use `/tmp/load_after_task.log` to bypass rights restrictions)
    - Schedule this script to run via `batch` when the load is low
    - Create a background load (`stress-ng --cpu 4` in a separate session) and demonstrate that `batch` defers execution

    ```bash
    $ cat /proc/loadavg
    1.87 0.49 0.18 5/339 5637
    $ batch 
    at> /home/axedo/projects/linux-task-schedulers-lab/task-b/heavy_task.sh
    at> <EOT>
    job 18 at Sat Nov 22 16:08:00 2025
    axedo@DESKTOP-NCT18JB:~/projects/linux-task-schedulers-lab/task-b$ atq
    18      Sat Nov 22 16:08:00 2025 b axedo
    ...
    $ cat /proc/loadavg && atq

    0.40 1.43 0.95 1/334 8839
    ```

    - Analyze the difference in load from the logs

    ```bash
    $ diff /tmp/load_before_task.log /tmp/load_after_task.log 
    1c1
    < [2025-11-22T16:16:55+03:00] 0.16 1.18 0.89 1/332 9187
    ---
    > [2025-11-22T16:17:26+03:00] 1.00 1.29 0.94 1/336 9364
    ```

2. **Complex schedule in `cron`:**
    - Set up complex backups:
        - Create folders

        ```bash
        # Performed as root user
        mkdir -pv /backup/etc/incremental
        mkdir -pv /backup/home/full
        ```

        - Every 15 minutes: incremental backup of `/etc/` to `/backup/etc/incremental`

        ```bash
        */15 * * * * tar czvf /backup/etc/incremental/etc_$(date '+%Y-%m-%d_%H-%M').tar.gz /etc 2>&1 | while IFS= read -r line; do printf '%s %s\n' "[$(date --iso-8601=seconds)]" "$line"; done >> /var/log/custom_backup.log
        ```

        - Daily at 02:30: full backup of `/home/` to `/backup/home/full`

        ```bash
        30 02 * * * tar czvf /backup/home/full/home_$(date '+%Y-%m-%d_%H-%M').tar.gz /home 2>&1 | while IFS= read -r line; do printf '%s %s\n' "[$(date --iso-8601=seconds)]" "$line"; done >> /var/log/custom_backup.log
        ```

        - Weekdays at 18:00: clean up temporary files older than 7 days from `/tmp/`

        ```bash
        00 18 * * 0,6 find /tmp/ -type f -mtime +7 -exec rm -f {} \; 2>&1 | while IFS= read -r line; do printf '%s %s\n' "[$(date --iso-8601=seconds)]" "$line"; done >> /var/log/custom_backup.log
        ```

        - Sundays at 23:00: synchronize `/backup/` to a remote server (use `rsync` with `-avz --dry-run` parameters to simulate)

        ```bash
        00 23 * * 0 rsync -avz --dry-run /backup/ backup@backup-server.local:/home/backup/my-wsl-backups 2>&1 | while IFS= read -r line; do printf '%s %s\n' "[$(date --iso-8601=seconds)]" "$line"; done >> /var/log/custom_backup.log
        ```

    - All tasks must use the system crontab (`/etc/crontab`) with explicit user specification
    - Ensure that each operation is logged in `/var/log/custom_backup.log` with timestamps

3. **Configure `anacron` for reliability:**
    - Create a script `/etc/cron.weekly/system_audit.sh` that:
        - Generates a report of installed packages (`rpm -qa` or `dpkg -l`)
        - Checks the integrity of system files (`rpm -Va` or `debsums`)
        - Saves the result to `/var/log/weekly_audit_$(date +%Y%m%d).log`
    - Ensure that anacron runs it on boot if the server was down at the scheduled time
    - Set RANDOM_DELAY=15 and START_HOURS_RANGE=20:00-23:00 for this task
    - Simulate skipping execution (by changing the last run date in `/var/spool/anacron/`) and verify startup on boot

**Key performance indicators:**

- `batch` postpones execution when load average > 0.8 and runs when it decreases
- Cron tasks run strictly on schedule (check via `grep` in logs)
- Anacron runs the missed task in the range 20:00-23:00 ±15 minutes
