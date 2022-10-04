report 1495 "Delete Check Ledger Entries"
{
    Caption = 'Delete Check Ledger Entries';
    Permissions = TableData "Check Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Check Ledger Entry"; "Check Ledger Entry")
        {
            DataItemTableView = SORTING("Bank Account No.", "Check Date") WHERE("Entry Status" = FILTER(<> Printed));
            RequestFilterFields = "Bank Account No.", "Bank Payment Type";

            trigger OnAfterGetRecord()
            begin
                CheckLedgEntry2 := "Check Ledger Entry";
                with CheckLedgEntry2 do begin
                    SetCurrentKey("Bank Account No.", "Check Date");
                    CopyFilters("Check Ledger Entry");

                    Window.Update(1, "Bank Account No.");

                    repeat
                        Delete();
                        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
                        Window.Update(4, DateComprReg."No. Records Deleted");
                    until Next() = 0;
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(DateComprReg);
            end;

            trigger OnPreDataItem()
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(Text004);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Check Ledger");

                CheckLedgEntry2.LockTable();
                if CheckLedgEntry3.FindLast() then;
                DateComprReg.LockTable();

                SetRange("Check Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                DateComprMgt.GetDateFilter(EntrdDateComprReg."Ending Date", EntrdDateComprReg, true);

                InitRegister();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("EntrdDateComprReg.""Starting Date"""; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date of the period from which the check ledger entries are suggested. The batch job includes all entries from this date to the ending date.';
                    }
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date of the period from which the check ledger entries are suggested. The batch job includes all entries from the starting date to this date.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = Action::Cancel then
                exit;
            if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                CurrReport.Break();
        end;

        trigger OnOpenPage()
        var
            DateCompression: Codeunit "Date Compression";
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        CheckLedgEntryFilter := CopyStr("Check Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        CheckLedgEntry2: Record "Check Ledger Entry";
        CheckLedgEntry3: Record "Check Ledger Entry";
        DateComprMgt: Codeunit DateComprMgt;
        Window: Dialog;
        CheckLedgEntryFilter: Text[250];
        NoOfDeleted: Integer;
        RegExists: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing check ledger entries...\\Bank Account No.       #1##########\No. of entries deleted #4######';
        Text007: Label 'All records deleted';

    local procedure InitRegister()
    var
        NextRegNo: Integer;
    begin
        if DateComprReg.FindLast() then
            NextRegNo := DateComprReg."No." + 1;

        DateComprReg.InitRegister(
          DATABASE::"Check Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          CheckLedgEntryFilter, 0, SourceCodeSetup."Compress Check Ledger");

        DateComprReg."Retain Field Contents" := Text007;

        RegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(DateComprReg: Record "Date Compr. Register")
    begin
        if RegExists then
            DateComprReg.Modify()
        else begin
            DateComprReg.Insert();
            RegExists := true;
        end;
        Commit();

        CheckLedgEntry2.LockTable();
        if CheckLedgEntry3.FindLast() then;
        DateComprReg.LockTable();

        InitRegister();
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date)
    begin
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
    end;
}

