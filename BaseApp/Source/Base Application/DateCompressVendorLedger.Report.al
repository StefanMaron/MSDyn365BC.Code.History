report 398 "Date Compress Vendor Ledger"
{
    ApplicationArea = Suite;
    Caption = 'Date Compress Vendor Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = SORTING("Vendor No.", "Posting Date") WHERE(Open = CONST(false));
            RequestFilterFields = "Vendor No.", "Vendor Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                VendLedgEntry2 := "Vendor Ledger Entry";
                with VendLedgEntry2 do begin
                    if not CompressDetails("Vendor Ledger Entry") then
                        CurrReport.Skip();
                    SetCurrentKey("Vendor No.", "Posting Date");
                    CopyFilters("Vendor Ledger Entry");
                    SetRange("Vendor No.", "Vendor No.");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    SetRange("Vendor Posting Group", "Vendor Posting Group");
                    SetRange("Currency Code", "Currency Code");
                    SetRange("Document Type", "Document Type");

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Buy-from Vendor No.")) then
                        SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                    if RetainNo(FieldNo("Purchaser Code")) then
                        SetRange("Purchaser Code", "Purchaser Code");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");

                    CalcFields(Amount);
                    if Amount >= 0 then
                        SummarizePositive := true
                    else
                        SummarizePositive := false;

                    InitNewEntry(NewVendLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewVendLedgEntry, VendLedgEntry2);
                    while Next <> 0 do begin
                        CalcFields(Amount);
                        if ((Amount >= 0) and SummarizePositive) or
                           ((Amount < 0) and (not SummarizePositive))
                        then
                            if CompressDetails(VendLedgEntry2) then begin
                                DimBufMgt.CollectDimEntryNo(
                                  TempSelectedDim, "Dimension Set ID", "Entry No.",
                                  ComprDimEntryNo, true, DimEntryNo);
                                if DimEntryNo = ComprDimEntryNo then
                                    SummarizeEntry(NewVendLedgEntry, VendLedgEntry2);
                            end;
                    end;

                    InsertNewEntry(NewVendLedgEntry, ComprDimEntryNo);

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
                SourceCodeSetup.TestField("Compress Vend. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Vendor Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Vendor Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Vendor Ledger", '', GLSetup."Global Dimension 2 Code");

                GLentry.LockTable();
                NewDtldVendLedgEntry.LockTable();
                NewVendLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLentry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastDtldEntryNo := NewDtldVendLedgEntry.GetLastEntryNo();
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
                    field("EntrdVendLedgEntry.Description"; EntrdVendLedgEntry.Description)
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
                            Caption = 'Buy-from Vendor No.';
                            ToolTip = 'Specifies a filter for the vendor or vendors that you want to compress entries for.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Purchaser Code';
                            ToolTip = 'Specifies the purchaser for whom vendor ledger entries are date compressed';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Vendor Ledger", RetainDimText);
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
          3, REPORT::"Date Compress Vendor Ledger", '', RetainDimText, Text010);
        VendLedgEntryFilter := CopyStr("Vendor Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        Text000: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing vendor ledger entries...\\';
        Text005: Label 'Vendor No.           #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        GLReg: Record "G/L Register";
        EntrdVendLedgEntry: Record "Vendor Ledger Entry";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntryBuffer: Record "Detailed Vendor Ledg. Entry" temporary;
        GLentry: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        VendLedgEntryFilter: Text[250];
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
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress Vend. Ledger", '', '');
        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Vendor Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          VendLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Vend. Ledger");

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
        GLentry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLentry."Entry No." := LastEntryNo;
        GLentry."Posting Date" := Today;
        GLentry.Description := EntrdVendLedgEntry.Description;
        GLentry."Source Code" := SourceCodeSetup."Compress Vend. Ledger";
        GLentry."System-Created Entry" := true;
        GLentry."User ID" := UserId;
        GLentry."Transaction No." := NextTransactionNo;
        GLentry.Insert();
        GLentry.Consistent(GLentry.Amount = 0);
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

        GLentry.LockTable();
        NewDtldVendLedgEntry.LockTable();
        NewVendLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLentry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastLedgEntryNo := NewVendLedgEntry.GetLastEntryNo();
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> FoundLastLedgEntryNo + 1)
        then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters;
        end;
        LastDtldEntryNo := NewDtldVendLedgEntry.GetLastEntryNo();
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

    local procedure SummarizeEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with VendLedgEntry do begin
            NewVendLedgEntry."Purchase (LCY)" := NewVendLedgEntry."Purchase (LCY)" + "Purchase (LCY)";
            NewVendLedgEntry."Inv. Discount (LCY)" := NewVendLedgEntry."Inv. Discount (LCY)" + "Inv. Discount (LCY)";
            NewVendLedgEntry."Original Pmt. Disc. Possible" :=
              NewVendLedgEntry."Original Pmt. Disc. Possible" + "Original Pmt. Disc. Possible";
            NewVendLedgEntry."Remaining Pmt. Disc. Possible" :=
              NewVendLedgEntry."Remaining Pmt. Disc. Possible" + "Remaining Pmt. Disc. Possible";
            NewVendLedgEntry."Closed by Amount (LCY)" :=
              NewVendLedgEntry."Closed by Amount (LCY)" + "Closed by Amount (LCY)";

            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");
            if DtldVendLedgEntry.Find('-') then begin
                repeat
                    SummarizeDtldEntry(DtldVendLedgEntry, NewVendLedgEntry);
                until DtldVendLedgEntry.Next = 0;
                DtldVendLedgEntry.DeleteAll();
            end;

            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    local procedure ComprCollectedEntries()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        VendLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, VendLedgEntryNo) then begin
            InitNewEntry(NewVendLedgEntry);
            repeat
                VendLedgEntry.Get(VendLedgEntryNo);
                SummarizeEntry(NewVendLedgEntry, VendLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, VendLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewVendLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewVendLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with VendLedgEntry2 do begin
            NewVendLedgEntry.Init();
            NewVendLedgEntry."Entry No." := LastEntryNo;
            NewVendLedgEntry."Vendor No." := "Vendor No.";
            NewVendLedgEntry."Posting Date" := GetRangeMin("Posting Date");
            NewVendLedgEntry.Description := EntrdVendLedgEntry.Description;
            NewVendLedgEntry."Vendor Posting Group" := "Vendor Posting Group";
            NewVendLedgEntry."Currency Code" := "Currency Code";
            NewVendLedgEntry."Document Type" := "Document Type";
            NewVendLedgEntry."Source Code" := SourceCodeSetup."Compress Vend. Ledger";
            NewVendLedgEntry."User ID" := UserId;
            NewVendLedgEntry."Transaction No." := NextTransactionNo;

            if RetainNo(FieldNo("Document No.")) then
                NewVendLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Buy-from Vendor No.")) then
                NewVendLedgEntry."Buy-from Vendor No." := "Buy-from Vendor No.";
            if RetainNo(FieldNo("Purchaser Code")) then
                NewVendLedgEntry."Purchaser Code" := "Purchaser Code";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewVendLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewVendLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewVendLedgEntry."Vendor No.");
            Window.Update(2, NewVendLedgEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewVendLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewVendLedgEntry.Insert();
        InsertDtldEntries;
    end;

    local procedure CompressDetails(VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Posting Date");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        if EntrdDateComprReg."Starting Date" <> 0D then
            DtldVendLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '..%1|%2..',
                CalcDate('<-1D>', EntrdDateComprReg."Starting Date"),
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")))
        else
            DtldVendLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '%1..',
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")));

        exit(DtldVendLedgEntry.IsEmpty());
    end;

    local procedure SummarizeDtldEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var NewVendLedgEntry: Record "Vendor Ledger Entry")
    var
        NewEntry: Boolean;
        PostingDate: Date;
    begin
        DtldVendLedgEntryBuffer.SetFilter(
          "Posting Date",
          DateComprMgt.GetDateFilter(DtldVendLedgEntry."Posting Date", EntrdDateComprReg, true));
        PostingDate := DtldVendLedgEntryBuffer.GetRangeMin("Posting Date");
        DtldVendLedgEntryBuffer.SetRange("Posting Date", PostingDate);
        DtldVendLedgEntryBuffer.SetRange("Entry Type", DtldVendLedgEntry."Entry Type");
        if RetainNo("Vendor Ledger Entry".FieldNo("Document No.")) then
            DtldVendLedgEntryBuffer.SetRange("Document No.", "Vendor Ledger Entry"."Document No.");
        if RetainNo("Vendor Ledger Entry".FieldNo("Buy-from Vendor No.")) then
            DtldVendLedgEntryBuffer.SetRange("Vendor No.", "Vendor Ledger Entry"."Buy-from Vendor No.");
        if RetainNo("Vendor Ledger Entry".FieldNo("Global Dimension 1 Code")) then
            DtldVendLedgEntryBuffer.SetRange("Initial Entry Global Dim. 1", "Vendor Ledger Entry"."Global Dimension 1 Code");
        if RetainNo("Vendor Ledger Entry".FieldNo("Global Dimension 2 Code")) then
            DtldVendLedgEntryBuffer.SetRange("Initial Entry Global Dim. 2", "Vendor Ledger Entry"."Global Dimension 2 Code");

        if not DtldVendLedgEntryBuffer.Find('-') then begin
            DtldVendLedgEntryBuffer.Reset();
            Clear(DtldVendLedgEntryBuffer);

            LastTmpDtldEntryNo := LastTmpDtldEntryNo + 1;
            DtldVendLedgEntryBuffer."Entry No." := LastTmpDtldEntryNo;
            DtldVendLedgEntryBuffer."Posting Date" := PostingDate;
            DtldVendLedgEntryBuffer."Document Type" := NewVendLedgEntry."Document Type";
            DtldVendLedgEntryBuffer."Initial Document Type" := NewVendLedgEntry."Document Type";
            DtldVendLedgEntryBuffer."Document No." := NewVendLedgEntry."Document No.";
            DtldVendLedgEntryBuffer."Entry Type" := DtldVendLedgEntry."Entry Type";
            DtldVendLedgEntryBuffer."Vendor Ledger Entry No." := NewVendLedgEntry."Entry No.";
            DtldVendLedgEntryBuffer."Vendor No." := NewVendLedgEntry."Vendor No.";
            DtldVendLedgEntryBuffer."Currency Code" := NewVendLedgEntry."Currency Code";
            DtldVendLedgEntryBuffer."User ID" := NewVendLedgEntry."User ID";
            DtldVendLedgEntryBuffer."Source Code" := NewVendLedgEntry."Source Code";
            DtldVendLedgEntryBuffer."Transaction No." := NewVendLedgEntry."Transaction No.";
            DtldVendLedgEntryBuffer."Journal Batch Name" := NewVendLedgEntry."Journal Batch Name";
            DtldVendLedgEntryBuffer."Reason Code" := NewVendLedgEntry."Reason Code";
            DtldVendLedgEntryBuffer."Initial Entry Due Date" := NewVendLedgEntry."Due Date";
            DtldVendLedgEntryBuffer."Initial Entry Global Dim. 1" := NewVendLedgEntry."Global Dimension 1 Code";
            DtldVendLedgEntryBuffer."Initial Entry Global Dim. 2" := NewVendLedgEntry."Global Dimension 2 Code";

            NewEntry := true;
        end;

        DtldVendLedgEntryBuffer.Amount :=
          DtldVendLedgEntryBuffer.Amount + DtldVendLedgEntry.Amount;
        DtldVendLedgEntryBuffer."Amount (LCY)" :=
          DtldVendLedgEntryBuffer."Amount (LCY)" + DtldVendLedgEntry."Amount (LCY)";
        DtldVendLedgEntryBuffer."Debit Amount" :=
          DtldVendLedgEntryBuffer."Debit Amount" + DtldVendLedgEntry."Debit Amount";
        DtldVendLedgEntryBuffer."Credit Amount" :=
          DtldVendLedgEntryBuffer."Credit Amount" + DtldVendLedgEntry."Credit Amount";
        DtldVendLedgEntryBuffer."Debit Amount (LCY)" :=
          DtldVendLedgEntryBuffer."Debit Amount (LCY)" + DtldVendLedgEntry."Debit Amount (LCY)";
        DtldVendLedgEntryBuffer."Credit Amount (LCY)" :=
          DtldVendLedgEntryBuffer."Credit Amount (LCY)" + DtldVendLedgEntry."Credit Amount (LCY)";

        if NewEntry then
            DtldVendLedgEntryBuffer.Insert
        else
            DtldVendLedgEntryBuffer.Modify();
    end;

    local procedure InsertDtldEntries()
    begin
        DtldVendLedgEntryBuffer.Reset();
        if DtldVendLedgEntryBuffer.Find('-') then
            repeat
                if ((DtldVendLedgEntryBuffer.Amount <> 0) or
                    (DtldVendLedgEntryBuffer."Amount (LCY)" <> 0) or
                    (DtldVendLedgEntryBuffer."Debit Amount" <> 0) or
                    (DtldVendLedgEntryBuffer."Credit Amount" <> 0) or
                    (DtldVendLedgEntryBuffer."Debit Amount (LCY)" <> 0) or
                    (DtldVendLedgEntryBuffer."Credit Amount (LCY)" <> 0))
                then begin
                    LastDtldEntryNo := LastDtldEntryNo + 1;

                    NewDtldVendLedgEntry := DtldVendLedgEntryBuffer;
                    NewDtldVendLedgEntry."Entry No." := LastDtldEntryNo;
                    NewDtldVendLedgEntry.Insert(true);
                end;
            until DtldVendLedgEntryBuffer.Next = 0;
        DtldVendLedgEntryBuffer.DeleteAll();
    end;

    local procedure InitializeParameter()
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := Today;
        if EntrdVendLedgEntry.Description = '' then
            EntrdVendLedgEntry.Description := Text009;

        with "Vendor Ledger Entry" do begin
            InsertField(FieldNo("Document No."), FieldCaption("Document No."));
            InsertField(FieldNo("Buy-from Vendor No."), FieldCaption("Buy-from Vendor No."));
            InsertField(FieldNo("Purchaser Code"), FieldCaption("Purchaser Code"));
            InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
            InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
        end;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Vendor Ledger", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[50]; RetainDocumentNo: Boolean; RetainBuyfromVendorNo: Boolean; RetainPurchaserCode: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeParameter;
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdVendLedgEntry.Description := Description;
        Retain[1] := RetainDocumentNo;
        Retain[2] := RetainBuyfromVendorNo;
        Retain[3] := RetainPurchaserCode;
        RetainDimText := RetainDimensionText;
    end;
}

