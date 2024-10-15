codeunit 31101 "Release VAT Control Report"
{
    TableNo = "VAT Control Report Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
    begin
        if Status = Status::Release then
            exit;

        TestField("No.");
        TestField(Year);
        TestField("Period No.");
        TestField("Start Date");
        TestField("End Date");

        VATCtrlRptLn.SetRange("Control Report No.", "No.");
        if VATCtrlRptLn.IsEmpty() then
            Error(LinesNotExistErr, "No.");
        VATCtrlRptLn.FindSet();
        repeat
            VATCtrlRptLn.TestField("VAT Control Rep. Section Code");
        until VATCtrlRptLn.Next() = 0;

        Status := Status::Release;

        Modify(true);
    end;

    var
        LinesNotExistErr: Label 'There is nothing to release for VAT Control Report No. %1.', Comment = '%1=VAT Registration No.';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Reopen(var VATCtrlRptHdr: Record "VAT Control Report Header")
    begin
        with VATCtrlRptHdr do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;
    end;
}

