report 17418 "Date Compress Payroll Ledger"
{
    Caption = 'Date Compress Payroll Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Payroll Ledger Entry" = rimd,
                  TableData "Payroll Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payroll Ledger Entry"; "Payroll Ledger Entry")
        {
            DataItemTableView = SORTING("Employee No.", "Posting Date");
            RequestFilterFields = "Employee No.", "Element Code";

            trigger OnAfterGetRecord()
            begin
                PayrollLedgEntry2 := "Payroll Ledger Entry";
                with PayrollLedgEntry2 do begin
                    SetCurrentKey("Employee No.", "Posting Date");
                    CopyFilters("Payroll Ledger Entry");
                    SetRange("Employee No.", "Employee No.");
                    SetRange("Element Code", "Element Code");

                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprJnl, true));

                    LastEntryNo := LastEntryNo + 1;

                    NewPayrollLedgEntry.Init;
                    NewPayrollLedgEntry."Entry No." := LastEntryNo;
                    NewPayrollLedgEntry."Employee No." := "Employee No.";
                    NewPayrollLedgEntry."Element Code" := "Element Code";
                    NewPayrollLedgEntry."Element Type" := "Element Type";
                    NewPayrollLedgEntry."Posting Type" := "Posting Type";
                    NewPayrollLedgEntry.Description := EntrdPayLedgEntry.Description;

                    NewPayrollLedgEntry."Posting Date" := GetRangeMin("Posting Date");
                    NewPayrollLedgEntry."Source Code" := SourceCode."Compress Payroll Journal";
                    NewPayrollLedgEntry."User ID" := UserId;
                    Window.Update(2, NewPayrollLedgEntry."Posting Date");
                    DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                    Window.Update(3, DateComprReg."No. of New Records");

                    if PayrollReg."From Entry No." = 0 then
                        PayrollReg."From Entry No." := NewPayrollLedgEntry."Entry No.";
                    PayrollReg."To Entry No." := NewPayrollLedgEntry."Entry No.";

                    if RetainNo(FieldNo("Document No.")) then begin
                        SetRange("Document No.", "Document No.");
                        NewPayrollLedgEntry."Document No." := "Document No.";
                    end;

                    ComprPayrollEntry(PayrollLedgEntry2, NewPayrollLedgEntry, DateComprReg);
                    while Next <> 0 do
                        ComprPayrollEntry(PayrollLedgEntry2, NewPayrollLedgEntry, DateComprReg);
                    NewPayrollLedgEntry.Insert;
                end;

                Window.Update(1, NewPayrollLedgEntry."Employee No.");
                Window.Update(2, NewPayrollLedgEntry."Posting Date");
                DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                Window.Update(3, DateComprReg."No. of New Records");

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(PayrollReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" <> 0 then
                    InsertRegisters(PayrollReg, DateComprReg);
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(Text000, false) then
                    CurrReport.Break;

                if EntrdDateComprJnl."Ending Date" = 0D then
                    Error(EntrdDateComprJnl.FieldName("Ending Date") + Text003);

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                NewPayrollLedgEntry.LockTable;
                PayrollReg.LockTable;
                DateComprReg.LockTable;

                SourceCode.Get;
                SourceCode.TestField("Compress Payroll Journal");

                if PayrollReg.FindLast then;
                PayrollReg.Init;
                PayrollReg."No." := PayrollReg."No." + 1;
                PayrollReg."Creation Date" := Today;
                PayrollReg."Source Code" := SourceCode."Compress Payroll Journal";
                PayrollReg."User ID" := UserId;

                if DateComprReg.FindLast then;
                DateComprReg.Init;
                DateComprReg."No." := DateComprReg."No." + 1;
                DateComprReg."Table ID" := DATABASE::"Payroll Ledger Entry";
                DateComprReg."Creation Date" := Today;
                DateComprReg."Starting Date" := EntrdDateComprJnl."Starting Date";
                DateComprReg."Ending Date" := EntrdDateComprJnl."Ending Date";
                DateComprReg."Period Length" := EntrdDateComprJnl."Period Length";
                for i := 1 to NoOfFields do
                    if Retain[i] then
                        DateComprReg."Retain Field Contents" :=
                          CopyStr(
                            DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                            MaxStrLen(DateComprReg."Retain Field Contents"));
                DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);
                DateComprReg.Filter := PayrollLedgEntryFilter;
                DateComprReg."Register No." := PayrollReg."No.";
                DateComprReg."Source Code" := SourceCode."Compress Payroll Journal";
                DateComprReg."User ID" := UserId;

                if PayrollLedgEntry2.Find('+') then;
                LastEntryNo := PayrollLedgEntry2."Entry No.";
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprJnl."Starting Date", EntrdDateComprJnl."Ending Date");
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
                    field("EntrdDateComprJnl.""Starting Date"""; EntrdDateComprJnl."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field("EntrdDateComprJnl.""Ending Date"""; EntrdDateComprJnl."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("EntrdDateComprJnl.""Period Length"""; EntrdDateComprJnl."Period Length")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Period';
                    }
                    field("EntrdPayLedgEntry.Description"; EntrdPayLedgEntry.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the description that will be added to the resulting posting.';
                    }
                    field("Retain[1]"; Retain[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field("Retain[2]"; Retain[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Resource No.';
                    }
                    field("Retain[3]"; Retain[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Job No.';
                    }
                    field("Retain[4]"; Retain[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Department Code';
                    }
                    field("Retain[5]"; Retain[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Code';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if EntrdDateComprJnl."Ending Date" = 0D then
                EntrdDateComprJnl."Ending Date" := Today;

            if EntrdPayLedgEntry.Description = '' then
                EntrdPayLedgEntry.Description := 'Date Compressed';

            with "Payroll Ledger Entry" do
                InsertField(FieldNo("Document No."), FieldName("Document No."));
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PayrollLedgEntryFilter := CopyStr("Payroll Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        SourceCode: Record "Source Code Setup";
        EntrdDateComprJnl: Record "Date Compr. Register";
        DateComprReg: Record "Date Compr. Register";
        PayrollReg: Record "Payroll Register";
        EntrdPayLedgEntry: Record "Payroll Ledger Entry";
        NewPayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollLedgEntry2: Record "Payroll Ledger Entry";
        DateComprMgt: Codeunit DateComprMgt;
        Window: Dialog;
        PayrollLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[20] of Boolean;
        FieldNo: array[20] of Integer;
        FieldNameArray: array[20] of Text[30];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        PayJournalxists: Boolean;
        i: Integer;
        Text000: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing payroll ledger entries...\\';
        Text005: Label 'Employee No.               #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';

    [Scope('OnPrem')]
    procedure ComprPayrollEntry(PayrollLedgEntry: Record "Payroll Ledger Entry"; var NewPayrollLedgEntry: Record "Payroll Ledger Entry"; var DateComprReg: Record "Date Compr. Register")
    begin
        with PayrollLedgEntry do begin
            NewPayrollLedgEntry."Payroll Amount" := NewPayrollLedgEntry."Payroll Amount" + "Payroll Amount";
            NewPayrollLedgEntry."Taxable Amount" := NewPayrollLedgEntry."Taxable Amount" + "Taxable Amount";
            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertRegisters(PayrollReg: Record "Payroll Register"; DateComprReg: Record "Date Compr. Register")
    begin
        if PayJournalxists then begin
            PayrollReg.Modify;
            DateComprReg.Modify;
        end else begin
            PayrollReg.Insert;
            DateComprReg.Insert;
            PayJournalxists := true;
        end;
        Commit;
        NewPayrollLedgEntry.LockTable;
        PayrollReg.LockTable;
        DateComprReg.LockTable;
    end;

    [Scope('OnPrem')]
    procedure InsertField(Number: Integer; Name: Text[30])
    begin
        NoOfFields := NoOfFields + 1;
        FieldNo[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := Name;
    end;

    [Scope('OnPrem')]
    procedure RetainNo(Number: Integer): Boolean
    begin
        exit(Retain[Index(Number)]);
    end;

    [Scope('OnPrem')]
    procedure Index(Number: Integer): Integer
    begin
        for i := 1 to NoOfFields do
            if Number = FieldNo[i] then
                exit(i);
    end;
}

