codeunit 14961 "Update Payroll Analysis View"
{
    Permissions = TableData "Payroll Analysis View" = rm,
                  TableData "Item Analysis View Filter" = r,
                  TableData "Payroll Analysis View Entry" = rimd,
                  TableData "Item Analysis View Budg. Entry" = rimd;
    TableNo = "Payroll Analysis View";

    trigger OnRun()
    begin
        if Code <> '' then begin
            InitLastEntryNo;
            LockTable;
            Find;
            UpdateOne(Rec, "Last Entry No." < LastEntryNo - 1000);
        end;
    end;

    var
        Text000: Label 'Do you want to update %1 %2?';
        Text005: Label 'Analysis View     #1############################\\';
        Text006: Label 'Updating table    #2############################\';
        Text007: Label 'Speed: (Entries/s)#4########\';
        Text008: Label 'Average Speed     #5########';
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewFilter: Record "Payroll Analysis View Filter";
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        DimSetEntry: Record "Dimension Set Entry";
        TempPayrollAnalysisViewEntry: Record "Payroll Analysis View Entry" temporary;
        TempPayrollAnalysisViewFilter: Record "Payroll Analysis View Filter" temporary;
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimEntryBuffer: Record "Dimension Entry Buffer" temporary;
        FilterIsInitialized: Boolean;
        FiltersExist: Boolean;
        LastEntryNoIsInitialized: Boolean;
        LedgEntryDimEntryNo: Integer;
        LastEntryNo: Integer;
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
        NoOfEntries: Integer;
        Window: Dialog;
        ShowProgressWindow: Boolean;
        WinLastEntryNo: Integer;
        WinPrevEntryNo: Integer;
        WinUpdateCounter: Integer;
        WinTotalCounter: Integer;
        WinTime0: Time;
        WinTime1: Time;
        WinTime2: Time;
        Text009: Label '#6############### @3@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text010: Label 'Summarizing';
        Text011: Label 'Updating Database';

    local procedure InitLastEntryNo()
    begin
        PayrollLedgerEntry.Reset;
        if LastEntryNoIsInitialized then
            exit;
        LastEntryNoIsInitialized := true;
        Commit;
        with PayrollLedgerEntry do begin
            LockTable;
            if FindLast then
                LastEntryNo := "Entry No.";
            Commit;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateAll(DirectlyFromPosting: Boolean)
    var
        PayrollAnalysisView2: Record "Payroll Analysis View";
    begin
        PayrollAnalysisView2.SetRange(Blocked, false);
        if DirectlyFromPosting then
            PayrollAnalysisView2.SetRange("Update on Posting", true);

        if PayrollAnalysisView2.IsEmpty then
            exit;

        InitLastEntryNo;

        if DirectlyFromPosting then
            PayrollAnalysisView2.SetFilter("Last Entry No.", '<%1', LastEntryNo);

        PayrollAnalysisView2.LockTable;
        if PayrollAnalysisView2.FindSet(true, true) then
            repeat
                UpdateOne(PayrollAnalysisView2, not DirectlyFromPosting and (PayrollAnalysisView2."Last Entry No." < LastEntryNo - 1000));
            until PayrollAnalysisView2.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure Update(var NewPayrollAnalysisView: Record "Payroll Analysis View"; ShowWindow: Boolean)
    begin
        InitLastEntryNo;
        NewPayrollAnalysisView.LockTable;
        NewPayrollAnalysisView.Find;
        UpdateOne(NewPayrollAnalysisView, ShowWindow);
    end;

    local procedure UpdateOne(var NewPayrollAnalysisView: Record "Payroll Analysis View"; ShowWindow: Boolean)
    begin
        PayrollAnalysisView := NewPayrollAnalysisView;
        PayrollAnalysisView.TestField(Blocked, false);
        ShowProgressWindow := ShowWindow;
        if ShowProgressWindow then
            InitWindow;

        if LastEntryNo > PayrollAnalysisView."Last Entry No." then begin
            if ShowProgressWindow then
                UpdateWindowHeader(DATABASE::"Payroll Analysis View Entry", PayrollLedgerEntry."Entry No.");
            UpdateEntries;
            PayrollAnalysisView."Last Entry No." := LastEntryNo;
            PayrollAnalysisView."Last Date Updated" := Today;
            PayrollAnalysisView.Modify;
        end;

        if ShowProgressWindow then
            Window.Close;
    end;

    local procedure UpdateEntries()
    var
        PayrollAnalysisViewSourceQry: Query "Payroll Analysis View Source";
        EntryNo: Integer;
    begin
        FilterIsInitialized := false;
        PayrollAnalysisViewSourceQry.SetRange(PayrollAnalysisViewCode, PayrollAnalysisView.Code);
        PayrollAnalysisViewSourceQry.SetRange(EntryNo, PayrollAnalysisView."Last Entry No." + 1, LastEntryNo);
        if PayrollAnalysisView."Payroll Element Filter" <> '' then
            PayrollAnalysisViewSourceQry.SetFilter(ElementCode, PayrollAnalysisView."Payroll Element Filter");
        if PayrollAnalysisView."Employee Filter" <> '' then
            PayrollAnalysisViewSourceQry.SetFilter(EmployeeNo, PayrollAnalysisView."Employee Filter");

        PayrollAnalysisViewSourceQry.Open;
        while PayrollAnalysisViewSourceQry.Read do begin
            if DimSetIDInFilter(PayrollAnalysisViewSourceQry.DimensionSetID, PayrollAnalysisView) then
                UpdateAnalysisViewEntry(
                  PayrollAnalysisViewSourceQry.DimVal1,
                  PayrollAnalysisViewSourceQry.DimVal2,
                  PayrollAnalysisViewSourceQry.DimVal3,
                  PayrollAnalysisViewSourceQry.DimVal4,
                  PayrollAnalysisViewSourceQry.ElementCode,
                  PayrollAnalysisViewSourceQry.UsePFAccumSystem,
                  PayrollAnalysisViewSourceQry.EmployeeNo,
                  PayrollAnalysisViewSourceQry.PostingDate,
                  PayrollAnalysisViewSourceQry.CalcGroup,
                  PayrollAnalysisViewSourceQry.PayrollAmount,
                  PayrollAnalysisViewSourceQry.TaxableAmount);
            EntryNo := EntryNo + 1;
            if ShowProgressWindow then
                UpdateWindowCounter(EntryNo);
        end;

        FlushAnalysisViewEntry;
    end;

    local procedure UpdateAnalysisViewEntry(DimValue1: Code[20]; DimValue2: Code[20]; DimValue3: Code[20]; DimValue4: Code[20]; ElementCode: Code[20]; UsePFAccumSystem: Boolean; EmployeeNo: Code[20]; PostingDate: Date; CalcGroup: Code[10]; PayrollAmount: Decimal; TaxableAmount: Decimal)
    var
        EntryNo: Integer;
    begin
        if PostingDate < PayrollAnalysisView."Starting Date" then begin
            PostingDate := PayrollAnalysisView."Starting Date" - 1;
            EntryNo := 0;
        end else begin
            PostingDate := CalculatePeriodStart(PostingDate, PayrollAnalysisView."Date Compression");
            if PostingDate < PayrollAnalysisView."Starting Date" then
                PostingDate := PayrollAnalysisView."Starting Date";
            if PayrollAnalysisView."Date Compression" <> PayrollAnalysisView."Date Compression"::None then
                EntryNo := 0;
        end;
        TempPayrollAnalysisViewEntry.Init;
        TempPayrollAnalysisViewEntry."Analysis View Code" := PayrollAnalysisView.Code;
        TempPayrollAnalysisViewEntry."Element Code" := ElementCode;
        TempPayrollAnalysisViewEntry."Use PF Accum. System" := UsePFAccumSystem;
        TempPayrollAnalysisViewEntry."Employee No." := EmployeeNo;
        TempPayrollAnalysisViewEntry."Element Group" := PayrollLedgerEntry."Element Group";
        TempPayrollAnalysisViewEntry."Org. Unit Code" := PayrollLedgerEntry."Org. Unit Code";
        TempPayrollAnalysisViewEntry."Payroll Element Type" := PayrollLedgerEntry."Element Type";
        TempPayrollAnalysisViewEntry."Posting Date" := PostingDate;
        TempPayrollAnalysisViewEntry."Calc Group" := CalcGroup;
        TempPayrollAnalysisViewEntry."Dimension 1 Value Code" := DimValue1;
        TempPayrollAnalysisViewEntry."Dimension 2 Value Code" := DimValue2;
        TempPayrollAnalysisViewEntry."Dimension 3 Value Code" := DimValue3;
        TempPayrollAnalysisViewEntry."Dimension 4 Value Code" := DimValue4;
        TempPayrollAnalysisViewEntry."Entry No." := EntryNo;

        if TempPayrollAnalysisViewEntry.Find then begin
            AddValue(TempPayrollAnalysisViewEntry."Payroll Amount", PayrollAmount);
            AddValue(TempPayrollAnalysisViewEntry."Taxable Amount", TaxableAmount);
        end else begin
            TempPayrollAnalysisViewEntry."Payroll Amount" := PayrollAmount;
            TempPayrollAnalysisViewEntry."Taxable Amount" := TaxableAmount;
            TempPayrollAnalysisViewEntry.Insert;
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewEntry;
    end;

    local procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        case DateCompression of
            PayrollAnalysisView."Date Compression"::Week:
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            PayrollAnalysisView."Date Compression"::Month:
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            PayrollAnalysisView."Date Compression"::Quarter:
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            PayrollAnalysisView."Date Compression"::Year:
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            PayrollAnalysisView."Date Compression"::Period:
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast then begin
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        end else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure FlushAnalysisViewEntry()
    begin
        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempPayrollAnalysisViewEntry.FindSet then
            repeat
                PayrollAnalysisViewEntry.Init;
                PayrollAnalysisViewEntry := TempPayrollAnalysisViewEntry;

                if not PayrollAnalysisViewEntry.Insert then begin
                    PayrollAnalysisViewEntry.Find;
                    AddValue(PayrollAnalysisViewEntry."Payroll Amount", TempPayrollAnalysisViewEntry."Payroll Amount");
                    AddValue(PayrollAnalysisViewEntry."Taxable Amount", TempPayrollAnalysisViewEntry."Taxable Amount");
                    PayrollAnalysisViewEntry.Modify;
                end;
            until TempPayrollAnalysisViewEntry.Next = 0;
        TempPayrollAnalysisViewEntry.DeleteAll;
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    local procedure InitWindow()
    begin
        Window.Open(
          Text005 +
          Text006 +
          Text009 +
          Text007 +
          Text008);
        Window.Update(6, Text010);
    end;

    local procedure UpdateWindowCounter(EntryNo: Integer)
    begin
        WinUpdateCounter := WinUpdateCounter + 1;
        WinTime2 := Time;
        if (WinTime2 > WinTime1 + 1000) or (EntryNo = WinLastEntryNo) then begin
            if WinLastEntryNo <> 0 then
                Window.Update(3, 100 * (100 * EntryNo div WinLastEntryNo));
            WinPrevEntryNo := EntryNo;
            WinTotalCounter := WinTotalCounter + WinUpdateCounter;
            if WinTime2 <> WinTime1 then
                Window.Update(4, Round(WinUpdateCounter * (1000 / (WinTime2 - WinTime1)), 1));
            if WinTime2 <> WinTime0 then
                Window.Update(5, Round(WinTotalCounter * (1000 / (WinTime2 - WinTime0)), 1));
            WinTime1 := WinTime2;
            WinUpdateCounter := 0;
        end;
    end;

    local procedure UpdateWindowHeader(TableID: Integer; EntryNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        WinLastEntryNo := EntryNo;
        WinPrevEntryNo := 0;
        WinTotalCounter := 0;
        AllObj.Get(AllObj."Object Type"::Table, TableID);
        Window.Update(1, PayrollAnalysisView.Code);
        Window.Update(2, AllObj."Object Name");
        Window.Update(3, 0);
        Window.Update(4, 0);
        Window.Update(5, 0);
        WinTime0 := Time;
        WinTime1 := WinTime0;
        WinTime2 := WinTime0;
    end;

    local procedure AddValue(var ToValue: Decimal; FromValue: Decimal)
    begin
        ToValue := ToValue + FromValue;
    end;

    local procedure IsValueIncludedInFilter(DimValue: Code[20]; DimFilter: Code[250]): Boolean
    begin
        with TempDimBuf do begin
            Reset;
            DeleteAll;
            Init;
            "Dimension Value Code" := DimValue;
            Insert;
            SetFilter("Dimension Value Code", DimFilter);
            exit(FindFirst);
        end;
    end;

    [Scope('OnPrem')]
    procedure DimSetIDInFilter(DimSetID: Integer; var PayrollAnalysisView: Record "Payroll Analysis View"): Boolean
    var
        InFilters: Boolean;
    begin
        if not FilterIsInitialized then begin
            TempDimEntryBuffer.DeleteAll;
            FilterIsInitialized := true;
            PayrollAnalysisViewFilter.SetRange("Analysis View Code", PayrollAnalysisView.Code);
            FiltersExist := not PayrollAnalysisViewFilter.IsEmpty;
        end;
        if not FiltersExist then
            exit(true);

        if TempDimEntryBuffer.Get(DimSetID) then  // cashed value?
            exit(TempDimEntryBuffer."Dimension Entry No." <> 0);

        InFilters := true;
        if PayrollAnalysisViewFilter.FindSet then
            repeat
                if DimSetEntry.Get(DimSetID, PayrollAnalysisViewFilter."Dimension Code") then
                    InFilters :=
                      InFilters and IsValueIncludedInFilter(DimSetEntry."Dimension Value Code", PayrollAnalysisViewFilter."Dimension Value Filter")
                else
                    InFilters :=
                      InFilters and IsValueIncludedInFilter('', PayrollAnalysisViewFilter."Dimension Value Filter");
            until (PayrollAnalysisViewFilter.Next = 0) or not InFilters;
        TempDimEntryBuffer."No." := DimSetID;
        if InFilters then
            TempDimEntryBuffer."Dimension Entry No." := 1
        else
            TempDimEntryBuffer."Dimension Entry No." := 0;
        TempDimEntryBuffer.Insert;
        exit(InFilters);
    end;
}

