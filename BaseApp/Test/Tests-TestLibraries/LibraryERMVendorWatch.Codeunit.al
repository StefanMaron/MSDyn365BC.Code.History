codeunit 131320 "Library - ERM Vendor Watch"
{

    trigger OnRun()
    begin
    end;

    var
        WatchVendor: Record "Watch Vendor";
        WatchVendorLedgerEntry: Record "Watch Vendor Ledger Entry";
        Assert: Codeunit Assert;
        Tolerance: Decimal;

    [Scope('OnPrem')]
    procedure Init()
    begin
        Tolerance := 0.0;
        WatchVendor.Reset();
        WatchVendor.DeleteAll();
        WatchVendorLedgerEntry.Reset();
        WatchVendorLedgerEntry.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure WatchVendorEntry(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean; LECompareMethod: Option; DtldLECompareMethod: Option)
    begin
        with WatchVendor do begin
            Init();
            "Line No." := NextLineNo;
            "Vendor No." := VendorNo;

            "Original LE Count" := LedgerEntryTotal(VendorNo);
            "Original Dtld. LE Count" := DtldLedgerEntryTotal(VendorNo);
            "Watch LE" := WatchLETotal;
            "Watch Dtld. LE" := WatchDtldLETotal;
            "LE Comparison Method" := LECompareMethod;
            "Dtld. LE Comparison Method" := DtldLECompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure VendorEqual(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::Equal,
          WatchVendor."Dtld. LE Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure VendorGreaterThan(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::"Greater Than",
          WatchVendor."Dtld. LE Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure VendorLessThan(VendorNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchVendorEntry(VendorNo, WatchLETotal, WatchDtldLETotal,
          WatchVendor."LE Comparison Method"::"Less Than",
          WatchVendor."Dtld. LE Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchLedgerEntries(VendorNo: Code[20]; EntryType: Option; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        with WatchVendorLedgerEntry do begin
            Init();
            "Line No." := NextLELineNo;
            "Vendor No." := VendorNo;
            "Line Level" := "Line Level"::"Ledger Entry";
            "Line Type" := EntryType;

            "Original Count" := LedgerEntryCount(VendorNo, EntryType);
            "Delta Count" := DeltaCount;
            "Original Sum" := LedgerEntrySum(VendorNo, EntryType);
            "Delta Sum" := DeltaSum;
            "Count Comparison Method" := CountCompareMethod;
            "Sum Comparison Method" := SumCompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EntriesEqual(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EntriesGreaterThan(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EntriesLessThan(VendorNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchDtldLedgerEntries(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        with WatchVendorLedgerEntry do begin
            Init();
            "Line No." := NextLELineNo;
            "Vendor No." := VendorNo;
            "Line Level" := "Line Level"::"Detailed Ledger Entry";
            "Line Type" := EntryType.AsInteger();

            "Original Count" := DtldLedgerEntryCount(VendorNo, EntryType);
            "Delta Count" := DeltaCount;
            "Original Sum" := DtldLedgerEntrySum(VendorNo, EntryType);
            "Delta Sum" := DeltaSum;
            "Count Comparison Method" := CountCompareMethod;
            "Sum Comparison Method" := SumCompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesSigned(Sign: Decimal; VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        if Sign = 0 then
            DtldEntriesEqual(VendorNo, EntryType, DeltaSum)
        else
            if Sign > 0 then
                DtldEntriesGreaterThan(VendorNo, EntryType, DeltaSum)
            else
                DtldEntriesLessThan(VendorNo, EntryType, DeltaSum);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesEqual(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesGreaterThan(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesLessThan(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(VendorNo, EntryType, 1, DeltaSum,
          WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    local procedure AssertLedgerEntry(WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry")
    begin
        with WatchVendorLedgerEntry2 do begin
            DeltaCompareCount(
              "Original Count",
              "Delta Count",
              LedgerEntryCount("Vendor No.", "Line Type"),
              "Count Comparison Method",
              'Incorrect ledger entry count, vendor: ' + "Vendor No." + ', line type: ' + Format("Line Type"));

            DeltaCompareSum(
              "Original Sum",
              "Delta Sum",
              LedgerEntrySum("Vendor No.", "Line Type"),
              "Sum Comparison Method",
              'Incorrect ledger entry sum, vendor: ' + "Vendor No." + ', line type: ' + Format("Line Type"));
        end;
    end;

    local procedure AssertDtldLedgerEntry(WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry")
    begin
        with WatchVendorLedgerEntry2 do begin
            DeltaCompareCount(
              "Original Count",
              "Delta Count",
              DtldLedgerEntryCount("Vendor No.", "Detailed CV Ledger Entry Type".FromInteger("Line Type")),
              "Count Comparison Method",
              'Incorrect detailed ledger entry count, vendor: ' + "Vendor No." + ', line type: ' + Format("Line Type"));

            DeltaCompareSum(
              "Original Sum",
              "Delta Sum",
              DtldLedgerEntrySum("Vendor No.", "Detailed CV Ledger Entry Type".FromInteger("Line Type")),
              "Sum Comparison Method",
              'Incorrect detailed ledger entry sum, vendor: ' + "Vendor No." + ', line type: ' + Format("Line Type"));
        end;
    end;

    [Scope('OnPrem')]
    procedure AssertVendor()
    var
        TotalLEDelta: Integer;
        TotalDtldLEDelta: Integer;
    begin
        TotalLEDelta := 0;
        TotalDtldLEDelta := 0;

        with WatchVendorLedgerEntry do begin
            Reset();

            if FindSet() then
                repeat
                    if "Line Level" = "Line Level"::"Ledger Entry" then begin
                        TotalLEDelta += "Delta Count";
                        AssertLedgerEntry(WatchVendorLedgerEntry)
                    end else begin
                        TotalDtldLEDelta += "Delta Count";
                        AssertDtldLedgerEntry(WatchVendorLedgerEntry);
                    end;
                until Next = 0;
        end;

        with WatchVendor do begin
            Reset();
            if FindFirst() then begin
                // Check that all ledger entries are accounted for
                if "Watch LE" then
                    DeltaCompareCount("Original LE Count", TotalLEDelta, LedgerEntryTotal("Vendor No."), "LE Comparison Method",
                      'There are unaccounted for ledger entries');

                // Check that all detailed ledger entries are accounted for
                if "Watch Dtld. LE" then
                    DeltaCompareCount(
                      "Original Dtld. LE Count", TotalDtldLEDelta, DtldLedgerEntryTotal("Vendor No."), "Dtld. LE Comparison Method"
                      , 'There are unaccounted for detailed ledger entries');
            end;
        end;
    end;

    local procedure DeltaCompareCount(Original: Integer; Delta: Integer; Total: Integer; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchVendorLedgerEntry."Count Comparison Method"::Equal:
                Assert.AreEqual(Original + Delta, Total, ErrorMsg);
            WatchVendorLedgerEntry."Count Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchVendorLedgerEntry."Count Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure DeltaCompareSum(Original: Decimal; Delta: Decimal; Total: Decimal; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchVendorLedgerEntry."Sum Comparison Method"::Equal:
                Assert.AreNearlyEqual(Original + Delta, Total, Tolerance, ErrorMsg);
            WatchVendorLedgerEntry."Sum Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchVendorLedgerEntry."Sum Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure LedgerEntryTotal(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntryTotal(VendorNo: Code[20]): Integer
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        if DtldVendorLedgEntry.FindFirst() then
            exit(DtldVendorLedgEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntryCount(VendorNo: Code[20]; LineType: Option): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", LineType);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntrySum(VendorNo: Code[20]; LineType: Option) "Sum": Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", LineType);
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields(Amount);
                Sum += VendorLedgerEntry.Amount;
            until VendorLedgerEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure DtldLedgerEntryCount(VendorNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type"): Integer
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DtldVendorLedgEntry.SetRange("Entry Type", LineType);
        if DtldVendorLedgEntry.FindFirst() then
            exit(DtldVendorLedgEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntrySum(VendorNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type") "Sum": Decimal
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendorLedgEntry.Reset();
        DtldVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DtldVendorLedgEntry.SetRange("Entry Type", LineType);
        if DtldVendorLedgEntry.FindSet() then
            repeat
                Sum += DtldVendorLedgEntry.Amount;
            until DtldVendorLedgEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure NextLineNo(): Integer
    var
        WatchVendor2: Record "Watch Vendor";
    begin
        if WatchVendor2.FindLast() then
            exit(WatchVendor2."Line No." + 1);
        exit(1);
    end;

    local procedure NextLELineNo(): Integer
    var
        WatchVendorLedgerEntry2: Record "Watch Vendor Ledger Entry";
    begin
        if WatchVendorLedgerEntry2.FindLast() then
            exit(WatchVendorLedgerEntry2."Line No." + 1);
        exit(1);
    end;
}

