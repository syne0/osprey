<#
.SYNOPSIS
    Show Osprey Help and creates the Osprey_Help.txt file
.DESCRIPTION
    Show Osprey Help and creates the Osprey_Help.txt file
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
Function Show-OspreyHelp {

	Out-LogFile "Creating Osprey Help File"

	$help = "BASIC USAGE INFORMATION FOR THE OSPREY MODULE
	===========================================
	Osprey is a fork of Hawk which differs from it in several ways. It is in constant development and is updated 
	to reflect new tactics of threat actors.
	
	DISCLAIMER:
	===========================================
	While the original Hawk module was created by Microsoft employees and other experienced developers,
	Osprey was created and is primarily maintained by a single person that does not have years of
	experience with PowerShell development. Complicated issues may take some time to fix or need to
	be written out of the module. Users of Osprey are encouraged to troubleshoot issues on their own
	and submit any fixes as a as a pull request to the modules Github repository.

	PURPOSE:
	===========================================
	The Osprey module has been designed to ease the burden on M365 administrators who are performing
	a forensic analysis in their organization.

	It does NOT take the place of a human reviewing the data generated and is simply here to make
	data gathering easier.

	HOW TO USE:
	===========================================
	You must run Start-Osprey to initialize the module and settings. If you run Start-Osprey again after
	it's first initialization, it will offer to redo the initialization with a new tenant or using
	different settings, such as changing the investigation range.
	
	Osprey is divided into two primary forms of cmdlets; user based Cmdlets and Tenant based cmdlets.
	User based cmdlets take the form Verb-OspreyUser<action>.  They all expect a -user switch and
	will retrieve information specific to the user that is specified.  Tenant based cmdlets take
	the form Verb-OspreyTenant<Action>.  They don't need any switches and will return information
	about the whole tenant.

	You can then run Start-OspreyTenantInvestigation. This will run all the tenant-based
	cmdlets and provide a collection of data to start with.  Once this data has been reviewed
	if there are specific user(s) that more information should be gathered on
	Start-OspreyUserInvestigation will gather all the User specific information for a single user.

	All Osprey cmdlets include help that provides an overview of the data they gather and a listing
	of all possible output files.  Run Get-Help <cmdlet> -full to see the full help output for a
	given Osprey cmdlet.

	Some of the Osprey cmdlets will flag results that should be further reviewed.  These will appear
	in _Investigate files.  These are NOT indicative of unwanted activity but are simply things
	that should reviewed.

	REVIEW OSPREY CODE:
	===========================================
	The Osprey module is written in PowerShell and only uses cmdlets and function that are available
	to all O365 customers.  Since it is written in PowerShell anyone who has downloaded it can
	and is encouraged to review the code so that they have a clear understanding of what it is doing
	and are comfortable with it prior to running it in their environment.

	To view the code in notepad run the following command in powershell:
		notepad (join-path ((get-module Osprey -ListAvailable)[0]).modulebase 'Osprey.psm1')
	To get the path for the module for use in other application run:
		((Get-module Osprey -listavailable)[0]).modulebase"

	$help | Out-MultipleFileType -FilePrefix "Osprey_Help" -txt

	Notepad (Join-Path $Osprey.filepath "Tenant\Osprey_Help.txt")

}
