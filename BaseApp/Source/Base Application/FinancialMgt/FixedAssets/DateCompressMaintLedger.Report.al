report 5698 "Date Compress Maint. Ledger"
{
    Caption = 'Date Compress Maint. Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "FA Register" = rimd,
                  TableData "Maintenance Ledger Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Maintenance Ledger Entry"; "Maintenance Ledger Entry")
        {
            DataItemTableView = SORTING("FA No.", "Depreciation Book Code", "FA Posting Date");
            RequestFilterFields = "FA No.", "Depreciation Book Code";

            trigger OnAfterGetRecord()
            begin
                MaintenanceLedgEntry2 := "Maintenance Ledger Entry";
                with MaintenanceLedgEntry2 do begin
                    SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    CopyFilters("Maintenance Ledger Entry");

                    SetRange("FA No.", "FA No.");
                    SetRange("Depreciation Book Code", "Depreciation Book Code");
                    SetRange("FA Posting Group", "FA Posting Group");
                    SetRange("Document Type", "Document Type");

                    SetFilter("FA Posting Date", DateComprMgt.GetDateFilter("FA Posting Date", EntrdDateComprReg, true));

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Maintenance Code")) then
                        SetRange("Maintenance Code", "Maintenance Code");
                    if RetainNo(FieldNo("Index Entry")) then
                        SetRange("Index Entry", "Index Entry");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                    if Quantity >= 0 then
                        SetFilter(Quantity, '>=0')
                    else
                        SetFilter(Quantity, '<0');

                    InitNewEntry(NewMaintenanceLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewMaintenanceLedgEntry, MaintenanceLedgEntry2);
                    while Next() <> 0 do begin
                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          ComprDimEntryNo, true, DimEntryNo);
                        if DimEntryNo = ComprDimEntryNo then
                            SummarizeEntry(NewMaintenanceLedgEntry, MaintenanceLedgEntry2);
                    end;

                    InsertNewEntry(NewMaintenanceLedgEntry, ComprDimEntryNo);

                    ComprCollectedEntries();
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(FAReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(FAReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Maintenance Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Maint. Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Maint. Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Maint. Ledger", '', GLSetup."Global Dimension 2 Code");

                NewMaintenanceLedgEntry.LockTable();
                FAReg.LockTable();
                DateComprReg.LockTable();

                LastEntryNo := MaintenanceLedgEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("FA Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Maint. Ledger"));
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
                    field("EntrdMaintenanceLedgEntry.Description"; EntrdMaintenanceLedgEntry.Description)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Code';
                            ToolTip = 'Specifies the fixed asset.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Index Entry';
                            ToolTip = 'Specifies the index entry to be data compressed. With the Index Fixed Assets batch job, you can index fixed assets that are linked to a specific depreciation book. The batch job creates entries in a journal based on the conditions that you specify. You can then post the journal or adjust the entries before posting, if necessary.';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Maint. Ledger", RetainDimText);
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
            if EntrdMaintenanceLedgEntry.Description = '' then
                EntrdMaintenanceLedgEntry.Description := Text009;

            with "Maintenance Ledger Entry" do begin
                InsertField(FieldNo("Document No."), FieldCaption("Document No."));
                InsertField(FieldNo("Maintenance Code"), FieldCaption("Maintenance Code"));
                InsertField(FieldNo("Index Entry"), FieldCaption("Index Entry"));
                InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
                InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
            end;

            RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Maint. Ledger", '');

            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
            UseDataArchive := DataArchiveProviderExists;
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
          3, REPORT::"Date Compress Maint. Ledger", '', RetainDimText, Text010);

        MaintenanceLedgEntryFilter := CopyStr("Maintenance Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

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
        FAReg: Record "FA Register";
        EntrdMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        NewMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        MaintenanceLedgEntry2: Record "Maintenance Ledger Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        Window: Dialog;
        MaintenanceLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        FARegExists: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        [InDataSet]
        DataArchiveProviderExists: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing maintenance ledger entries...\\';
        Text005: Label 'FA No.               #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    begin
        FAReg.Init();
        FAReg."No." := FAReg.GetLastEntryNo() + 1;
        FAReg."Creation Date" := Today;
        FAReg."Creation Time" := Time;
        FAReg."Journal Type" := FAReg."Journal Type"::"Fixed Asset";
        FAReg."Source Code" := SourceCodeSetup."Compress Maintenance Ledger";
        FAReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(FAReg."User ID"));
        FAReg."From Maintenance Entry No." := LastEntryNo + 1;

        DateComprReg.Init();
        DateComprReg."No." := DateComprReg.GetLastEntryNo() + 1;
        DateComprReg."Table ID" := DATABASE::"Maintenance Ledger Entry";
        DateComprReg."Creation Date" := Today;
        DateComprReg."Starting Date" := EntrdDateComprReg."Starting Date";
        DateComprReg."Ending Date" := EntrdDateComprReg."Ending Date";
        DateComprReg."Period Length" := EntrdDateComprReg."Period Length";
        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);
        DateComprReg.Filter := MaintenanceLedgEntryFilter;
        DateComprReg."Register No." := FAReg."No.";
        DateComprReg."Source Code" := SourceCodeSetup."Compress Maintenance Ledger";
        DateComprReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(DateComprReg."User ID"));

        FARegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var FAReg: Record "FA Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FAReg2: Record "FA Register";
        CurrLastEntryNo: Integer;
    begin
        FAReg."To Maintenance Entry No." := NewMaintenanceLedgEntry."Entry No.";

        if FARegExists then begin
            FAReg.Modify();
            DateComprReg.Modify();
        end else begin
            FAReg.Insert();
            DateComprReg.Insert();
            FARegExists := true;
        end;

        Commit();

        NewMaintenanceLedgEntry.LockTable();
        FAReg.LockTable();
        DateComprReg.LockTable();

        MaintenanceLedgEntry2.Reset();
        CurrLastEntryNo := MaintenanceLedgEntry2.GetLastEntryNo();
        if (LastEntryNo <> CurrLastEntryNo) or (FAReg."No." <> FAReg2.GetLastEntryNo()) then begin
            LastEntryNo := CurrLastEntryNo;
            InitRegisters();
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

    local procedure SummarizeEntry(var NewMaintenanceLedgEntry: Record "Maintenance Ledger Entry"; MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        with MaintenanceLedgEntry do begin
            NewMaintenanceLedgEntry.Quantity := NewMaintenanceLedgEntry.Quantity + Quantity;
            NewMaintenanceLedgEntry.Amount := NewMaintenanceLedgEntry.Amount + Amount;
            Delete();
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
        if UseDataArchive then
            DataArchive.SaveRecord(MaintenanceLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        MaintenanceLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, MaintenanceLedgEntryNo) then begin
            InitNewEntry(NewMaintenanceLedgEntry);
            repeat
                MaintenanceLedgEntry.Get(MaintenanceLedgEntryNo);
                SummarizeEntry(NewMaintenanceLedgEntry, MaintenanceLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, MaintenanceLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewMaintenanceLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewMaintenanceLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewMaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with MaintenanceLedgEntry2 do begin
            NewMaintenanceLedgEntry.Init();
            NewMaintenanceLedgEntry."Entry No." := LastEntryNo;

            NewMaintenanceLedgEntry."FA No." := "FA No.";
            NewMaintenanceLedgEntry."Depreciation Book Code" := "Depreciation Book Code";
            NewMaintenanceLedgEntry."FA Posting Group" := "FA Posting Group";
            NewMaintenanceLedgEntry."Document Type" := "Document Type";

            NewMaintenanceLedgEntry."FA Posting Date" := GetRangeMin("FA Posting Date");
            NewMaintenanceLedgEntry."Posting Date" := GetRangeMin("FA Posting Date");
            NewMaintenanceLedgEntry.Description := EntrdMaintenanceLedgEntry.Description;
            NewMaintenanceLedgEntry."Source Code" := SourceCodeSetup."Compress Maintenance Ledger";
            NewMaintenanceLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));

            if RetainNo(FieldNo("Document No.")) then
                NewMaintenanceLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Maintenance Code")) then
                NewMaintenanceLedgEntry."Maintenance Code" := "Maintenance Code";
            if RetainNo(FieldNo("Index Entry")) then
                NewMaintenanceLedgEntry."Index Entry" := "Index Entry";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewMaintenanceLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewMaintenanceLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";

            Window.Update(1, NewMaintenanceLedgEntry."FA No.");
            Window.Update(2, NewMaintenanceLedgEntry."FA Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewMaintenanceLedgEntry: Record "Maintenance Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewMaintenanceLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewMaintenanceLedgEntry.Insert();
        if NewMaintenanceLedgEntry."FA No." <> '' then
            FAInsertLedgEntry.SetMaintenanceLastDate(NewMaintenanceLedgEntry);
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; RetainDimTextFrom: Text[250])
    begin
        InitializeRequest(StartingDateFrom, EndingDateFrom, PeriodLengthFrom, DescriptionFrom, RetainDimTextFrom, true)
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; RetainDimTextFrom: Text[250]; DoUseDataArchive: Boolean)
    begin
        EntrdDateComprReg."Starting Date" := StartingDateFrom;
        EntrdDateComprReg."Ending Date" := EndingDateFrom;
        EntrdDateComprReg."Period Length" := PeriodLengthFrom;
        EntrdMaintenanceLedgEntry.Description := DescriptionFrom;
        RetainDimText := RetainDimTextFrom;

        InsertField("Maintenance Ledger Entry".FieldNo("Maintenance Code"), "Maintenance Ledger Entry".FieldCaption("Maintenance Code"));
        InsertField(
          "Maintenance Ledger Entry".FieldNo("Global Dimension 1 Code"),
          "Maintenance Ledger Entry".FieldCaption("Global Dimension 1 Code"));
        InsertField(
          "Maintenance Ledger Entry".FieldNo("Global Dimension 2 Code"),
          "Maintenance Ledger Entry".FieldCaption("Global Dimension 2 Code"));

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    procedure SetRetainDocumentNo(RetainValue: Boolean)
    begin
        Retain[1] := RetainValue;
        InsertField("Maintenance Ledger Entry".FieldNo("Document No."), "Maintenance Ledger Entry".FieldCaption("Document No."));
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
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4S', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4T', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    procedure SetRetainIndexEntry(RetainValue: Boolean)
    begin
        Retain[3] := RetainValue;
        InsertField("Maintenance Ledger Entry".FieldNo("Index Entry"), "Maintenance Ledger Entry".FieldCaption("Index Entry"));
    end;
}

