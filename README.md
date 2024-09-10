You can find the descriptions of the scripts and instructions here:
  1. Download the scripts to local (for example C:/temp)
  2. Open Command Prompt with Administrator mode on your PC
  3. Run command to start collecting query data (You need to have SQLCMD installed on your PC prior to this, and remember to replace the servername, db name, username and password below with yours):
      Sqlcmd -S matt0717.database.windows.net -U azureuser -P xxxxx -d db1 -i SQL_Azure_Perf_Stats.sql -o blocking.out
  4. Wait until the problem occurs
  5. Stop the command sqlcmd.exe by Ctrl+C
  6. Examine the out file and look at the period when you had the performance issue.






SQL_Azure_Perf_Stats_ReadonlyApplicable.sql
-> This is to collect query wait type and blocking info continuously
-> The collected data be like what you can find in Sample_SQL_Azure_Perf_Stats_ReadonlyApplicable.out in the repository




CPU_query.sql
-> This is to collect CPU stats (you can further modify it to collect IO stats, Log IO stats,..,etc
-> The collected data be like what you can find inSample_CPU_query.out
