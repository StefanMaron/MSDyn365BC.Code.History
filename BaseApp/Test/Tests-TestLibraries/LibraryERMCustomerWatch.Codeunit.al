codeunit 131310 "Library - ERM Customer Watch"
{

    trigger OnRun()
    begin
    end;

    var
        WatchCustomer: Record "Watch Customer";
        WatchCustLedgerEntry: Record "Watch Customer Ledger Entry";
        Assert: Codeunit Assert;
        Tolerance: Decimal;

    [Scope('OnPrem')]
    procedure Init()
    begin
        Tolerance := 0.0;
        WatchCustomer.Reset();
        WatchCustomer.DeleteAll();
        WatchCustLedgerEntry.Reset();
        WatchCustLedgerEntry.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure WatchCustomerEntry(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean; LECompareMethod: Option; DtldLECompareMethod: Option)
    begin
        with WatchCustomer do begin
            Init();
            "Line No." := NextLineNo;
            "Customer No." := CustomerNo;

            "Original LE Count" := LedgerEntryTotal(CustomerNo);
            "Original Dtld. LE Count" := DtldLedgerEntryTotal(CustomerNo);
            "Watch LE" := WatchLETotal;
            "Watch Dtld. LE" := WatchDtldLETotal;
            "LE Comparison Method" := LECompareMethod;
            "Dtld. LE Comparison Method" := DtldLECompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CustomerEqual(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::Equal,
          WatchCustomer."Dtld. LE Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure CustomerGreaterThan(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::"Greater Than",
          WatchCustomer."Dtld. LE Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure CustomerLessThan(CustomerNo: Code[20]; WatchLETotal: Boolean; WatchDtldLETotal: Boolean)
    begin
        WatchCustomerEntry(CustomerNo, WatchLETotal, WatchDtldLETotal,
          WatchCustomer."LE Comparison Method"::"Less Than",
          WatchCustomer."Dtld. LE Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchLedgerEntries(CustomerNo: Code[20]; EntryType: Option; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        with WatchCustLedgerEntry do begin
            Init();
            "Line No." := NextLELineNo;
            "Customer No." := CustomerNo;
            "Line Level" := "Line Level"::"Ledger Entry";
            "Line Type" := EntryType;

            "Original Count" := LedgerEntryCount(CustomerNo, EntryType);
            "Delta Count" := DeltaCount;
            "Original Sum" := LedgerEntrySum(CustomerNo, EntryType);
            "Delta Sum" := DeltaSum;
            "Count Comparison Method" := CountCompareMethod;
            "Sum Comparison Method" := SumCompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EntriesEqual(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure EntriesGreaterThan(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure EntriesLessThan(CustomerNo: Code[20]; EntryType: Option; DeltaSum: Decimal)
    begin
        WatchLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    [Scope('OnPrem')]
    procedure WatchDtldLedgerEntries(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaCount: Integer; DeltaSum: Decimal; CountCompareMethod: Option; SumCompareMethod: Option)
    begin
        with WatchCustLedgerEntry do begin
            Init();
            "Line No." := NextLELineNo;
            "Customer No." := CustomerNo;
            "Line Level" := "Line Level"::"Detailed Ledger Entry";
            "Line Type" := EntryType.AsInteger();

            "Original Count" := DtldLedgerEntryCount(CustomerNo, EntryType);
            "Delta Count" := DeltaCount;
            "Original Sum" := DtldLedgerEntrySum(CustomerNo, EntryType);
            "Delta Sum" := DeltaSum;
            "Count Comparison Method" := CountCompareMethod;
            "Sum Comparison Method" := SumCompareMethod;

            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesSigned(Sign: Decimal; CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        if Sign = 0 then
            DtldEntriesEqual(CustomerNo, EntryType, DeltaSum)
        else
            if Sign > 0 then
                DtldEntriesGreaterThan(CustomerNo, EntryType, DeltaSum)
            else
                DtldEntriesLessThan(CustomerNo, EntryType, DeltaSum);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesEqual(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::Equal);
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesGreaterThan(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than");
    end;

    [Scope('OnPrem')]
    procedure DtldEntriesLessThan(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DeltaSum: Decimal)
    begin
        WatchDtldLedgerEntries(CustomerNo, EntryType, 1, DeltaSum,
          WatchCustLedgerEntry."Count Comparison Method"::"Greater Than",
          WatchCustLedgerEntry."Sum Comparison Method"::"Less Than");
    end;

    local procedure AssertLedgerEntry(WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry")
    begin
        with WatchCustLedgerEntry2 do begin
            DeltaCompareCount(
              "Original Count",
              "Delta Count",
              LedgerEntryCount("Customer No.", "Line Type"),
              "Count Comparison Method",
              'Incorrect ledger entry count, Customer: ' + "Customer No." + ', line type: ' + Format("Line Type"));

            DeltaCompareSum(
              "Original Sum",
              "Delta Sum",
              LedgerEntrySum("Customer No.", "Line Type"),
              "Sum Comparison Method",
              'Incorrect ledger entry sum, Customer: ' + "Customer No." + ', line type: ' + Format("Line Type"));
        end;
    end;

    local procedure AssertDtldLedgerEntry(WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry")
    begin
        with WatchCustLedgerEntry2 do begin
            DeltaCompareCount(
              "Original Count",
              "Delta Count",
              DtldLedgerEntryCount("Customer No.", "Detailed CV Ledger Entry Type".FromInteger("Line Type")),
              "Count Comparison Method",
              'Incorrect detailed ledger entry count, Customer: ' + "Customer No." + ', line type: ' + Format("Line Type"));

            DeltaCompareSum(
              "Original Sum",
              "Delta Sum",
              DtldLedgerEntrySum("Customer No.", "Detailed CV Ledger Entry Type".FromInteger("Line Type")),
              "Sum Comparison Method",
              'Incorrect detailed ledger entry sum, Customer: ' + "Customer No." + ', line type: ' + Format("Line Type"));
        end;
    end;

    [Scope('OnPrem')]
    procedure AssertCustomer()
    var
        TotalLEDelta: Integer;
        TotalDtldLEDelta: Integer;
    begin
        TotalLEDelta := 0;
        TotalDtldLEDelta := 0;

        with WatchCustLedgerEntry do begin
            Reset();

            if FindSet() then
                repeat
                    if "Line Level" = "Line Level"::"Ledger Entry" then begin
                        TotalLEDelta += "Delta Count";
                        AssertLedgerEntry(WatchCustLedgerEntry)
                    end else begin
                        TotalDtldLEDelta += "Delta Count";
                        AssertDtldLedgerEntry(WatchCustLedgerEntry);
                    end;
                until Next = 0;
        end;

        with WatchCustomer do begin
            Reset();
            if FindFirst() then begin
                // Check that all ledger entries are accounted for
                if "Watch LE" then
                    DeltaCompareCount("Original LE Count", TotalLEDelta, LedgerEntryTotal("Customer No."), "LE Comparison Method",
                      'There are unaccounted for ledger entries');

                // Check that all detailed ledger entries are accounted for
                if "Watch Dtld. LE" then
                    DeltaCompareCount(
                      "Original Dtld. LE Count", TotalDtldLEDelta, DtldLedgerEntryTotal("Customer No."), "Dtld. LE Comparison Method"
                      , 'There are unaccounted for detailed ledger entries');
            end;
        end;
    end;

    local procedure DeltaCompareCount(Original: Integer; Delta: Integer; Total: Integer; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchCustLedgerEntry."Count Comparison Method"::Equal:
                Assert.AreEqual(Original + Delta, Total, ErrorMsg);
            WatchCustLedgerEntry."Count Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchCustLedgerEntry."Count Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure DeltaCompareSum(Original: Decimal; Delta: Decimal; Total: Decimal; ComparisonMethod: Option; ErrorMsg: Text[250])
    begin
        ErrorMsg := ErrorMsg + ' [Original: ' + Format(Original) + ', Delta: ' + Format(Delta) + ', Total: ' + Format(Total) + ']';
        case ComparisonMethod of
            WatchCustLedgerEntry."Sum Comparison Method"::Equal:
                Assert.AreNearlyEqual(Original + Delta, Total, Tolerance, ErrorMsg);
            WatchCustLedgerEntry."Sum Comparison Method"::"Greater Than":
                Assert.IsTrue(Original + Delta <= Total, ErrorMsg);
            WatchCustLedgerEntry."Sum Comparison Method"::"Less Than":
                Assert.IsTrue(Original + Delta >= Total, ErrorMsg);
        end;
    end;

    local procedure LedgerEntryTotal(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntryTotal(CustomerNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        if DtldCustLedgEntry.FindFirst() then
            exit(DtldCustLedgEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntryCount(CustomerNo: Code[20]; LineType: Option): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", LineType);
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry.Count);
        exit(0);
    end;

    local procedure LedgerEntrySum(CustomerNo: Code[20]; LineType: Option) "Sum": Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", LineType);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.CalcFields(Amount);
                Sum += CustLedgerEntry.Amount;
            until CustLedgerEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure DtldLedgerEntryCount(CustomerNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type"): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DtldCustLedgEntry.SetRange("Entry Type", LineType);
        if DtldCustLedgEntry.FindFirst() then
            exit(DtldCustLedgEntry.Count);
        exit(0);
    end;

    local procedure DtldLedgerEntrySum(CustomerNo: Code[20]; LineType: Enum "Detailed CV Ledger Entry Type") "Sum": Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DtldCustLedgEntry.SetRange("Entry Type", LineType);
        if DtldCustLedgEntry.FindSet() then
            repeat
                Sum += DtldCustLedgEntry.Amount;
            until DtldCustLedgEntry.Next() = 0;

        exit(Sum);
    end;

    local procedure NextLineNo(): Integer
    var
        WatchCustomer2: Record "Watch Customer";
    begin
        if WatchCustomer2.FindLast() then
            exit(WatchCustomer2."Line No." + 1);
        exit(1);
    end;

    local procedure NextLELineNo(): Integer
    var
        WatchCustLedgerEntry2: Record "Watch Customer Ledger Entry";
    begin
        if WatchCustLedgerEntry2.FindLast() then
            exit(WatchCustLedgerEntry2."Line No." + 1);
        exit(1);
    end;
}

