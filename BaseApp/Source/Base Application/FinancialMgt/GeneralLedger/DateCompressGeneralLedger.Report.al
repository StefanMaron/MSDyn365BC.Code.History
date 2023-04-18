report 98 "Date Compress General Ledger"
{
    Caption = 'Date Compress General Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
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

                        if DateComprRetainFields."Retain Document Type" then
                            SetRange("Document Type", "Document Type");
                        if DateComprRetainFields."Retain Document No." then
                            SetRange("Document No.", "Document No.");
                        if DateComprRetainFields."Retain Job No." then
                            SetRange("Job No.", "Job No.");
                        if DateComprRetainFields."Retain Business Unit Code" then
                            SetRange("Business Unit Code", "Business Unit Code");
                        if DateComprRetainFields."Retain Global Dimension 1" then
                            SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                        if DateComprRetainFields."Retain Global Dimension 2" then
                            SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                        if DateComprRetainFields."Retain Journal Template Name" then
                            SetRange("Journal Templ. Name", "Journal Templ. Name");

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

                        OnGLEntryOnAfterGetRecordOnBeforeInitNewEntry(GLEntry2, "G/L Entry");

                        InitNewEntry(NewGLEntry);

                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          0, false, DimEntryNo);
                        ComprDimEntryNo := DimEntryNo;
                        SummarizeEntry(NewGLEntry, GLEntry2);
                        while Next() <> 0 do begin
                            DimBufMgt.CollectDimEntryNo(
                              TempSelectedDim, "Dimension Set ID", "Entry No.",
                              ComprDimEntryNo, true, DimEntryNo);
                            if DimEntryNo = ComprDimEntryNo then
                                SummarizeEntry(NewGLEntry, GLEntry2);
                        end;

                        InsertNewEntry(NewGLEntry, ComprDimEntryNo);

                        ComprCollectedEntries();

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

                if AnalysisView.FindFirst() then
                    AnalysisView.UpdateLastEntryNo();

                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                if AnalysisView.FindFirst() then begin
                    AnalysisView.CheckDimensionsAreRetained(3, REPORT::"Date Compress General Ledger", false);
                    if not SkipAnalysisViewUpdateCheck then
                        AnalysisView.CheckViewsAreUpdated();
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
                DateComprRetainFields."Retain Global Dimension 1" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 1 Code");
                DateComprRetainFields."Retain Global Dimension 2" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 2 Code");

                NewGLEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();
                NewGLEntry.GetLastEntry(LastEntryNo, NextTransactionNo);
                NextTransactionNo := NextTransactionNo + 1;
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress General Ledger"));
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

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
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
                        field("Retain[1]"; DateComprRetainFields."Retain Document Type")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document Type';
                            ToolTip = 'Specifies the type of document that is processed by the report or batch job.';
                        }
                        field("Retain[2]"; DateComprRetainFields."Retain Document No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        }
                        field("Retain[3]"; DateComprRetainFields."Retain Job No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Job No.';
                            ToolTip = 'Specifies the job number.';
                        }
                        field("Retain[4]"; DateComprRetainFields."Retain Business Unit Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                        }
                        field("Retain[7]"; DateComprRetainFields."Retain Journal Template Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Journal Template Name';
                            ToolTip = 'Specifies the name of the journal template that is used for the posting.';
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
                        field("Retain[8]"; DateComprRetainFields."Retain Totals")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the item quantity on the ledger entries that will be date compressed.';
                        }
                    }
                    field(UseDataArchiveCtrl; UseDataArchive)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Deleted Entries';
                        ToolTip = 'Specifies whether the deleted (compressed) entries will be stored in the data archive for later inspection or export.';
                        Visible = DataArchiveProviderExists;
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
        begin
            InitializeParameter();
        end;

        trigger OnInit()
        begin
            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        DimSelectionBuf.CompareDimText(3, REPORT::"Date Compress General Ledger", '', RetainDimText, Text010);

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
        LogStartTelemetryMessage();
    end;

    trigger OnPostReport()
    begin
        LogEndTelemetryMessage();
    end;

    var
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
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        AnalysisView: Record "Analysis View";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        [InDataSet]
        DataArchiveProviderExists: Boolean;
        SkipAnalysisViewUpdateCheck: Boolean;

        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing G/L entries...\\';
        Text005: Label 'G/L Account No.      #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    begin
        OnBeforeInitRegisters("G/L Entry");

        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress G/L", '', '');

        DateComprReg.InitRegister(
          DATABASE::"G/L Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", '', GLReg."No.", SourceCodeSetup."Compress G/L");

        if DateComprRetainFields."Retain Document Type" then
            AddFieldContent(NewGLEntry.FieldName("Document Type"));
        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewGLEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Job No." then
            AddFieldContent(NewGLEntry.FieldName("Job No."));
        if DateComprRetainFields."Retain Business Unit Code" then
            AddFieldContent(NewGLEntry.FieldName("Business Unit Code"));
        if DateComprRetainFields."Retain Global Dimension 1" then
            AddFieldContent(NewGLEntry.FieldName("Global Dimension 1 Code"));
        if DateComprRetainFields."Retain Global Dimension 2" then
            AddFieldContent(NewGLEntry.FieldName("Global Dimension 2 Code"));
        if DateComprRetainFields."Retain Journal Template Name" then
            AddFieldContent(NewGLEntry.FieldName("Journal Templ. Name"));

        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        if DateComprRetainFields."Retain Quantity" then
            DateComprReg."Retain Totals" :=
              CopyStr(
                DateComprReg."Retain Totals" + ',' + NewGLEntry.FieldName(Quantity), 1,
                MaxStrLen(DateComprReg."Retain Totals"));

        DateComprReg."Retain Totals" := CopyStr(DateComprReg."Retain Totals", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure AddFieldContent(FieldName: Text)
    begin
        DateComprReg."Retain Field Contents" :=
            CopyStr(
                DateComprReg."Retain Field Contents" + ',' + FieldName, 1, MaxStrLen(DateComprReg."Retain Field Contents"));
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
            InitRegisters();
        end;
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
            if DateComprRetainFields."Retain Quantity" then
                NewGLEntry.Quantity := NewGLEntry.Quantity + Quantity;
            OnSummarizeEntryOnBeforeGLEntryDelete(NewGLEntry, GLEntry);
            Delete();

            GLItemLedgRelation.SetRange("G/L Entry No.", "Entry No.");
            GLItemLedgRelation.DeleteAll();

            GLEntryVatEntrylink.SetRange("G/L Entry No.", "Entry No.");
            if GLEntryVatEntrylink.FindSet() then
                repeat
                    GLEntryVatEntrylink2 := GLEntryVatEntrylink;
                    GLEntryVatEntrylink2.Delete();
                    GLEntryVatEntrylink2."G/L Entry No." := NewGLEntry."Entry No.";
                    if GLEntryVatEntrylink2.Insert() then;
                until GLEntryVatEntrylink.Next() = 0;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
        if UseDataArchive then
            DataArchive.SaveRecord(GLEntry);

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
        DimBufMgt.DeleteAllDimEntryNo();
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
            NewGLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            NewGLEntry."Transaction No." := NextTransactionNo;

            if DateComprRetainFields."Retain Document Type" then
                NewGLEntry."Document Type" := "Document Type";
            if DateComprRetainFields."Retain Document No." then
                NewGLEntry."Document No." := "Document No.";
            if DateComprRetainFields."Retain Job No." then
                NewGLEntry."Job No." := "Job No.";
            if DateComprRetainFields."Retain Business Unit Code" then
                NewGLEntry."Business Unit Code" := "Business Unit Code";
            if DateComprRetainFields."Retain Global Dimension 1" then
                NewGLEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if DateComprRetainFields."Retain Global Dimension 2" then
                NewGLEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";
            if DateComprRetainFields."Retain Journal Template Name" then
                NewGLEntry."Journal Templ. Name" := "Journal Templ. Name";

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
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdGLEntry.Description = '' then
            EntrdGLEntry.Description := Text009;

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress General Ledger", '');
    end;

#if not CLEAN20
    [Obsolete('Replaced by InitializeRequest with parameter DateComprRetainFields', '20.0')]
    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainDocumentType: Boolean; RetainDocumentNo: Boolean; RetainJobNo: Boolean; RetainBuisnessUnitCode: Boolean; RetainQuantity: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeRequest(StartingDate, EndingDate, PeriodLength, Description, RetainDocumentType, RetainDocumentNo, RetainJobNo, RetainBuisnessUnitCode, RetainQuantity, RetainDimensionText, true)
    end;
#endif

#if not CLEAN20
    [Obsolete('Replaced by InitializeRequest with parameter DateComprRetainFields', '20.0')]
    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainDocumentType: Boolean; RetainDocumentNo: Boolean; RetainJobNo: Boolean; RetainBuisnessUnitCode: Boolean; RetainQuantity: Boolean; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdGLEntry.Description := Description;
        DateComprRetainFields."Retain Document Type" := RetainDocumentType;
        DateComprRetainFields."Retain Document No." := RetainDocumentNo;
        DateComprRetainFields."Retain Job No." := RetainJobNo;
        DateComprRetainFields."Retain Business Unit Code" := RetainBuisnessUnitCode;
        DateComprRetainFields."Retain Quantity" := RetainQuantity;
        RetainDimText := RetainDimensionText;
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;
#endif

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdGLEntry.Description := Description;
        DateComprRetainFields := NewDateComprRetainFields;
        RetainDimText := RetainDimensionText;
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    internal procedure SetSkipAnalysisViewUpdateCheck();
    begin
        SkipAnalysisViewUpdateCheck := true;
    end;

    local procedure LogStartTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('UseRequestPage', Format(CurrReport.UseRequestPage()));
        TelemetryDimensions.Add('StartDate', Format(EntrdDateComprReg."Starting Date", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(EntrdDateComprReg."Ending Date", 0, 9));
        TelemetryDimensions.Add('PeriodLength', Format(EntrdDateComprReg."Period Length", 0, 9));
        TelemetryDimensions.Add('RetainDocumentType', Format(DateComprRetainFields."Retain Document Type", 0, 9));
        TelemetryDimensions.Add('RetainDocumentNo', Format(DateComprRetainFields."Retain Document No.", 0, 9));
        TelemetryDimensions.Add('RetainJobNo', Format(DateComprRetainFields."Retain Job No.", 0, 9));
        TelemetryDimensions.Add('RetainBusinessUnitCode', Format(DateComprRetainFields."Retain Business Unit Code", 0, 9));
        TelemetryDimensions.Add('RetainQuantity', Format(DateComprRetainFields."Retain Quantity", 0, 9));
        TelemetryDimensions.Add('RetainJnlTemplate', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4O', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure LogEndTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('RegisterNo', Format(DateComprReg."Register No.", 0, 9));
        TelemetryDimensions.Add('TableID', Format(DateComprReg."Table ID", 0, 9));
        TelemetryDimensions.Add('NoRecordsDeleted', Format(DateComprReg."No. Records Deleted", 0, 9));
        TelemetryDimensions.Add('NoofNewRecords', Format(DateComprReg."No. of New Records", 0, 9));

        Session.LogMessage('0000F4P', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRegisters(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLEntryOnAfterGetRecordOnBeforeInitNewEntry(var GLEntry2: Record "G/L Entry"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeEntryOnBeforeGLEntryDelete(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    begin
    end;
}

