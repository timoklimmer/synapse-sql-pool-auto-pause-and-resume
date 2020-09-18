# Synapse SQL Pool Auto Pause and Resume

![Pause SQL Pool](https://github.com/timoklimmer/synapse-sql-pool-auto-pause-and-resume/workflows/Pause%20SQL%20Pool/badge.svg)
![Resume SQL Pool](https://github.com/timoklimmer/synapse-sql-pool-auto-pause-and-resume/workflows/Resume%20SQL%20Pool/badge.svg)

This sample shows how to auto-pause and resume a Synapse SQL Pool using Github Actions according to a specified
schedule.

To use, clone this repo AND configure the secrets in your GitHub repo as follows AND update the workflow files as
described below to activate schedules.

| Secret Name             | Content                                              |
| ----------------------- |------------------------------------------------------| 
| RESOURCE_GROUP          | The resource group where the Synapse SQL Pool is in. | 
| SYNAPSE_WORKSPACE_NAME  | The name of the Synapse workspace.                   | 
| SQL_POOL_NAME           | The name of the SQL Pool.                            |
| AZURE_CREDENTIALS       | Describes the service principal used for resuming/pausing the SQL Pool.<br/>See the included [azure-sp-credentials.sample.json](azure-sp-credentials.sample.json) file for an example. |
| SQL_SERVER_ENDPOINT     | Server endpoint of the SQL Pool.                     |
| SQL_DATABASE            | SQL Pool database name.                              |
| SQL_USER                | Name of a SQL user which can check if the script can pause. See [can_pause.sql](can_pause.sql) for details.|
| SQL_PASSWORD            | Password for the SQL user above.                     |


Pause/resume schedules can be modified/activated by editing and committing the respective cron schedule expressions in
the included `pause-sql-pool.yml` and/or `resume-sql-pool.yml` files in folder `.github/workflows`.

Note: For cost saving reasons, the code committed here has the schedules disabled. To activate regular pausing/resuming,
remove the respective comments in the files above.

[https://crontab.guru](https://crontab.guru) is an excellent help for writing cron schedule expressions. Please note
that all cron schedule expressions relate to UTC and not to your local time!

As a deployment alternative, you can also take the included `pause-sql-pool.yml` and/or `resume-sql-pool.yml` files over
to your existing repository and configure the settings above in your existing repo.

Be aware that running the pause and resume workflows will deduct some minutes from your monthly minutes quota. In most
of the cases, this will likely not be a problem because you might have some free minutes anyway - but you should be
aware at least.

If you need to setup a SQL Pool first for testing, you can use the included `setup-synapse-sql-pool.sh` script.

As always, provided "as is". Feel free to use but don't blame me if things go wrong.