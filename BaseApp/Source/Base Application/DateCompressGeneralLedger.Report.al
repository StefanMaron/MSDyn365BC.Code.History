report 98 "Date Compress General Ledger"
{
    Caption = 'Date Compress General Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd,
                  TableData "G/L - Item Ledger Relation" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = SORTING("G/L Account No.", "Posting Date");

            trigger OnAfterGetRecord()
            begin
                GLEntry2 := "G/L Entry";
                with GLEntry2 do begin
                    SetCurrentKey("G/L Account No.", "Posting Date");
                    CopyFilters("G/L Entry");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    repeat
                        SetRange("G/L Account No.", "G/L Account No.");
                        SetRange("Gen. Posting Type", "Gen. Posting Type");
                        SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                        SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");

                        if RetainNo(FieldNo("Document Type")) then
                            SetRange("Document Type", "Document Type");
                        if RetainNo(FieldNo("Document No.")) then
                            SetRange("Document No.", "Document No.");
                        if RetainNo(FieldNo("Job No.")) then
                            SetRange("Job No.", "Job No.");
                        if RetainNo(FieldNo("Business Unit Code")) then
                            SetRange("Business Unit Code", "Business Unit Code");
                        if RetainNo(FieldNo("Global Dimension 1 Code")) then
                            SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                        if RetainNo(FieldNo("Global Dimension 2 Code")) then
                            SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                        if Amount <> 0 then begin
                            if Amount > 0 then
                                SetFilter(Amount, '>0')
                            else
                                SetFilter(Amount, '<0');
                        end else begin
                            SetRange(Amount, 0);
                            if "Additional-Currency Amount" >= 0 then
                                SetFilter("Additional-Currency Amount", '>=0')
                            else
                                SetFilter("Additional-Currency Amount", '<0');
                        end;

                        InitNewEntry(NewGLEntry);

                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          0, false, DimEntryNo);
                        ComprDimEntryNo := DimEntryNo;
                        SummarizeEntry(NewGLEntry, GLEntry2);
                        while Next <> 0 do begin
                            DimBufMgt.CollectDimEntryNo(
                              TempSelectedDim, "Dimension Set ID", "Entry No.",
                              ComprDimEntryNo, true, DimEntryNo);
                            if DimEntryNo = ComprDimEntryNo then
                                SummarizeEntry(NewGLEntry, GLEntry2);
                        end;

                        InsertNewEntry(NewGLEntry, ComprDimEntryNo);

                        ComprCollectedEntries;

                        CopyFilters("G/L Entry");
                        SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    until not Find('-');
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

                if AnalysisView.FindFirst then
                    AnalysisView.UpdateLastEntryNo;
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                    CurrReport.Break();

                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                if AnalysisView.FindFirst then begin
                    AnalysisView.CheckDimensionsAreRetained(3, REPORT::"Date Compress General Ledger", false);
                    AnalysisView.CheckViewsAreUpdated;
                    Commit();
                end;

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress G/L");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress General Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[6] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 2 Code");

                NewGLEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();
                NewGLEntry.GetLastEntry(LastEntryNo, NextTransactionNo);
                NextTransactionNo := NextTransactionNo + 1;
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
                        ClosingDates = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("EntrdGLEntry.Description"; EntrdGLEntry.Description)
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
                            Caption = 'Document Type';
                            ToolTip = 'Specifies the type of document that is processed by the report or batch job.';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Job No.';
                            ToolTip = 'Specifies the job number.';
                        }
                        field("Retain[4]"; Retain[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies the code for the business unit, in a company group structure.';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress General Ledger", RetainDimText);
                        end;
                    }
                    group("Retain Totals")
                    {
                        Caption = 'Retain Totals';
                        field("Retain[7]"; Retain[7])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the item quantity on the ledger entries that will be date compressed.';
                        }
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
        DimSelectionBuf.CompareDimText(3, REPORT::"Date Compress General Ledger", '', RetainDimText, Text010);
    end;

    var
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing G/L entries...\\';
        Text005: Label 'G/L Account No.      #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        GLReg: Record "G/L Register";
        EntrdGLEntry: Record "G/L Entry";
        NewGLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        AnalysisView: Record "Analysis View";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        NoOfFields: Integer;
        NoOfFieldsContents: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        CompressEntriesQst: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';

    local procedure InitRegisters()
    begin
        OnBeforeInitRegisters("G/L Entry");

        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress G/L", '', '');

        DateComprReg.InitRegister(
          DATABASE::"G/L Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", '', GLReg."No.", SourceCodeSetup."Compress G/L");
        for i := 1 to NoOfFieldsContents do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);
        for i := NoOfFieldsContents + 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Totals" :=
                  CopyStr(
                    DateComprReg."Retain Totals" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Totals"));
        DateComprReg."Retain Totals" := CopyStr(DateComprReg."Retain Totals", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var GLReg: Record "G/L Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FoundLastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLReg."To Entry No." := NewGLEntry."Entry No.";

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        NewGLEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        NewGLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        if LastEntryNo <> FoundLastEntryNo then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
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

    local procedure SummarizeEntry(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    var
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GLEntryVatEntrylink: Record "G/L Entry - VAT Entry Link";
        GLEntryVatEntrylink2: Record "G/L Entry - VAT Entry Link";
    begin
        with GLEntry do begin
            NewGLEntry.Amount := NewGLEntry.Amount + Amount;
            NewGLEntry."VAT Amount" := NewGLEntry."VAT Amount" + "VAT Amount";
            NewGLEntry."Debit Amount" := NewGLEntry."Debit Amount" + "Debit Amount";
            NewGLEntry."Credit Amount" := NewGLEntry."Credit Amount" + "Credit Amount";
            NewGLEntry."Additional-Currency Amount" :=
              NewGLEntry."Additional-Currency Amount" + "Additional-Currency Amount";
            NewGLEntry."Add.-Currency Debit Amount" :=
              NewGLEntry."Add.-Currency Debit Amount" + "Add.-Currency Debit Amount";
            NewGLEntry."Add.-Currency Credit Amount" :=
              NewGLEntry."Add.-Currency Credit Amount" + "Add.-Currency Credit Amount";
            if RetainNo(FieldNo(Quantity)) then
                NewGLEntry.Quantity := NewGLEntry.Quantity + Quantity;
            Delete;

            GLItemLedgRelation.SetRange("G/L Entry No.", "Entry No.");
            GLItemLedgRelation.DeleteAll();

            GLEntryVatEntrylink.SetRange("G/L Entry No.", "Entry No.");
            if GLEntryVatEntrylink.FindSet then
                repeat
                    GLEntryVatEntrylink2 := GLEntryVatEntrylink;
                    GLEntryVatEntrylink2.Delete();
                    GLEntryVatEntrylink2."G/L Entry No." := NewGLEntry."Entry No.";
                    if GLEntryVatEntrylink2.Insert() then;
                until GLEntryVatEntrylink.Next = 0;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    procedure ComprCollectedEntries()
    var
        GLEntry: Record "G/L Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        GLEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, GLEntryNo) then begin
            InitNewEntry(NewGLEntry);
            repeat
                GLEntry.Get(GLEntryNo);
                SummarizeEntry(NewGLEntry, GLEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, GLEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewGLEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewGLEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewGLEntry: Record "G/L Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with GLEntry2 do begin
            NewGLEntry.Init();
            NewGLEntry."Entry No." := LastEntryNo;
            NewGLEntry."G/L Account No." := "G/L Account No.";
            NewGLEntry."Posting Date" := GetRangeMin("Posting Date");
            NewGLEntry.Description := EntrdGLEntry.Description;
            NewGLEntry."Gen. Posting Type" := "Gen. Posting Type";
            NewGLEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            NewGLEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            NewGLEntry."System-Created Entry" := true;
            NewGLEntry."Prior-Year Entry" := true;
            NewGLEntry."Source Code" := SourceCodeSetup."Compress G/L";
            NewGLEntry."User ID" := UserId;
            NewGLEntry."Transaction No." := NextTransactionNo;

            if RetainNo(FieldNo("Document Type")) then
                NewGLEntry."Document Type" := "Document Type";
            if RetainNo(FieldNo("Document No.")) then
                NewGLEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Job No.")) then
                NewGLEntry."Job No." := "Job No.";
            if RetainNo(FieldNo("Business Unit Code")) then
                NewGLEntry."Business Unit Code" := "Business Unit Code";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewGLEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewGLEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewGLEntry."G/L Account No.");
            Window.Update(2, NewGLEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewGLEntry: Record "G/L Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewGLEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewGLEntry.Insert();
    end;

    local procedure InitializeParameter()
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := Today;
        if EntrdGLEntry.Description = '' then
            EntrdGLEntry.Description := Text009;

        with "G/L Entry" do begin
            InsertField(FieldNo("Document Type"), FieldCaption("Document Type"));
            InsertField(FieldNo("Document No."), FieldCaption("Document No."));
            InsertField(FieldNo("Job No."), FieldCaption("Job No."));
            InsertField(FieldNo("Business Unit Code"), FieldCaption("Business Unit Code"));
            InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
            InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
            NoOfFieldsContents := NoOfFields;
            InsertField(FieldNo(Quantity), FieldCaption(Quantity));
        end;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress General Ledger", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[50]; RetainDocumentType: Boolean; RetainDocumentNo: Boolean; RetainJobNo: Boolean; RetainBuisnessUnitCode: Boolean; RetainQuantity: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeParameter;
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdGLEntry.Description := Description;
        Retain[1] := RetainDocumentType;
        Retain[2] := RetainDocumentNo;
        Retain[3] := RetainJobNo;
        Retain[4] := RetainBuisnessUnitCode;
        Retain[7] := RetainQuantity;
        RetainDimText := RetainDimensionText;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRegisters(var GLEntry: Record "G/L Entry")
    begin
    end;
}

