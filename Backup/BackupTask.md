# Creating a Backup Task

- Copy `SpecFile1.ps1` from the `Backup` folder to a new location and customize it to suit your backup requirements.

- Copy `BackupTask.vbs` from the `Backup` folder to a new location and customize the `common2` variable to reflect the correct, absolute file locations for `Backup.ps1` and `SpecFile1.ps1`.

- Open `TaskSchd.msc`.
- Create a new folder and select it.
- Under *Actions*, click *Create Task...*
- In the *General* tab, 

  - Type a name and a description.

- In the *Triggers* tab, click *New...* and then in the *New Trigger* window select

  - *At log in*.
  - *Specific user*.
  - Delay task for *10 minutes*.
  - Repeat task every *10 minutes*.
  - ... for a duration of *indefinitely*.
  - *Enabled* should be checked.
  - Click *OK* to save changes.

- In the *Actions* tab click *New...* and then in the *New Action* window,

  - Select *Start  program*.
  - Type `wscript` in the *Program/script:* field.
  - In the *Add arguments* field, type the path to your customized `BackupTask.vbs`, including the filename. Surround it in quotes if there are spaces in the path, or if you are unsure. Example:

  ```
  "$env:Project42/Backup/BackupTask.vbs"
  ```

  - Click *OK* to save changes.

- In the *Settings* tab,

  - Under *If the task is already running...*, select *Run a new instance in parallel*.
  - Click *OK* to save changes.

- Click *OK* in the *Create Task* window to create the task.

- Log off and log in to trigger the task.

## Note

> If you make changes to the task, and save the 
> changes, you will need to log off then back on, 
> in order to re-trigger the task.