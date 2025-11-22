# Lab work: “Automating tasks in Linux: schedulers from at to systemd timers”

## Content

- [[Task C\Task C.md]]
- [[Task B\Task B.md]]
- [[Task A\Task A.md]]
- [[Task S\Task S.md]]

## 1. Purpose and competencies to be developed

**Purpose of the assignment:** To master the practical skills of configuring and managing task schedulers in Linux environments for automating system administration, ensuring the selection of the optimal tool depending on the usage scenario.

**Skills and knowledge to be acquired:**

- Forming the syntax of time expressions for one-time and regular tasks
- Managing the task queue via `atd` with access control via `/etc/at.allow/deny`
- Configuring user and system crontabs using advanced patterns
- Setting up delayed execution at system startup via anacron
- Creating persistent systemd timer units as a modern alternative to cron
- Analyzing execution logs and debugging schedulers
- Evaluating performance and choosing a tool (at for one-time tasks, cron for regular tasks on 24/7 servers, anacron for desktops, systemd for complex dependencies)

---

## 2. Tasks

### Level C (Basic): “Primary automation of routine operations”

**Scenario:** You are a system administrator who needs to prepare an environment for automatic backup of configuration files and disk space monitoring.

**Tasks:**

1. **Set up a one-time task using `at`:**
   - Five minutes after startup, create a report on the current state of the system in the file `/tmp/system_report.txt` (contents: date, uptime, free space on the root partition, active users)
   - Make sure the task has been created, view its details
   - After execution, check the file contents and remove the task from the queue

2. **Basic task in `cron`:**
   - Set up hourly execution of a script that creates the file `/tmp/hourly_mark` with the current timestamp
   - Use the syntax with a step (`*/n`)
   - Make sure the task is added to your user crontab
   - Wait for execution (or simulate it) and confirm that it works

3. **Access control:**
   - Create a user `testuser` without sudo privileges
   - Prohibit them from using `at`, leaving it available for other users
   - Verify the prohibition by attempting to create a task on their behalf

**Key performance indicators:**

- `atq` shows the correct task with your name
- The `/tmp/hourly_mark` file is updated every hour ±1 minute
- `testuser` receives a refusal when executing `at noon`

---

### Level B (Intermediate): “Server Performance Optimization”

**Scenario:** On a high-load production server, you need to configure intelligent scheduling of resource-intensive operations.

**Tasks:**

1. **Adaptive scheduling with `batch`:**
   - Create a script `/usr/local/bin/heavy_task.sh` that:
      - Writes the current load average to `/var/log/load_before_task.log`
      - Performs synthetic load: `stress-ng --cpu 2 --timeout 30s` (pre-install)
      - Writes the load after execution to `/var/log/load_after_task.log`
   - Schedule this script to run via `batch` when the load is low
   - Create a background load (`stress-ng --cpu 4` in a separate session) and demonstrate that `batch` defers execution
   - Analyze the difference in load from the logs

2. **Complex schedule in `cron`:**
   - Set up complex backups:
      - Every 15 minutes: incremental backup of `/etc/` to `/backup/etc/incremental`
      - Daily at 02:30: full backup of `/home/` to `/backup/home/full`
      - Weekdays at 18:00: clean up temporary files older than 7 days from `/tmp/`
      - Sundays at 23:00: synchronize `/backup/` to a remote server (use `rsync` with `-avz --dry-run` parameters to simulate)
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

---

### Level A (Advanced): “Migration to systemd timers and security”

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

---

### Level S (Pet Project): “Building an SLA Monitoring System with Intelligent Planning”

**Project:** Develop and deploy a full-fledged automated SLA (Service Level Agreement) monitoring system for a hypothetical company with 3 levels of criticality.

**Requirements:**

1. **System architecture:**
   - Create an infrastructure consisting of 3 services:
      - `sla-monitor-low.service`: Checking the availability of external APIs (every 5 minutes)
      - `sla-monitor-medium.service`: Checking the status of the database and disk subsystem (every minute)
      - `sla-monitor-critical.service`: Monitoring critical processes (every 30 seconds)
   - Each service must:
      - Have different resource limitations (Critical: CPU 50%, Memory 200M; Medium: CPU 30%, Memory 100M; Low: CPU 10%, Memory 50M)
      - Write results to a structured JSON log `/var/log/sla/YYYY-MM-DD.json`
      - Send notifications when thresholds are violated (use `curl` in `ExecStartPost` for webhook simulation)

2. **Scheduling with correlation:**
   - Implement via systemd timers, taking into account:
      - `OnCalendar` for strict scheduling
      - `RandomizedDelaySec` for load distribution (0 for critical, 30s for medium, 2min for low)
      - `AccuracySec=1s` for critical, `AccuracySec=1min` for others
      - `Persistent=true` for all, with different skip handling policies (`OnBootSec=30s` for critical, `OnBootSec=5min` for low)
   - Add dependencies: critical monitoring does not start if the server is loaded >75% (use `ConditionPathExists=!/var/run/high_load.flag`, created by a separate timer)

3. **Reporting and analytics system:**
   - Create a daily reporting service (`sla-reporter.service`) that:
      - Aggregates data from JSON logs for the day
      - Creates an HTML report in `/var/www/sla/reports/YYYY-MM-DD.html` with graphs (use `gnuplot` or `python3+matplotlib`)
      - Calculates the SLA percentage (99.9% for critical, 98% for medium, 95% for low)
      - Archives old logs and deletes them after 30 days
   - Run scheduler: daily at 23:55 via systemd timer with `FixedRandomDelay=false`

4. **Deployment automation:**
   - Create an Ansible playbook or bash script that:
      - Installs all necessary dependencies (`stress-ng`, `gnuplot`, `mailx`)
      - Creates all unit files, directories, scripts
      - Configures access rights (only root can edit, read for the adm group)
      - Activates and starts all timers
      - Performs a smoke test (creates an artificial failure and checks the notification)

5. **Documentation and testing:**
   - Write `README.md` with:
      - A description of each component and how it works
      - Instructions for setting thresholds and changing schedules
      - A procedure for recovering from failures
   - Create a set of tests (`test_sla_system.sh`) that checks:
      - The correctness of the syntax of all unit files (`systemd-analyze verify`)
      - Timer execution for 10 minutes (metrics collection)
      - Report generation
      - Notification sending

**Pet project submission criteria:**

- All services are active and have no failed status during 24 hours of testing
- The system handles reboots correctly (all timers continue to work)
- HTML report contains real data for the day (minimum 3 executions of each monitoring)
- Smoke test passes successfully
- Playbook/deployment script runs without errors on a clean system
- Documentation allows a third-party administrator to change thresholds in <5 minutes

**Expert level assessment:**

- Demonstrate the system in action on a test VM for 2-3 hours
- Show journalctl with correlated events
- Demonstrate the HTML report in a browser
- Perform a failover test: `systemctl stop sla-monitor-critical.service` and show the timer's response

---

## 3. Assessment methodology

For each task, the student must demonstrate:

- **Level C:** Error-free execution of commands, correct output of test commands, presence of expected files
- **Level B:** Working scripts, log files with correct data, successful simulation of scenarios
- **Level A:** Active systemd units, logs with resource constraints, anomaly detection
- **Level S:** Fully functional system, automated deployment, clear reporting

**“Skill without concentration” principle:** The student must complete task S, then delete the entire configuration and restore it from the playbook in <15 minutes, demonstrating automated thinking.
