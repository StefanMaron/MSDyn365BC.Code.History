report 1498 "Date Compress Bank Acc. Ledger"
{
    ApplicationArea = Suite;
    Caption = 'Date Compress Bank Account Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
        {
            DataItemTableView = SORTING("Bank Account No.", "Posting Date") WHERE(Open = CONST(false));
            RequestFilterFields = "Bank Account No.", "Bank Acc. Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                BankAccLedgEntry2 := "Bank Account Ledger Entry";
                with BankAccLedgEntry2 do begin
                    SetCurrentKey("Bank Account No.", "Posting Date");
                    CopyFilters("Bank Account Ledger Entry");
                    SetRange("Bank Account No.", "Bank Account No.");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    SetRange("Bank Acc. Posting Group", "Bank Acc. Posting Group");
                    SetRange("Currency Code", "Currency Code");
                    SetRange("Document Type", "Document Type");

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Our Contact Code")) then
                        SetRange("Our Contact Code", "Our Contact Code");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                    if Amount >= 0 then
                        SetFilter(Amount, '>=0')
                    else
                        SetFilter(Amount, '<0');

                    InitNewEntry(NewBankAccLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry2);
                    while Next <> 0 do begin
                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          ComprDimEntryNo, true, DimEntryNo);
                        if DimEntryNo = ComprDimEntryNo then
                            SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry2);
                    end;

                    InsertNewEntry(NewBankAccLedgEntry, ComprDimEntryNo);

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
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                LastTransactionNo: Integer;
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(Text004);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Bank Acc. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[3] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', GLSetup."Global Dimension 2 Code");

                GLEntry.LockTable();
                NewBankAccLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters;

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Bank Acc. Ledger"));
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
                    field("EntrdBankAccLedgEntry.Description"; EntrdBankAccLedgEntry.Description)
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
                            Caption = 'Our Contact Code';
                            ToolTip = 'Specifies the employee who is responsible for this bank account.';
                        }
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
                        DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Bank Acc. Ledger", RetainDimText);
                    end;
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
            InitializeParameter;
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
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Date Compress Bank Acc. Ledger", '', RetainDimText, Text010);
        BankAccLedgEntryFilter := CopyStr("Bank Account Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
        LogStartTelemetryMessage();
    end;

    trigger OnPostReport()
    begin
        LogEndTelemetryMessage();
    end;

    var
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing bank account ledger entries...\\Bank Account No.       #1##########\Date                   #2######\\No. of new entries     #3######\No. of entries deleted #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        GLReg: Record "G/L Register";
        EntrdBankAccLedgEntry: Record "Bank Account Ledger Entry";
        NewBankAccLedgEntry: Record "Bank Account Ledger Entry";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        GLEntry: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        BankAccLedgEntryFilter: Text[250];
        NoOfFields: Integer;
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
        UseDataArchive: Boolean;
        [InDataSet]
        DataArchiveProviderExists: Boolean;
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        if GLReg.Find('+') then;
        GLReg.Init();
        GLReg."No." := GLReg."No." + 1;
        GLReg."Creation Date" := Today;
        GLReg."Creation Time" := Time;
        GLReg."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
        GLReg."User ID" := UserId;
        GLReg."From Entry No." := LastEntryNo + 1;

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Bank Account Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          BankAccLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Bank Acc. Ledger");

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
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLEntry."Entry No." := LastEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry.Description := EntrdBankAccLedgEntry.Description;
        GLEntry."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := UserId;
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := GLEntry."Entry No.";

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
        NewBankAccLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        if NewBankAccLedgEntry.Find('+') then;
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> NewBankAccLedgEntry."Entry No." + 1)
        then begin
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

    local procedure SummarizeEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        with BankAccLedgEntry do begin
            NewBankAccLedgEntry.Amount := NewBankAccLedgEntry.Amount + Amount;
            NewBankAccLedgEntry."Remaining Amount" := NewBankAccLedgEntry."Remaining Amount" + "Remaining Amount";
            NewBankAccLedgEntry."Amount (LCY)" := NewBankAccLedgEntry."Amount (LCY)" + "Amount (LCY)";
            NewBankAccLedgEntry."Debit Amount" := NewBankAccLedgEntry."Debit Amount" + "Debit Amount";
            NewBankAccLedgEntry."Credit Amount" := NewBankAccLedgEntry."Credit Amount" + "Credit Amount";
            NewBankAccLedgEntry."Debit Amount (LCY)" :=
              NewBankAccLedgEntry."Debit Amount (LCY)" + "Debit Amount (LCY)";
            NewBankAccLedgEntry."Credit Amount (LCY)" :=
              NewBankAccLedgEntry."Credit Amount (LCY)" + "Credit Amount (LCY)";
            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
        if UseDataArchive then
            DataArchive.SaveRecord(BankAccLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        BankAccLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, BankAccLedgEntryNo) then begin
            InitNewEntry(NewBankAccLedgEntry);
            repeat
                BankAccLedgEntry.Get(BankAccLedgEntryNo);
                SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, BankAccLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewBankAccLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewBankAccLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with BankAccLedgEntry2 do begin
            NewBankAccLedgEntry.Init();
            NewBankAccLedgEntry."Entry No." := LastEntryNo;
            NewBankAccLedgEntry."Bank Account No." := "Bank Account No.";
            NewBankAccLedgEntry."Posting Date" := GetRangeMin("Posting Date");
            NewBankAccLedgEntry.Description := EntrdBankAccLedgEntry.Description;
            NewBankAccLedgEntry."Bank Acc. Posting Group" := "Bank Acc. Posting Group";
            NewBankAccLedgEntry."Currency Code" := "Currency Code";
            NewBankAccLedgEntry."Document Type" := "Document Type";
            NewBankAccLedgEntry."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
            NewBankAccLedgEntry."User ID" := UserId;
            NewBankAccLedgEntry."Transaction No." := NextTransactionNo;

            if RetainNo(FieldNo("Document No.")) then
                NewBankAccLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Our Contact Code")) then
                NewBankAccLedgEntry."Our Contact Code" := "Our Contact Code";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewBankAccLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewBankAccLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewBankAccLedgEntry."Bank Account No.");
            Window.Update(2, NewBankAccLedgEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewBankAccLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        OnInsertNewEntryOnBeforeInsert(NewBankAccLedgEntry, DimEntryNo);
        NewBankAccLedgEntry.Insert();
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdBankAccLedgEntry.Description = '' then
            EntrdBankAccLedgEntry.Description := Text009;

        with "Bank Account Ledger Entry" do begin
            InsertField(FieldNo("Document No."), FieldCaption("Document No."));
            InsertField(FieldNo("Our Contact Code"), FieldCaption("Our Contact Code"));
            InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
            InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
        end;
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainDocumentNo: Boolean; RetainOurContactCode: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeRequest(StartingDate, EndingDate, PeriodLength, Description, RetainDocumentNo, RetainOurContactCode, RetainDimensionText, true);
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainDocumentNo: Boolean; RetainOurContactCode: Boolean; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter;
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdBankAccLedgEntry.Description := Description;
        Retain[1] := RetainDocumentNo;
        Retain[2] := RetainOurContactCode;
        RetainDimText := RetainDimensionText;
        UseDataArchive := DoUseDataArchive and DataArchiveProviderExists;
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
        TelemetryDimensions.Add('RetainDocumentNo', Format(Retain[1], 0, 9));
        TelemetryDimensions.Add('RetainOurContactCode', Format(Retain[2], 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4I', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4J', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewEntryOnBeforeInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; DimEntryNo: Integer)
    begin
    end;
}

