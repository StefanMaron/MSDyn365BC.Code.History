#if not CLEAN25
codeunit 142081 "UT PAG Vendor 1099"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IRS1099CodeDiv: Label 'DIV-08';
        IRS1099CodeInt: Label 'INT-05';
        IRS1099CodeMisc: Label 'MISC-02';
        Assert: Codeunit Assert;
        CodeDIV01B: Label 'DIV-01-B';
        AmtCodesErr: Label 'Wrong AmtCodes value';

    [Test]
    [HandlerFunctions('Vendor1099StatisticsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendor1099()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor 1099 Statistics]
        // Purpose is to test OnAfterGetRecord trigger of Page 10016 - Vendor 1099 Statistics.

        // Setup: Create Vendor and Detailed Leger Entry.
        Initialize();
        CreateMultipleVendorLedgerEntry(VendorLedgerEntry);
        VendorCard.OpenEdit;
        VendorCard.FILTER.SetFilter("No.", VendorLedgerEntry."Vendor No.");

        // [WHEN] Open "Vendor 1099 Statistics" page
        VendorCard."1099 Statistics".Invoke;

        // Verify: Amount verifying in Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunAPMagneticMediaManagement()
    var
        APMagneticMediaManagement: Codeunit "A/P Magnetic Media Management";
        CodeNos: Text;
        i: Integer;
    begin
        // [FEATURE] [A/P Magnetic Media]
        // Purpose is to test Codeunit 10085 A/P Magnetic Media Management On Run trigger and AmtCodes function.

        // Setup.
        Initialize();
        i := LibraryRandom.RandIntInRange(2, 10);
        APMagneticMediaManagement.Run();

        // [WHEN] run AmtCodes()
        APMagneticMediaManagement.AmtCodes(CodeNos, i, i);  // Value is not required for CodeNos.

        // Verify: Purpose for exercise is to execute the Amt Codes function Sucessfully.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "VerifyAmtCodes_DIV-01-B"()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        APMagneticMediaManagement: Codeunit "A/P Magnetic Media Management";
        CodeNos: Text[12];
        FormType: Integer;
        EndLine: Integer;
    begin
        // [FEATURE] [A/P Magnetic Media]
        // Verify AmtCodes returned by Codeunit 10085 A/P Magnetic Media Management
        // in case of 'DIV-01-B' non-zero amount
        Initialize();

        FormType := 2; // DIV type
        EndLine := 30; // AmtCodes array length

        APMagneticMediaManagement.Run();
        APMagneticMediaManagement.UpdateLines(VendorLedgerEntry, FormType, EndLine, CodeDIV01B, LibraryRandom.RandDec(1000, 2));
        // [WHEN] run AmtCodes()
        APMagneticMediaManagement.AmtCodes(CodeNos, FormType, EndLine);

        Assert.AreEqual('12', CodeNos, AmtCodesErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedVendLedgerEntryNo: Integer; EntryType: Option; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;  // Adding 1 to take next Entry No.
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedVendLedgerEntryNo;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount;
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Insert(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Option; VendorNo: Code[20]; IRS1099Code: Code[10]; IRSAmount: Decimal)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;  // Adding 1 to take next Entry No.
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."IRS 1099 Code" := IRS1099Code;
        VendorLedgerEntry."IRS 1099 Amount" := -IRSAmount;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateMultipleVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        Amount := 100 * LibraryRandom.RandInt(10);  // Using Random value for Amount.
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, CreateVendor, IRS1099CodeDiv, Amount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Vendor No.", IRS1099CodeDiv, Amount);
        CreateMultipleDetailedVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry2, Amount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Vendor No.", IRS1099CodeInt, Amount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Vendor No.", IRS1099CodeInt, Amount);
        CreateMultipleDetailedVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry2, Amount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc, Amount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc, Amount);
        CreateMultipleDetailedVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry2, Amount);
        LibraryVariableStorage.Enqueue(3 * Amount);  // Enqueue Vendor1099StatisticsPageHandler
    end;

    local procedure CreateMultipleDetailedVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry2: Record "Vendor Ledger Entry"; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry, 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry", -Amount);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry2, 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry", Amount);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application, Amount);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application, -Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099StatisticsPageHandler(var Vendor1099Statistics: TestPage "Vendor 1099 Statistics")
    var
        Amounts: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amounts);
        Vendor1099Statistics."Amounts[1]".AssertEquals(Amounts);
        Vendor1099Statistics.OK.Invoke;
    end;
}
#endif
