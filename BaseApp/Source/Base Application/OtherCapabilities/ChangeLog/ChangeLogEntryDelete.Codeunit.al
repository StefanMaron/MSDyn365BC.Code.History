# if not CLEAN22
codeunit 510 "Change Log Entry - Delete"
{
    Permissions = TableData "Change Log Entry" = rd;
    TableNo = "Change Log Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality has been replaced with the retention policy module in system application.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        Rec.SetRange("Field Log Entry Feature", "Field Log Entry Feature"::"Change Log");
        Rec.SetRange(Protected, true);
        Rec.Delete(); // do not call trigger as that will fail for protected entries
    end;
}
#endif
