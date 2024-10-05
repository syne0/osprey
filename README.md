# Osprey Documentation
Please visit the wiki for details on running the Osprey module.

https://github.com/syne0/osprey/wiki

# Osprey + Github

## Important
Osprey is a fork of Hawk and was designed to remove deprecated dependent modules and implement QoL improvements.
Due to this, large portions of Hawk were removed or rewritten. It was decided that instead of trying to merge these changes into the existing module,
a new module would be created.
        
Osprey would not have been possible without the years of work that the community put into maintaining Hawk. A sincere thank you to the Hawk maintainers 
for everything you have done for the M365 IR and BEC community.

## Who can contribute:
Everyone is welcome to contribute to this tool.  The goal of the Osprey tool is to be a community lead tool and provides
security support professionals with the tools they need to quickly and easily gather data from O365 and Azure.

## What Osprey is and isn't
Osprey provides Limited analysis of the gathered data.  This is by design!
Osprey is here to help get all of the data in a single place it is not designed to make any significant
conclusions about this data. This is intentional since it is impossible for the tool to know enough about
your environment or what you are concerned about to make a legitimate analysis of the data.

Osprey's goal is to quickly get you the data that is needed to come to a conclusion; not to make the conclusion for you.
We've structured the exported data in a manner of which can help analysts quickly triage known malicious Indicators Of Compromise (IOC) but again
is NOT an all exhaustive list.
## How can I contribute:
Please post any issues you find to the Issue section, or request features in the Discussions section.

# Osprey
PowerShell Based tool for gathering information related to O365 intrusions and potential Breaches

## PURPOSE:
The Osprey module has been designed to ease the burden on O365 administrators who are performing
a forensic analysis in their organization.

It does NOT take the place of a human reviewing the data generated and is simply here to make
data gathering easier.

## HOW TO USE:
Osprey is divided into two primary forms of cmdlets; *user* based Cmdlets and *tenant* based cmdlets.

User based cmdlets take the form Verb-OspreyUser<action>.  They all expect a -user switch and
will retrieve information specific to the user that is specified.  Tenant based cmdlets take
the form Verb-OspreyTenant<Action>.  They don't need any switches and will return information
about the whole tenant.

You must run the Start-Osprey command first, which will initialize the session and allow you to set the required parameters.
After Osprey is initialized you should run Start-OspreyTenantInvestigation which will run all the tenant based
cmdlets and provide a collection of data to start with.  Once this data has been reviewed
if there are specific user(s) that more information should be gathered on
Start-OspreyUserInvestigation will gather all the User specific information for a single user.

You can run Start-Osprey again in the same PowerShell Session and get prompted for reinitialization.
When reinitializing you can either just change the investigation parameters such as the timeframe,
or can change the actual tenant you are investigating, which is helpful for responders who may
investigate incidents for different clients.

All Osprey cmdlets include help that provides an overview of the data they gather and a listing
of all possible output files.  Run Get-Help <cmdlet> -full to see the full help output for a
given Osprey cmdlet.

Some of the Osprey cmdlets will flag results that should be further reviewed.  These will appear
in _Investigate files.  These are NOT indicative of unwanted activity but are simply things
that should reviewed.

## Disclaimer
Osprey is NOT an official MICROSOFT tool.  Therefore use of the tool is covered exclusively by the license associated with this GitHub repository.
