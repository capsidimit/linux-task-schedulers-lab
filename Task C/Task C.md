# Level C (Basic): “Primary automation of routine operations”

**Scenario:** You are a system administrator who needs to prepare an environment for automatic backup of configuration files and disk space monitoring.

**Tasks:**

1. **Set up a one-time task using `at`:**
    - Five minutes after startup, create a report on the current state of the system in the file `/tmp/system_report.txt` (contents: date, uptime, free space on the root partition, active users)

    ```bash
    pushd .
    mkdir -pv ~/projects/linux-task-schedulers-lab/task-c/
    cd ~/projects/linux-task-schedulers-lab/task-c/
    cat > ./system-report.sh <<-EOF
    #!/bin/bash

    echo "[\$(date --iso-8601=seconds)]" "Server is" "\$(uptime -p)," "space avaliable on root" "\$(df -h | egrep "/$" | awk '{print \$4}')," "\$(who | wc -l)" "active users" >> /tmp/system_report.txt
    EOF
    chmod +x ./system-report.sh
    at now + 5 minutes -f ./system-report.sh

    popd
    ```

    - Make sure the task has been created, view its details

    ```bash
    $ atq
    15      Mon Nov 17 01:00:00 2025 a axedo
    $ at -c 14
    #!/bin/sh
    # atrun uid=1000 gid=1000
    # mail axedo 0
    ...
    #!/bin/bash

    echo "[$(date --iso-8601=seconds)]" "Server is" "$(uptime -p)," "space avaliable on root" "$(df -h | egrep "/$" | awk '{print $4}')," "$(who | wc -l)" "active users" >> /tmp/system_report.txt
    ```

    - After execution, check the file contents and remove the task from the queue

    ```bash
    $ cat /tmp/system_report.txt

    [2025-11-17T01:00:00+03:00] Server is up 11 hours, 34 minutes, space avaliable on root 954G, 2 active users
    $ #Task was automatically removed after execution
    $ atq
    $
    ```

2. **Basic task in `cron`:**
    - Set up hourly execution of a script that creates the file `/tmp/hourly_mark` with the current timestamp

    ```bash
    pushd .
    mkdir -pv ~/projects/linux-task-schedulers-lab/task-c/
    cd ~/projects/linux-task-schedulers-lab/task-c/
    cat > ./hourly-mark.sh <<-EOF
    #!/bin/bash

    echo "\$(date +%s)" > /tmp/hourly_mark
    EOF
    chmod +x ./hourly-mark.sh
    
    popd
    ```

    - Use the syntax with a step (`*/n`)

    ```bash
    */2 * * * * ~/projects/linux-task-schedulers-lab/task-c/hourly-mark.sh
    ```

    - Make sure the task is added to your user crontab

    ```bash
    $ crontab -l
    */2 * * * * ~/projects/linux-task-schedulers-lab/task-c/hourly-mark.sh
    ```

    - Wait for execution (or simulate it) and confirm that it works

    ```bash
    $ date && cat /tmp/hourly_mark
    Mon Nov 17 01:38:06 MSK 2025
    1763332681
    ```

3. **Access control:**
    - Create a user `testuser` without sudo privileges

    ```bash
    sudo adduser testuser
    ```

    - Prohibit them from using `at`, leaving it available for other users

    ```bash
    echo "testuser"| sudo tee -a /etc/at.deny
    ```

    - Verify the prohibition by attempting to create a task on their behalf

    ```bash
    $ su - testuser
    $ atq
    You do not have permission to use atq.
    $ batch
    You do not have permission to use at.
    $ at noon
    You do not have permission to use at.
    ```

**Key performance indicators:**

- `atq` shows the correct task with your name
- The `/tmp/hourly_mark` file is updated every hour ±1 minute
- `testuser` receives a refusal when executing `at noon`
