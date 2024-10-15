#if not CLEAN22
profile "M365 Collaboration"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'New EMPLOYEE profile has been created and it should be used instead.';
    ObsoleteTag = '22.0';
    Caption = 'M365 Collaboration';
    ProfileDescription = 'Gives people who have a license for Teams read-only access to data in Business Central.';
    RoleCenter = "Blank Role Center";
    Enabled = false;
}
#endif