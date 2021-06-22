report 1198 "Date Compress Resource Ledger"
{
    Caption = 'Date Compress Resource Ledger';
    Permissions = TableData "Res. Ledger Entry" = rimd,
                  TableData "Resource Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
        {
            DataItemTableView = SORTING("Resource No.", "Posting Date");
            RequestFilterFields = "Entry Type", "Resource No.", "Resource Group No.";

            trigger OnAfterGetRecord()
            begin
                ResLedgEntry2 := "Res. Ledger Entry";
                with ResLedgEntry2 do begin
                    SetCurrentKey("Resource No.", "Posting Date");
                    CopyFilters("Res. Ledger Entry");
                    SetRange("Entry Type", "Entry Type");
                    SetRange("Resource No.", "Resource No.");
                    SetRange("Resource Group No.", "Resource Group No.");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));

                    if RetainNo(FieldNo("Document No.")) then
                        SetRange("Document No.", "Document No.");
                    if RetainNo(FieldNo("Work Type Code")) then
                        SetRange("Work Type Code", "Work Type Code");
                    if RetainNo(FieldNo("Job No.")) then
                        SetRange("Job No.", "Job No.");
                    if RetainNo(FieldNo("Unit of Measure Code")) then
                        SetRange("Unit of Measure Code", "Unit of Measure Code");
                    if RetainNo(FieldNo("Global Dimension 1 Code")) then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if RetainNo(FieldNo("Global Dimension 2 Code")) then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                    if RetainNo(FieldNo(Chargeable)) then
                        SetRange(Chargeable, Chargeable);
                    if RetainNo(FieldNo("Source Type")) then
                        SetRange("Source Type", "Source Type");
                    if RetainNo(FieldNo("Source No.")) then
                        SetRange("Source No.", "Source No.");

                    if Quantity >= 0 then
                        SetFilter(Quantity, '>=0')
                    else
                        SetFilter(Quantity, '<0');

                    InitNewEntry(NewResLedgEntry);

                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, "Dimension Set ID", "Entry No.",
                      0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewResLedgEntry, ResLedgEntry2);
                    while Next <> 0 do begin
                        DimBufMgt.CollectDimEntryNo(
                          TempSelectedDim, "Dimension Set ID", "Entry No.",
                          ComprDimEntryNo, true, DimEntryNo);
                        if DimEntryNo = ComprDimEntryNo then
                            SummarizeEntry(NewResLedgEntry, ResLedgEntry2);
                    end;

                    InsertNewEntry(NewResLedgEntry, ComprDimEntryNo);

                    ComprCollectedEntries;
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(ResReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(ResReg, DateComprReg);
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if not Confirm(Text000, false) then
                    CurrReport.Break();

                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(Text004);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Res. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Resource Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Resource Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[6] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Resource Ledger", '', GLSetup."Global Dimension 2 Code");

                NewResLedgEntry.LockTable();
                ResReg.LockTable();
                DateComprReg.LockTable();

                LastEntryNo := ResLedgEntry2.GetLastEntryNo();
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
                        ApplicationArea = Jobs;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("EntrdResLedgEntry.Description"; EntrdResLedgEntry.Description)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of a document that the date compression will apply to.';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Work Type Code';
                            ToolTip = 'Specifies that you want to retain the contents of the Work Type Code field.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Job No.';
                            ToolTip = 'Specifies the job number.';
                        }
                        field("Retain[4]"; Retain[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Unit of Measure Code';
                            ToolTip = 'Specifies that you want to retain the contents of the Unit of Measure Code field.';
                        }
                        field("Retain[8]"; Retain[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Source Type';
                            ToolTip = 'Specifies that you want to retain the contents of the Source Type field.';
                        }
                        field("Retain[9]"; Retain[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Source No.';
                            ToolTip = 'Specifies that you want to retain the contents of the Source No. field.';
                        }
                        field("Retain[7]"; Retain[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Chargeable';
                            ToolTip = 'Specifies that you want to retain the contents of the Chargeable field when compressing resource ledgers.';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Resource Ledger", RetainDimText);
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
            if EntrdResLedgEntry.Description = '' then
                EntrdResLedgEntry.Description := Text009;

            with "Res. Ledger Entry" do begin
                InsertField(FieldNo("Document No."), FieldCaption("Document No."));
                InsertField(FieldNo("Work Type Code"), FieldCaption("Work Type Code"));
                InsertField(FieldNo("Job No."), FieldCaption("Job No."));
                InsertField(FieldNo("Unit of Measure Code"), FieldCaption("Unit of Measure Code"));
                InsertField(FieldNo("Global Dimension 1 Code"), FieldCaption("Global Dimension 1 Code"));
                InsertField(FieldNo("Global Dimension 2 Code"), FieldCaption("Global Dimension 2 Code"));
                InsertField(FieldNo(Chargeable), FieldCaption(Chargeable));
                InsertField(FieldNo("Source Type"), FieldCaption("Source No."));
                InsertField(FieldNo("Source No."), FieldCaption("Source No."));
            end;

            RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Resource Ledger", '');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Date Compress Resource Ledger", '', RetainDimText, Text010);
        ResLedgEntryFilter := CopyStr("Res. Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        Text000: Label 'This batch job deletes entries.Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing resource ledger entries...\\Resource No.         #1##########\Date                 #2######\\No. of new entries   #3######\No. of entries del.  #4######';
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        ResReg: Record "Resource Register";
        EntrdResLedgEntry: Record "Res. Ledger Entry";
        NewResLedgEntry: Record "Res. Ledger Entry";
        ResLedgEntry2: Record "Res. Ledger Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        ResLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        ResRegExists: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        ResReg.Init();
        ResReg."No." := ResReg.GetLastEntryNo() + 1;
        ResReg."Creation Date" := Today;
        ResReg."Creation Time" := Time;
        ResReg."Source Code" := SourceCodeSetup."Compress Res. Ledger";
        ResReg."User ID" := UserId;
        ResReg."From Entry No." := LastEntryNo + 1;

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Res. Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          ResLedgEntryFilter, ResReg."No.", SourceCodeSetup."Compress Res. Ledger");

        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        ResRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var ResReg: Record "Resource Register"; var DateComprReg: Record "Date Compr. Register")
    var
        CurrLastEntryNo: Integer;
    begin
        ResReg."To Entry No." := NewResLedgEntry."Entry No.";

        if ResRegExists then begin
            ResReg.Modify();
            DateComprReg.Modify();
        end else begin
            ResReg.Insert();
            DateComprReg.Insert();
            ResRegExists := true;
        end;
        Commit();

        NewResLedgEntry.LockTable();
        ResReg.LockTable();
        DateComprReg.LockTable();

        ResLedgEntry2.Reset();
        CurrLastEntryNo := ResLedgEntry2.GetLastEntryNo();
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

    local procedure SummarizeEntry(var NewResLedgEntry: Record "Res. Ledger Entry"; ResLedgEntry: Record "Res. Ledger Entry")
    begin
        with ResLedgEntry do begin
            NewResLedgEntry.Quantity := NewResLedgEntry.Quantity + Quantity;
            NewResLedgEntry."Quantity (Base)" := NewResLedgEntry."Quantity (Base)" + "Quantity (Base)";
            NewResLedgEntry."Total Cost" := NewResLedgEntry."Total Cost" + "Total Cost";
            NewResLedgEntry."Total Price" := NewResLedgEntry."Total Price" + "Total Price";
            Delete;
            DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
            Window.Update(4, DateComprReg."No. Records Deleted");
        end;
    end;

    procedure ComprCollectedEntries()
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        ResLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, ResLedgEntryNo) then begin
            InitNewEntry(NewResLedgEntry);
            repeat
                ResLedgEntry.Get(ResLedgEntryNo);
                SummarizeEntry(NewResLedgEntry, ResLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, ResLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewResLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewResLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo;
    end;

    procedure InitNewEntry(var NewResLedgEntry: Record "Res. Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        with ResLedgEntry2 do begin
            NewResLedgEntry.Init();
            NewResLedgEntry."Entry No." := LastEntryNo;
            NewResLedgEntry."Entry Type" := "Entry Type";
            NewResLedgEntry."Resource No." := "Resource No.";
            NewResLedgEntry."Resource Group No." := "Resource Group No.";
            NewResLedgEntry."Posting Date" := GetRangeMin("Posting Date");
            NewResLedgEntry.Description := EntrdResLedgEntry.Description;
            NewResLedgEntry."Source Code" := SourceCodeSetup."Compress Res. Ledger";
            NewResLedgEntry."User ID" := UserId;

            if RetainNo(FieldNo("Document No.")) then
                NewResLedgEntry."Document No." := "Document No.";
            if RetainNo(FieldNo("Work Type Code")) then
                NewResLedgEntry."Work Type Code" := "Work Type Code";
            if RetainNo(FieldNo("Job No.")) then
                NewResLedgEntry."Job No." := "Job No.";
            if RetainNo(FieldNo("Unit of Measure Code")) then
                NewResLedgEntry."Unit of Measure Code" := "Unit of Measure Code";
            if RetainNo(FieldNo("Global Dimension 1 Code")) then
                NewResLedgEntry."Global Dimension 1 Code" := "Global Dimension 1 Code";
            if RetainNo(FieldNo("Global Dimension 2 Code")) then
                NewResLedgEntry."Global Dimension 2 Code" := "Global Dimension 2 Code";
            if RetainNo(FieldNo(Chargeable)) then
                NewResLedgEntry.Chargeable := Chargeable;

            Window.Update(1, NewResLedgEntry."Resource No.");
            Window.Update(2, NewResLedgEntry."Posting Date");
            DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
            Window.Update(3, DateComprReg."No. of New Records");
        end;
    end;

    local procedure InsertNewEntry(var NewResLedgEntry: Record "Res. Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewResLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewResLedgEntry.Insert();
    end;
}

