report 198 "Date Compress Customer Ledger"
{
    Caption = 'Date Compress Customer Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Reminder/Fin. Charge Entry" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING("Customer No.", "Posting Date") WHERE(Open = CONST(false));
            RequestFilterFields = "Customer No.", "Customer Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                if not CompressDetails("Cust. Ledger Entry") then
                    CurrReport.Skip();
                ReminderEntry.SetCurrentKey("Customer Entry No.");
                CustLedgEntry2 := "Cust. Ledger Entry";
                with CustLedgEntry2 do begin
                    SetCurrentKey("Customer No.", "Posting Date");
                    CopyFilters("Cust. Ledger Entry");
                    SetRange("Customer No.", "Customer No.");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    SetRange("Customer Posting Group", "Customer Posting Group");
                    SetRange("Currency Code", "Currency Code");
                    SetRange("Document Type", "Document Type");

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Sell-to Customer No.")) then
                        SetRange("Sell-to Customer No.", "Sell-to Customer No.");
                    if RetainNo(FieldNo("Salesperson Code")) then
                        SetRange("Salesperson Code", "Salesperson Code");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                    CalcFields(Amount);
                    if Amount >= 0 then
                        SummarizePositive := true
                    else
                        SummarizePositive := false;

                    InitNewEntry(NewCustLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewCustLedgEntry, CustLedgEntry2);

                    while Next <> 0 do begin
                        CalcFields(Amount);
                        if ((Amount >= 0) and SummarizePositive) or
                           ((Amount < 0) and (not SummarizePositive))
                        then
                            if CompressDetails(CustLedgEntry2) then begin
                                DimBufMgt.CollectDimEntryNo(
                                  TempSelectedDim, "Dimension Set ID", "Entry No.",
                                  ComprDimEntryNo, true, DimEntryNo);
                                if DimEntryNo = ComprDimEntryNo then
                                    SummarizeEntry(NewCustLedgEntry, CustLedgEntry2);
                            end;
                    end;

                    InsertNewEntry(NewCustLedgEntry, ComprDimEntryNo);

                    ComprCollectedEntries;
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(GLReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(GLReg, DateComprReg);
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                ConfirmManagement: Codeunit "Confirm Management";
                LastTransactionNo: Integer;
            begin
                if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                    CurrReport.Break();

                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Cust. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Customer Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Customer Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Customer Ledger", '', GLSetup."Global Dimension 2 Code");

                GLEntry.LockTable();
                ReminderEntry.LockTable();
                NewDtldCustLedgEntry.LockTable();
                NewCustLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastDtldEntryNo := NewDtldCustLedgEntry.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters;
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
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("EntrdCustLedgEntry.Description"; EntrdCustLedgEntry.Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Sell-to Customer No.';
                            ToolTip = 'Specifies the customer for whom ledger entries are date compressed.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Salesperson Code';
                            ToolTip = 'Specifies the salesperson for whom customer ledger entries are date compressed';
                        }
                    }
                    field(RetainDimText; RetainDimText)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies which dimension information you want to retain when the entries are compressed. The more dimension information that you choose to retain, the more detailed the compressed entries are.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Customer Ledger", RetainDimText);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitializeParameter;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Date Compress Customer Ledger", '', RetainDimText, Text010);
        CustLedgEntryFilter := CopyStr("Cust. Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        Text000: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing customer ledger entries...\\';
        Text005: Label 'Customer No.         #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        GLReg: Record "G/L Register";
        EntrdCustLedgEntry: Record "Cust. Ledger Entry";
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntryBuffer: Record "Detailed Cust. Ledg. Entry" temporary;
        GLEntry: Record "G/L Entry";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        CustLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        LastDtldEntryNo: Integer;
        LastTmpDtldEntryNo: Integer;
        GLRegExists: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        SummarizePositive: Boolean;

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress Cust. Ledger", '', '');
        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Cust. Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          CustLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Cust. Ledger");
        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var GLReg: Record "G/L Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FoundLastEntryNo: Integer;
        FoundLastLedgEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLEntry."Entry No." := LastEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry.Description := EntrdCustLedgEntry.Description;
        GLEntry."Source Code" := SourceCodeSetup."Compress Cust. Ledger";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := UserId;
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := LastEntryNo;

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        GLEntry.LockTable();
        ReminderEntry.LockTable();
        NewDtldCustLedgEntry.LockTable();
        NewCustLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastLedgEntryNo := NewCustLedgEntry.GetLastEntryNo();
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> FoundLastLedgEntryNo + 1)
        then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters;
        end;
        LastDtldEntryNo := NewDtldCustLedgEntry.GetLastEntryNo();
    end;

    local procedure InsertField(Number: Integer; Name: Text[100])
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := Name;
    end;

    local procedure RetainNo(Number: Integer): Boolean
    begin
        exit(Retain[Index(Number)]);
    end;

    local procedure Index(Number: Integer): Integer
    begin
        for i := 1 to NoOfFields do
            if Number = FieldNumber[i] then
                exit(i);
    end;

    local procedure SummarizeEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with CustLedgEntry do begin
            NewCustLedgEntry."Sales (LCY)" := NewCustLedgEntry."Sales (LCY)" + "Sales (LCY)";
            NewCustLedgEntry."Profit (LCY)" := NewCustLedgEntry."Profit (LCY)" + "Profit (LCY)";
            NewCustLedgEntry."Inv. Discount (LCY)" := NewCustLedgEntry."Inv. Discount (LCY)" + "Inv. Discount (LCY)";
            NewCustLedgEntry."Original Pmt. Disc. Possible" :=
              NewCustLedgEntry."Original Pmt. Disc. Possible" + "Original Pmt. Disc. Possible";
            NewCustLedgEntry."Remaining Pmt. Disc. Possible" :=
              NewCustLedgEntry."Remaining Pmt. Disc. Possible" + "Remaining Pmt. Disc. Possible";
            NewCustLedgEntry."Closed by Amount (LCY)" :=
              NewCustLedgEntry."Closed by Amount (LCY)" + "Closed by Amount (LCY)";

            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Entry No.");
            if DtldCustLedgEntry.Find('-') then begin
                repeat
                    SummarizeDtldEntry(DtldCustLedgEntry, NewCustLedgEntry);
                until DtldCustLedgEntry.Next = 0;
                DtldCustLedgEntry.DeleteAll();
            end;

            ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
            ReminderEntry.DeleteAll();
            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    local procedure ComprCollectedEntries()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        CustLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, CustLedgEntryNo) then begin
            InitNewEntry(NewCustLedgEntry);
            repeat
                CustLedgEntry.Get(CustLedgEntryNo);
                SummarizeEntry(NewCustLedgEntry, CustLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, CustLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewCustLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewCustLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with CustLedgEntry2 do begin
            NewCustLedgEntry.Init();
            NewCustLedgEntry."Entry No." := LastEntryNo;
            NewCustLedgEntry."Customer No." := "Customer No.";
            NewCustLedgEntry."Posting Date" := GetRangeMin("Posting Date");
            NewCustLedgEntry.Description := EntrdCustLedgEntry.Description;
            NewCustLedgEntry."Customer Posting Group" := "Customer Posting Group";
            NewCustLedgEntry."Currency Code" := "Currency Code";
            NewCustLedgEntry."Document Type" := "Document Type";
            NewCustLedgEntry."Source Code" := SourceCodeSetup."Compress Cust. Ledger";
            NewCustLedgEntry."User ID" := UserId;
            NewCustLedgEntry."Transaction No." := NextTransactionNo;

            if RetainNo(FieldNo("Document No.")) then
                NewCustLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Sell-to Customer No.")) then
                NewCustLedgEntry."Sell-to Customer No." := "Sell-to Customer No.";
            if RetainNo(FieldNo("Salesperson Code")) then
                NewCustLedgEntry."Salesperson Code" := "Salesperson Code";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewCustLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewCustLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewCustLedgEntry."Customer No.");
            Window.Update(2, NewCustLedgEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewCustLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewCustLedgEntry.Insert();
        InsertDtldEntries;
    end;

    local procedure CompressDetails(CustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        if EntrdDateComprReg."Starting Date" <> 0D then begin
            DtldCustLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '..%1|%2..',
                CalcDate('<-1D>', EntrdDateComprReg."Starting Date"),
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")));
        end else
            DtldCustLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '%1..',
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")));

        exit(DtldCustLedgEntry.IsEmpty());
    end;

    local procedure SummarizeDtldEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NewCustLedgEntry: Record "Cust. Ledger Entry")
    var
        NewEntry: Boolean;
        PostingDate: Date;
    begin
        DtldCustLedgEntryBuffer.SetFilter(
          "Posting Date",
          DateComprMgt.GetDateFilter(DtldCustLedgEntry."Posting Date", EntrdDateComprReg, true));
        PostingDate := DtldCustLedgEntryBuffer.GetRangeMin("Posting Date");
        DtldCustLedgEntryBuffer.SetRange("Posting Date", PostingDate);
        DtldCustLedgEntryBuffer.SetRange("Entry Type", DtldCustLedgEntry."Entry Type");
        if RetainNo("Cust. Ledger Entry".FieldNo("Document No.")) then
            DtldCustLedgEntryBuffer.SetRange("Document No.", "Cust. Ledger Entry"."Document No.");
        if RetainNo("Cust. Ledger Entry".FieldNo("Sell-to Customer No.")) then
            DtldCustLedgEntryBuffer.SetRange("Customer No.", "Cust. Ledger Entry"."Sell-to Customer No.");
        if RetainNo("Cust. Ledger Entry".FieldNo("Global Dimension 1 Code")) then
            DtldCustLedgEntryBuffer.SetRange("Initial Entry Global Dim. 1", "Cust. Ledger Entry"."Global Dimension 1 Code");
        if RetainNo("Cust. Ledger Entry".FieldNo("Global Dimension 2 Code")) then
            DtldCustLedgEntryBuffer.SetRange("Initial Entry Global Dim. 2", "Cust. Ledger Entry"."Global Dimension 2 Code");

        if not DtldCustLedgEntryBuffer.Find('-') then begin
            DtldCustLedgEntryBuffer.Reset();
            Clear(DtldCustLedgEntryBuffer);

            LastTmpDtldEntryNo := LastTmpDtldEntryNo + 1;
            DtldCustLedgEntryBuffer."Entry No." := LastTmpDtldEntryNo;
            DtldCustLedgEntryBuffer."Posting Date" := PostingDate;
            DtldCustLedgEntryBuffer."Document Type" := NewCustLedgEntry."Document Type";
            DtldCustLedgEntryBuffer."Initial Document Type" := NewCustLedgEntry."Document Type";
            DtldCustLedgEntryBuffer."Document No." := NewCustLedgEntry."Document No.";
            DtldCustLedgEntryBuffer."Entry Type" := DtldCustLedgEntry."Entry Type";
            DtldCustLedgEntryBuffer."Cust. Ledger Entry No." := NewCustLedgEntry."Entry No.";
            DtldCustLedgEntryBuffer."Customer No." := NewCustLedgEntry."Customer No.";
            DtldCustLedgEntryBuffer."Currency Code" := NewCustLedgEntry."Currency Code";
            DtldCustLedgEntryBuffer."User ID" := NewCustLedgEntry."User ID";
            DtldCustLedgEntryBuffer."Source Code" := NewCustLedgEntry."Source Code";
            DtldCustLedgEntryBuffer."Transaction No." := NewCustLedgEntry."Transaction No.";
            DtldCustLedgEntryBuffer."Journal Batch Name" := NewCustLedgEntry."Journal Batch Name";
            DtldCustLedgEntryBuffer."Reason Code" := NewCustLedgEntry."Reason Code";
            DtldCustLedgEntryBuffer."Initial Entry Due Date" := NewCustLedgEntry."Due Date";
            DtldCustLedgEntryBuffer."Initial Entry Global Dim. 1" := NewCustLedgEntry."Global Dimension 1 Code";
            DtldCustLedgEntryBuffer."Initial Entry Global Dim. 2" := NewCustLedgEntry."Global Dimension 2 Code";

            NewEntry := true;
        end;

        DtldCustLedgEntryBuffer.Amount :=
          DtldCustLedgEntryBuffer.Amount + DtldCustLedgEntry.Amount;
        DtldCustLedgEntryBuffer."Amount (LCY)" :=
          DtldCustLedgEntryBuffer."Amount (LCY)" + DtldCustLedgEntry."Amount (LCY)";
        DtldCustLedgEntryBuffer."Debit Amount" :=
          DtldCustLedgEntryBuffer."Debit Amount" + DtldCustLedgEntry."Debit Amount";
        DtldCustLedgEntryBuffer."Credit Amount" :=
          DtldCustLedgEntryBuffer."Credit Amount" + DtldCustLedgEntry."Credit Amount";
        DtldCustLedgEntryBuffer."Debit Amount (LCY)" :=
          DtldCustLedgEntryBuffer."Debit Amount (LCY)" + DtldCustLedgEntry."Debit Amount (LCY)";
        DtldCustLedgEntryBuffer."Credit Amount (LCY)" :=
          DtldCustLedgEntryBuffer."Credit Amount (LCY)" + DtldCustLedgEntry."Credit Amount (LCY)";

        if NewEntry then
            DtldCustLedgEntryBuffer.Insert
        else
            DtldCustLedgEntryBuffer.Modify();
    end;

    local procedure InsertDtldEntries()
    begin
        DtldCustLedgEntryBuffer.Reset();
        if DtldCustLedgEntryBuffer.Find('-') then
            repeat
                if ((DtldCustLedgEntryBuffer.Amount <> 0) or
                    (DtldCustLedgEntryBuffer."Amount (LCY)" <> 0) or
                    (DtldCustLedgEntryBuffer."Debit Amount" <> 0) or
                    (DtldCustLedgEntryBuffer."Credit Amount" <> 0) or
                    (DtldCustLedgEntryBuffer."Debit Amount (LCY)" <> 0) or
                    (DtldCustLedgEntryBuffer."Credit Amount (LCY)" <> 0))
                then begin
                    LastDtldEntryNo := LastDtldEntryNo + 1;

                    NewDtldCustLedgEntry := DtldCustLedgEntryBuffer;
                    NewDtldCustLedgEntry."Entry No." := LastDtldEntryNo;
                    NewDtldCustLedgEntry.Insert(true);
                end;
            until DtldCustLedgEntryBuffer.Next = 0;
        DtldCustLedgEntryBuffer.DeleteAll();
    end;

    local procedure InitializeParameter()
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := Today;
        if EntrdCustLedgEntry.Description = '' then
            EntrdCustLedgEntry.Description := Text009;

        with "Cust. Ledger Entry" do begin
            InsertField(FieldNo("Document No."), FieldCaption("Document No."));
            InsertField(FieldNo("Sell-to Customer No."), FieldCaption("Sell-to Customer No."));
            InsertField(FieldNo("Salesperson Code"), FieldCaption("Salesperson Code"));
            InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
            InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
        end;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Customer Ledger", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[50]; RetainDocumentNo: Boolean; RetainSelltoCustomerNo: Boolean; RetainSalespersonCode: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeParameter;
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdCustLedgEntry.Description := Description;
        Retain[1] := RetainDocumentNo;
        Retain[2] := RetainSelltoCustomerNo;
        Retain[3] := RetainSalespersonCode;
        RetainDimText := RetainDimensionText;
    end;
}

