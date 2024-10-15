namespace Microsoft.CRM.Setup;

enum 5069 "Salutation Formula Name"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Job Title")
    {
        Caption = 'Job Title';
    }
    value(2; "First Name")
    {
        Caption = 'First Name';
    }
    value(3; "Middle Name")
    {
        Caption = 'Middle Name';
    }
    value(4; Surname)
    {
        Caption = 'Surname';
    }
    value(5; Initials)
    {
        Caption = 'Initials';
    }
    value(6; "Company Name")
    {
        Caption = 'Company Name';
    }
}