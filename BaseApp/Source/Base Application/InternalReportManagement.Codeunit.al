codeunit 12403 "Internal Report Management"
{
    Permissions = TableData "Invoice Post. Buffer" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There are no Posting Accounts in the Chart of Accounts.';

    [Scope('OnPrem')]
    procedure SetBeginEndDate(var BeginDate: Date; var EndDate: Date)
    var
        SaveDate: Date;
    begin
        if EndDate = 0D then
            EndDate := WorkDate;
        if BeginDate > EndDate then begin
            SaveDate := BeginDate;
            BeginDate := EndDate;
            EndDate := SaveDate;
        end;
        if BeginDate = 0D then
            BeginDate := DMY2Date(1, 1, Date2DMY(EndDate, 3));
    end;

    [Scope('OnPrem')]
    procedure CreateCrossMatrixForGLAccount(var Rec: Record "Invoice Post. Buffer"; var GLAccount1: Record "G/L Account"; var NumbLines: Integer; var NumbColumns: Integer; BeginDate: Date; EndDate: Date; SkipZeroAmount: Boolean): Boolean
    var
        GLCorresp: Record "G/L Correspondence";
    begin
        with Rec do begin
            Reset;
            DeleteAll;
            NumbColumns := 0;
            GLCorresp.SetCurrentKey("Credit Account No.", "Debit Account No.");
            GLCorresp.SetRange("Credit Account No.", GLAccount1."No.");
            if not (BeginDate = 0D) then
                if not (EndDate = 0D) then
                    GLCorresp.SetRange("Date Filter", BeginDate, EndDate)
                else
                    GLCorresp.SetRange("Date Filter", BeginDate)
            else
                if not (EndDate = 0D) then
                    GLCorresp.SetRange("Date Filter", 0D, EndDate);
            if GLAccount1.GetFilter("Source Type Filter") <> '' then
                GLCorresp.SetFilter("Credit Source Type Filter", GLAccount1.GetFilter("Source Type Filter"));
            if GLAccount1.GetFilter("Source No. Filter") <> '' then
                GLCorresp.SetFilter("Credit Source No. Filter", GLAccount1.GetFilter("Source No. Filter"));
            Type := 1;
            Init;
            if GLCorresp.Find('-') then
                repeat
                    if not (BeginDate = 0D) or not (EndDate = 0D) then begin
                        GLCorresp.CalcFields(Amount);
                        Amount := GLCorresp.Amount;
                    end;
                    if not (SkipZeroAmount and
                            (not (BeginDate = 0D) or not (EndDate = 0D)) and
                            (Amount = 0))
                    then begin
                        "G/L Account" := GLCorresp."Debit Account No.";
                        NumbColumns := NumbColumns + 1;
                        Insert;
                        Commit;
                    end;
                until GLCorresp.Next = 0;
            NumbLines := 0;
            GLCorresp.Reset;
            GLCorresp.SetCurrentKey("Debit Account No.", "Credit Account No.");
            GLCorresp.SetRange("Debit Account No.", GLAccount1."No.");
            if not (BeginDate = 0D) then
                if not (EndDate = 0D) then
                    GLCorresp.SetRange("Date Filter", BeginDate, EndDate)
                else
                    GLCorresp.SetRange("Date Filter", BeginDate)
            else
                if not (EndDate = 0D) then
                    GLCorresp.SetRange("Date Filter", 0D, EndDate);
            if GLAccount1.GetFilter("Source Type Filter") <> '' then
                GLCorresp.SetFilter("Debit Source Type Filter", GLAccount1.GetFilter("Source Type Filter"));
            if GLAccount1.GetFilter("Source No. Filter") <> '' then
                GLCorresp.SetFilter("Debit Source No. Filter", GLAccount1.GetFilter("Source No. Filter"));
            Init;
            Type := 0;
            if GLCorresp.Find('-') then
                repeat
                    if not (BeginDate = 0D) or not (EndDate = 0D) then begin
                        GLCorresp.CalcFields(Amount);
                        Amount := GLCorresp.Amount;
                    end;
                    if not (SkipZeroAmount and
                            (not (BeginDate = 0D) or not (EndDate = 0D)) and
                            (Amount = 0))
                    then begin
                        "G/L Account" := GLCorresp."Credit Account No.";
                        NumbLines := NumbLines + 1;
                        Insert;
                        Commit;
                    end;
                until GLCorresp.Next = 0;
            exit((NumbLines > 0) and (NumbColumns > 0));
        end;
    end;
}

