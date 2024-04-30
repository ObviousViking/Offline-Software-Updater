# Offline-Software-Updater
Automatically update software on machines running in an air-gapped environment

To add software:

Create a central repository somewhere that all machines on your network can access and edit the below line to match:

$centralPath = "C:\USEFUL_TOOLS\Software Updater\TEST\" # <<<<<< change to central repo for your softare updaters

Each software you want to use needs its own folder, which would look like this:  
C:\USEFUL_TOOLS\Software Updater\TEST\VLC  
C:\USEFUL_TOOLS\Software Updater\TEST\7zip  
C:\USEFUL_TOOLS\Software Updater\TEST\Notepad++  

Put only the newest installer in its respective folder.  

IMPOORTANT: make sure you add a folder centrally for the script. C:\USEFUL_TOOLS\Software Updater\TEST\Script   <<<<< this one is required in order to update the script automatically  
This way you only need update 1 version of the script with new software and it will automatically be rolled out.  

You then need to add the software to the central script. Ive left some examples in for the programs above. Its pretty straight forward.  

Note: Xways was a special use case for myself and just needed extracting to a folder for use. This could be removed if not needed.  

How to use:  
On each machine you want to update(should be a one time set up):  

Create a folder in the root of C: named 'USEFUL_TOOLS'.  

Inside that create 3 more folders, 'Hashes', 'Temp' and 'Files'  

Put the Software Updater.ps1 in the files folder and set a scheduled task to run it when you like. I had 6am every morning.  
  

What should happen at 6am?  
Script runs  
Checks the central location for files  
If there then hash that installer and compare against locally stored hash from previous install  
If no hash or hash different, copy installer locally to temp folder  
Check if process running and wait for user input  
Run installer or skip if user skipped  
Update hash  
Loop through software  
Check if central script has been updated  
If yes copy locally  
Clean temp folder
