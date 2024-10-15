codeunit 143001 "Library - FI Localization"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

#if not CLEAN22
    [Obsolete('Moved to Automatic Account Codes app.', '22')]
    [Scope('OnPrem')]
    procedure CreateAutomaticAccountHeader(var AutomaticAccHeader: Record "Automatic Acc. Header")
    begin
        AutomaticAccHeader.Init();
        AutomaticAccHeader.Validate(
          "No.", LibraryUtility.GenerateRandomCode(AutomaticAccHeader.FieldNo("No."), DATABASE::"Automatic Acc. Header"));
        AutomaticAccHeader.Insert(true);
    end;
#endif

#if not CLEAN22
    [Obsolete('Moved to Automatic Account Codes app.', '22')]
    [Scope('OnPrem')]
    procedure CreateAutomaticAccountLine(var AutomaticAccLine: Record "Automatic Acc. Line"; AutomaticAccNo: Code[10])
    var
        RecordRef: RecordRef;
    begin
        AutomaticAccLine.Init();
        AutomaticAccLine.Validate("Automatic Acc. No.", AutomaticAccNo);
        RecordRef.GetTable(AutomaticAccLine);
        AutomaticAccLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, AutomaticAccLine.FieldNo("Line No.")));
        AutomaticAccLine.Insert(true);
    end;
#endif
}

