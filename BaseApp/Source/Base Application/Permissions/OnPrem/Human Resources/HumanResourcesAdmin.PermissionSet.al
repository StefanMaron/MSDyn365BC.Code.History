permissionset 4592 "Human Resources - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Human Resources setup';

    Permissions = tabledata "Cause of Inactivity" = RIMD,
                  tabledata "Classificator OKIN" = RIMD,
                  tabledata Confidential = RIMD,
                  tabledata "Default Labor Contract Terms" = RIMD,
                  tabledata Employee = R,
                  tabledata "Employee Absence" = R,
                  tabledata "Employee Journal Batch" = RIMD,
                  tabledata "Employee Journal Template" = RIMD,
                  tabledata "Employee Qualification" = R,
                  tabledata "Employee Statistics Group" = RIMD,
                  tabledata "Employment Contract" = RIMD,
                  tabledata "General Directory" = RIMD,
                  tabledata "Grounds for Termination" = RIMD,
                  tabledata "HR Field Group" = RIMD,
                  tabledata "HR Field Group Line" = RIMD,
                  tabledata "Human Resources Setup" = RIMD,
                  tabledata "Job Title" = RIMD,
                  tabledata "KLADR Address" = RIMD,
                  tabledata "KLADR Category" = RIMD,
                  tabledata "KLADR Region" = RIMD,
                  tabledata "Labor Contract Terms Setup" = RIMD,
                  tabledata "Misc. Article" = RIMD,
                  tabledata "Misc. Article Information" = R,
                  tabledata "Organizational Unit" = RIMD,
                  tabledata Position = RIMD,
                  tabledata "Position View Buffer" = RIMD,
                  tabledata Qualification = RIMD,
                  tabledata Relative = RIMD,
                  tabledata "Staff List" = Rimd,
                  tabledata "Time Activity" = RIMD,
                  tabledata Union = RIMD,
                  tabledata "Unit of Measure" = RIMD;
}
