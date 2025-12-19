# Level S (Pet Project): “Building an SLA Monitoring System with Intelligent Planning”

**Project:** Develop and deploy a full-fledged automated SLA (Service Level Agreement) monitoring system for a hypothetical company with 3 levels of criticality.

** Requirements:**

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
