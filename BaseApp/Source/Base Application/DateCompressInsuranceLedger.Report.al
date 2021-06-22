report 5697 "Date Compress Insurance Ledger"
{
    Caption = 'Date Compress Insurance Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd,
                  TableData "Ins. Coverage Ledger Entry" = rimd,
                  TableData "Insurance Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
        {
            DataItemTableView = SORTING("FA No.", "Insurance No.", "Disposed FA");
            RequestFilterFields = "Insurance No.", "FA No.";

            trigger OnAfterGetRecord()
            begin
                if ("Insurance No." <> '') and OnlyIndexEntries and not "Index Entry" then
                    CurrReport.Skip();
                InsCoverageLedgEntry2 := "Ins. Coverage Ledger Entry";
                with InsCoverageLedgEntry2 do begin
                    SetCurrentKey("FA No.", "Insurance No.");
                    CopyFilters("Ins. Coverage Ledger Entry");

                    SetRange("Insurance No.", "Insurance No.");
                    SetRange("FA No.", "FA No.");
                    SetRange("Document Type", "Document Type");
                    SetRange("Index Entry", "Index Entry");
                    SetRange("Disposed FA", "Disposed FA");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");

                    InitNewEntry(NewInsCoverageLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry2);
                    while Next <> 0 do begin
                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          ComprDimEntryNo, true, DimEntryNo);
                        if DimEntryNo = ComprDimEntryNo then
                            SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry2);
                    end;

                    InsertNewEntry(NewInsCoverageLedgEntry, ComprDimEntryNo);

                    ComprCollectedEntries;
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(InsuranceReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(InsuranceReg, DateComprReg);
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if not Confirm(Text000, false) then
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
                SourceCodeSetup.TestField("Compress Insurance Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Insurance Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[2] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Insurance Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[3] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Insurance Ledger", '', GLSetup."Global Dimension 2 Code");

                NewInsCoverageLedgEntry.LockTable();
                InsuranceReg.LockTable();
                DateComprReg.LockTable();

                LastEntryNo := InsCoverageLedgEntry2.GetLastEntryNo();
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
                    field(StartingDate; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(PeriodLength; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(PostingDescription; EntrdInsCoverageLedgEntry.Description)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    field(OnlyIndexEntries; OnlyIndexEntries)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Only Index Entries';
                        ToolTip = 'Specifies if only index entries are date compressed. With the Index Fixed Assets batch job, you can index fixed assets that are linked to a specific depreciation book. The batch job creates entries in a journal based on the conditions that you specify. You can then post the journal or adjust the entries before posting, if necessary.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field(DocumentNo; Retain[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                        }
                    }
                    field(RetainDimensions; RetainDimText)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies which dimension information you want to retain when the entries are compressed. The more dimension information that you choose to retain, the more detailed the compressed entries are.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Insurance Ledger", RetainDimText);
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
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := Today;
            if EntrdInsCoverageLedgEntry.Description = '' then
                EntrdInsCoverageLedgEntry.Description := Text009;

            with "Ins. Coverage Ledger Entry" do begin
                InsertField(FieldNo("Document No."), FieldCaption("Document No."));
                InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
                InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
            end;

            RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Insurance Ledger", '');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Date Compress Insurance Ledger", '', RetainDimText, Text010);
        InsCoverageLedgEntryFilter := CopyStr("Ins. Coverage Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        Text000: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing insurance ledger entries...\\';
        Text005: Label 'Insurance No.        #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        InsuranceReg: Record "Insurance Register";
        EntrdInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsCoverageLedgEntry2: Record "Ins. Coverage Ledger Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        InsCoverageLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        InsuranceRegExists: Boolean;
        OnlyIndexEntries: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        InsuranceReg.Init();
        InsuranceReg."No." := InsuranceReg.GetLastEntryNo() + 1;
        InsuranceReg."Creation Date" := Today;
        InsuranceReg."Creation Time" := Time;
        InsuranceReg."Source Code" := SourceCodeSetup."Compress Insurance Ledger";
        InsuranceReg."User ID" := UserId;
        InsuranceReg."From Entry No." := LastEntryNo + 1;

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Ins. Coverage Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          InsCoverageLedgEntryFilter, InsuranceReg."No.", SourceCodeSetup."Compress Insurance Ledger");

        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        InsuranceRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var InsuranceReg: Record "Insurance Register"; var DateComprReg: Record "Date Compr. Register")
    var
        CurrLastEntryNo: Integer;
    begin
        InsuranceReg."To Entry No." := NewInsCoverageLedgEntry."Entry No.";

        if InsuranceRegExists then begin
            InsuranceReg.Modify();
            DateComprReg.Modify();
        end else begin
            InsuranceReg.Insert();
            DateComprReg.Insert();
            InsuranceRegExists := true;
        end;
        Commit();

        NewInsCoverageLedgEntry.LockTable();
        InsuranceReg.LockTable();
        DateComprReg.LockTable();

        InsCoverageLedgEntry2.Reset();
        CurrLastEntryNo := InsCoverageLedgEntry2.GetLastEntryNo();
        if LastEntryNo <> CurrLastEntryNo then begin
            LastEntryNo := CurrLastEntryNo;
            InitRegisters;
        end;
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

    local procedure SummarizeEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry")
    begin
        with InsCoverageLedgEntry do begin
            NewInsCoverageLedgEntry.Amount := NewInsCoverageLedgEntry.Amount + Amount;
            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    local procedure ComprCollectedEntries()
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        InsCoverageLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, InsCoverageLedgEntryNo) then begin
            InitNewEntry(NewInsCoverageLedgEntry);
            repeat
                InsCoverageLedgEntry.Get(InsCoverageLedgEntryNo);
                SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, InsCoverageLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewInsCoverageLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewInsCoverageLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;
        with InsCoverageLedgEntry2 do begin
            NewInsCoverageLedgEntry.Init();
            NewInsCoverageLedgEntry."Entry No." := LastEntryNo;

            NewInsCoverageLedgEntry."Insurance No." := "Insurance No.";
            NewInsCoverageLedgEntry."FA No." := "FA No.";
            NewInsCoverageLedgEntry."Document Type" := "Document Type";
            NewInsCoverageLedgEntry."Index Entry" := "Index Entry";
            NewInsCoverageLedgEntry."Disposed FA" := "Disposed FA";

            NewInsCoverageLedgEntry."Posting Date" := GetRangeMin("Posting Date");
            NewInsCoverageLedgEntry.Description := EntrdInsCoverageLedgEntry.Description;
            NewInsCoverageLedgEntry."Source Code" := SourceCodeSetup."Compress Insurance Ledger";
            NewInsCoverageLedgEntry."User ID" := UserId;
            if RetainNo(FieldNo("Document No.")) then
                NewInsCoverageLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewInsCoverageLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewInsCoverageLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewInsCoverageLedgEntry."Insurance No.");
            Window.Update(2, NewInsCoverageLedgEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewInsCoverageLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewInsCoverageLedgEntry.Insert();
    end;
}

