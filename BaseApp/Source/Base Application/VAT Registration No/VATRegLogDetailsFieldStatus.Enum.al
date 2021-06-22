enum 244 "VAT Reg. Log Details Field Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Valid")
    {
        Caption = 'Not Valid';
    }
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    value(2; Applied)
    {
        Caption = 'Applied';
    }
    value(3; Valid)
    {
        Caption = 'Valid';
    }
}