#if not CLEAN17
codeunit 31060 "Release VIES Declaration"
{
    TableNo = "VIES Declaration Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        VIESDeclarationLine: Record "VIES Declaration Line";
    begin
        if Status = Status::Released then
            exit;

        StatReportingSetup.Get();
        StatReportingSetup.TestField("VIES Number of Lines");

        TestField("VAT Registration No.");
        TestField("Document Date");

        TestField(Year);
        TestField("Period No.");

        if "Declaration Type" <> "Declaration Type"::Normal then
            TestField("Corrected Declaration No.");

        VIESDeclarationLine.SetRange("VIES Declaration No.", "No.");
        if VIESDeclarationLine.IsEmpty() then
            Error(Text001Err, "No.");
        VIESDeclarationLine.FindSet();
        PageNo := 1;
        LineNo := 0;
        repeat
            VIESDeclarationLine.TestField("Country/Region Code");
            VIESDeclarationLine.TestField("VAT Registration No.");
            if "Declaration Type" <> "Declaration Type"::Normal then
                VIESDeclarationLine.TestField("Amount (LCY)");
            LineNo += 1;
            if LineNo = StatReportingSetup."VIES Number of Lines" + 1 then begin
                LineNo := 1;
                PageNo += 1;
            end;
            VIESDeclarationLine."Report Page Number" := PageNo;
            VIESDeclarationLine."Report Line Number" := LineNo;
            VIESDeclarationLine.Modify();
        until VIESDeclarationLine.Next() = 0;

        Status := Status::Released;

        Modify(true);
    end;

    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        PageNo: Integer;
        LineNo: Integer;
        Text001Err: Label 'There is nothing to release for declaration No. %1.';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Reopen(var VIESDeclarationHeader: Record "VIES Declaration Header")
    begin
        with VIESDeclarationHeader do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;
    end;
}


#endif