namespace Microsoft.CRM.Interaction;

enum 5076 "Correspondence Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Hard Copy")
    {
        Caption = 'Hard Copy';
    }
    value(2; Email)
    {
        Caption = 'Email';
    }
#if not CLEAN23
    value(3; Fax)
    {
        ObsoleteReason = 'Not supported since moving to WebClient.';
        ObsoleteState = Pending;
        ObsoleteTag = '23.0';
        Caption = 'Fax';
    }
#endif
}