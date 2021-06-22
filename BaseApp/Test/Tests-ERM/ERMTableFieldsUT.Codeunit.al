codeunit 134155 "ERM Table Fields UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        BalAccountNoConfirmTxt: Label 'The %1 %2 has a %3 %4.\\Do you still want to use %1 %2 in this journal line';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTablesUT: Codeunit "Library - Tables UT";

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustBalanceByDateFilter()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDate: Date;
        TotalAmount: Decimal;
    begin
        // [SCENARIO 217425] Flow field "Balance" of Customer does not depend on flow filter "Date Filter"

        LibrarySales.CreateCustomer(Customer);
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", WorkDate, WorkDate);
        TotalAmount += DetailedCustLedgEntry.Amount;
        NewDate := WorkDate + 1;
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", NewDate, NewDate);
        TotalAmount += DetailedCustLedgEntry.Amount;

        Customer.SetFilter("Date Filter", Format(NewDate));
        Customer.CalcFields(Balance);

        Customer.TestField(Balance, TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustBalanceLCYByDateFilter()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDate: Date;
        TotalAmount: Decimal;
    begin
        // [SCENARIO 217425] Flow field "Balance (LCY)" of Customer does not depend on flow filter "Date Filter"

        LibrarySales.CreateCustomer(Customer);
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", WorkDate, WorkDate);
        TotalAmount += DetailedCustLedgEntry."Amount (LCY)";
        NewDate := WorkDate + 1;
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", NewDate, NewDate);
        TotalAmount += DetailedCustLedgEntry."Amount (LCY)";

        Customer.SetFilter("Date Filter", Format(NewDate));
        Customer.CalcFields("Balance (LCY)");

        Customer.TestField("Balance (LCY)", TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustBalanceDueCalcOnMaxLimitOfDateFilter()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 210354] Customer Flow field "Balance Due" calculates given maximum limit of flow filter "Date Filter"

        LibrarySales.CreateCustomer(Customer);
        DueDate := CalcDate('<1M>', WorkDate);
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", WorkDate, DueDate);
        ExpectedAmount := DetailedCustLedgEntry.Amount;
        NewDate := DueDate + 1;
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", NewDate, CalcDate('<1M>', NewDate));

        Customer.SetFilter("Date Filter", Format(NewDate));
        Customer.CalcFields("Balance Due");

        Customer.TestField("Balance Due", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustBalanceDueLCYCalcOnMaxLimitOfDateFilter()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 210354] Customer Flow field "Balance Due (LCY)" calculates given maximum limit of flow filter "Date Filter"

        LibrarySales.CreateCustomer(Customer);
        DueDate := CalcDate('<1M>', WorkDate);
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", WorkDate, DueDate);
        ExpectedAmount := DetailedCustLedgEntry."Amount (LCY)";
        NewDate := DueDate + 1;
        MockDtldCustLedgEntry(DetailedCustLedgEntry, Customer."No.", NewDate, CalcDate('<1M>', NewDate));

        Customer.SetFilter("Date Filter", Format(NewDate));
        Customer.CalcFields("Balance Due (LCY)");

        Customer.TestField("Balance Due (LCY)", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VendorBalanceDueCalcOnMaxLimitOfDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 230505] Vendor Flow field "Balance Due" calculates given maximum limit of flow filter "Date Filter"

        LibraryPurchase.CreateVendor(Vendor);

        DueDate := CalcDate('<1M>', WorkDate);
        MockDtldVendLedgEntry(DetailedVendLedgEntry, Vendor."No.", WorkDate, DueDate);
        ExpectedAmount := -DetailedVendLedgEntry.Amount;
        NewDate := DueDate + 1;
        MockDtldVendLedgEntry(DetailedVendLedgEntry, Vendor."No.", NewDate, CalcDate('<1M>', NewDate));

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields("Balance Due");

        Vendor.TestField("Balance Due", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VendorBalanceDueLCYCalcOnMaxLimitOfDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 230505] Vendor Flow field "Balance Due (LCY)" calculates given maximum limit of flow filter "Date Filter"

        LibraryPurchase.CreateVendor(Vendor);

        DueDate := CalcDate('<1M>', WorkDate);
        MockDtldVendLedgEntry(DetailedVendLedgEntry, Vendor."No.", WorkDate, DueDate);
        ExpectedAmount := -DetailedVendLedgEntry."Amount (LCY)";
        NewDate := DueDate + 1;
        MockDtldVendLedgEntry(DetailedVendLedgEntry, Vendor."No.", NewDate, CalcDate('<1M>', NewDate));

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields("Balance Due (LCY)");

        Vendor.TestField("Balance Due (LCY)", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB310_Lookup_Drilldown_PageIDs()
    var
        TableMetadata: Record "Table Metadata";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 260580] "No. Series Relationship" table has Lookup and Dilldown Page ID = PAGE::"No. Series Relationships"
        TableMetadata.Get(DATABASE::"No. Series Relationship");
        TableMetadata.TestField(LookupPageID, PAGE::"No. Series Relationships");
        TableMetadata.TestField(DrillDownPageId, PAGE::"No. Series Relationships");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElectronicDocumentFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [FEATURE] [Electronic Document]
        // [SCENARIO 269611] Stan can see captions of specified codeunits in Electronic Document Format
        ElectronicDocumentFormat."Codeunit ID" := CODEUNIT::"Type Helper";
        ElectronicDocumentFormat."Delivery Codeunit ID" := CODEUNIT::"Sales-Post";

        ElectronicDocumentFormat.CalcFields("Codeunit Caption", "Delivery Codeunit Caption");

        ElectronicDocumentFormat.TestField("Codeunit Caption", 'Type Helper');
        ElectronicDocumentFormat.TestField("Delivery Codeunit Caption", 'Sales-Post');
    end;

    [Test]
    [HandlerFunctions('VerifyingConfirmHandler')]
    [Scope('OnPrem')]
    procedure TAB81_BalAccountNoCustomerWithConfirm()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [General Journal] [Customer]
        // [SCENARIO 271769] System shows confirmation dialog when Cassies tries to specify balance customer with different customer in "Bill-to Customer No."
        GenJournalLine.Init;

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo);
        Customer.Modify(true);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            BalAccountNoConfirmTxt, Customer.TableCaption, Customer."No.",
            Customer.FieldCaption("Bill-to Customer No."), Customer."Bill-to Customer No."));
        LibraryVariableStorage.Enqueue(true);

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", Customer."No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB81_BalAccountNoCustomerHideConform()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [General Journal] [Customer]
        // [SCENARIO 271769] System does not show confirmation dialog when validation dialog are disabled and
        // [SCENARIO 271769] Cassies tries to specify balance customer with different customer in "Bill-to Customer No."
        GenJournalLine.Init;

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo);
        Customer.Modify(true);

        GenJournalLine.SetHideValidation(true);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", Customer."No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('VerifyingConfirmHandler')]
    [Scope('OnPrem')]
    procedure TAB81_BalAccountNoVendorWithConfirm()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [General Journal] [Vendor]
        // [SCENARIO 271769] System shows confirmation dialog when Cassies tries to specify balance vendor with different vendor in "Pay-to Vendor No."
        GenJournalLine.Init;

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo);
        Vendor.Modify(true);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            BalAccountNoConfirmTxt, Vendor.TableCaption, Vendor."No.",
            Vendor.FieldCaption("Pay-to Vendor No."), Vendor."Pay-to Vendor No."));
        LibraryVariableStorage.Enqueue(true);

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB81_BalAccountNoVendorHideConform()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [General Journal] [Vendor]
        // [SCENARIO 271769] System does not show confirmation dialog when validation dialog are disabled and
        // [SCENARIO 271769] Cassies tries to specify balance vendor with different customer in "Pay-to Vendor No."
        GenJournalLine.Init;

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo);
        Vendor.Modify(true);

        GenJournalLine.SetHideValidation(true);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAvgCostAdjmtEntryPointOnAccountingPeriodInsert()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
        PeriodStartingDate: Date;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] Average cost adjustment entry point is created when creating a new accounting period
        PeriodStartingDate := FindNextAccountingPeriodStartingDate;

        // [GIVEN] Item with a value entry on 01-01-2020
        MockItem(Item);
        MockValueEntry(Item."No.", PeriodStartingDate);

        // [WHEN] Create accounting period starting on 01-01-2020
        CreateAccountingPeriod(AccountingPeriod, PeriodStartingDate, true);

        // [THEN] Average cost adjustment entry point with valuation date "01-01-2020" is created
        VerifyAvgCostAdjmtEntryPoint(Item."No.", PeriodStartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAvgCostAdjmtEntryPointOnAccountingPeriodDelete()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] "Cost is Adjusted" is reset on item and average cost adjustment entry point when deleting an accounting period

        // [GIVEN] Accounting period with starting date "01-01-2020"
        CreateAccountingPeriod(AccountingPeriod, FindNextAccountingPeriodStartingDate, true);

        // [GIVEN] Item with a value entry on 01-01-2020
        MockItem(Item);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date");

        // [WHEN] Delete the accounting period
        AccountingPeriod.Delete(true);

        // [THEN] "Cost is Adjusted" in the item card is FALSE
        Item.Find;
        Item.TestField("Cost is Adjusted", false);

        // [THEN] "Cost is adjusted" in the avg. cost adjmt. entry point on 01-01-2020 is FALSE
        VerifyAvgCostAdjmtEntryPoint(Item."No.", AccountingPeriod."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAvgCostAdjmtEntryPointOnAccountingPeriodModify()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] "Cost is Adjusted" is reset on item and average cost adjustment entry point when modifying an accounting period

        // [GIVEN] Accounting period with starting date "01-01-2020"
        CreateAccountingPeriod(AccountingPeriod, FindNextAccountingPeriodStartingDate, true);

        // [GIVEN] Item with a value entry on 01-01-2020
        MockItem(Item);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date");

        // [WHEN] Change the name of the accounting period
        AccountingPeriod.Name :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(AccountingPeriod.Name)), 1, MaxStrLen(AccountingPeriod.Name));
        AccountingPeriod.Modify(true);

        // [THEN] "Cost is Adjusted" in the item card is FALSE
        Item.Find;
        Item.TestField("Cost is Adjusted", false);

        // [THEN] "Cost is adjusted" in the avg. cost adjmt. entry point on 01-01-2020 is FALSE
        VerifyAvgCostAdjmtEntryPoint(Item."No.", AccountingPeriod."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAvgCostAdjmtEntryPointOnAccountingPeriodRenameLaterNewDate()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
        PeriodStartingDate: Date;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] When changing the starting date of an acc. period to a later date, "Cost is Adjusted" is reset on item and all avg. cost adjmt. entry points that fall within the date range between the old and the new values

        // [GIVEN] Accounting period with starting date "01-01-2020"
        PeriodStartingDate := FindNextAccountingPeriodStartingDate;
        CreateAccountingPeriod(AccountingPeriod, PeriodStartingDate, true);

        // [GIVEN] Item with two value entries having valuation dates "01-01-2020" and "02-01-2020"
        MockItem(Item);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date");
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date" + 1);

        // [WHEN] Rename the accounting period by changing the starting date from 01-01-2020 to 02-01-2020
        Commit;
        AccountingPeriod.Rename(AccountingPeriod."Starting Date" + 1);

        // [THEN] "Cost is Adjusted" in the item card is FALSE
        Item.Find;
        Item.TestField("Cost is Adjusted", false);

        // [THEN] "Cost is adjusted" is FALSE in both average cost adjustment entry points
        VerifyAvgCostAdjmtEntryPoint(Item."No.", PeriodStartingDate);
        VerifyAvgCostAdjmtEntryPoint(Item."No.", PeriodStartingDate + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAvgCostAdjmtEntryPointOnAccountingPeriodRenameEarlierNewDate()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
        PeriodStartingDate: Date;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] When changing the starting date of an acc. period to an earlier date, "Cost is Adjusted" is reset on item and all avg. cost adjmt. entry points that fall within the date range between the old and the new values

        // [GIVEN] Accounting period with starting date "01-01-2020"
        PeriodStartingDate := FindNextAccountingPeriodStartingDate;
        CreateAccountingPeriod(AccountingPeriod, PeriodStartingDate, true);

        // [GIVEN] Item with two value entries having valuation dates "31-12-2019" and "01-01-2020"
        MockItem(Item);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date" - 1);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date");

        // [WHEN] Rename the accounting period by changing the starting date from 01-01-2020 to 31-12-2019
        AccountingPeriod.Rename(AccountingPeriod."Starting Date" - 1);

        // [THEN] "Cost is Adjusted" in the item card is FALSE
        Item.Find;
        Item.TestField("Cost is Adjusted", false);

        // [THEN] "Cost is adjusted" is FALSE in both average cost adjustment entry points
        VerifyAvgCostAdjmtEntryPoint(Item."No.", PeriodStartingDate - 1);
        VerifyAvgCostAdjmtEntryPoint(Item."No.", PeriodStartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgCostAdjmtEntryPointNotUpdatedOnAccountingPeriodRenameNotNewFY()
    var
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
    begin
        // [FEATURE] [Accounting Period]
        // [SCENARIO 273709] "Cost is Adjusted" is not reset when changing the starting date of an accounting period that does not start new financial year

        // [GIVEN] Accounting period with starting date "01-02-2020" which is not a new financial year
        CreateAccountingPeriod(AccountingPeriod, FindNextAccountingPeriodStartingDate, false);

        // [GIVEN] Item with a value entries on 01-02-2020
        MockItem(Item);
        MockValueEntry(Item."No.", AccountingPeriod."Starting Date");

        // [WHEN] Change the starting date of the accounting period to "02-02-2020"
        AccountingPeriod.Rename(AccountingPeriod."Starting Date" + 1);

        // [THEN] "Cost is Adjusted" in the item card is TRUE
        Item.Find;
        Item.TestField("Cost is Adjusted", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntryFieldBalAccountTypeHasOptionEmployee()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRefValue: Text;
    begin
        // [FEATURE] [Bank Account Ledger Entry] [Employee]
        // [SCENARIO 277076] Bal. Account Type has option Employee in Bank Account Ledger Entry

        // [GIVEN] Bank Account Ledger Entry with "Bal. Account Type" = Employee
        BankAccountLedgerEntry.Init;
        BankAccountLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bal. Account Type" := BankAccountLedgerEntry."Bal. Account Type"::Employee;
        BankAccountLedgerEntry.Insert;

        // [GIVEN] FieldRef to "Bal. Account Type" field
        RecRef.GetTable(BankAccountLedgerEntry);
        FieldRef := RecRef.Field(BankAccountLedgerEntry.FieldNo("Bal. Account Type"));

        // [WHEN] Read value of of FieldRef
        FieldRefValue := Format(FieldRef);

        // [THEN] FieldRef value = 'Employee'
        Assert.AreEqual('Employee', FieldRefValue, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingTariffNoForIntrastatJnlLineWithItemNo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNumber: Record "Tariff Number";
    begin
        // [FEATURE] [Intrastat]
        // [SCENARIO 304876] It is possible to change "Tariff No." for Intrastat Journal Line with not empty "Item No."

        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.Validate("Item No.", LibraryInventory.CreateItemNo);
        TariffNumber.Init;
        TariffNumber."No." := LibraryUtility.GenerateRandomCode20(TariffNumber.FieldNo("No."), DATABASE::"Tariff Number");
        TariffNumber.Insert;

        IntrastatJnlLine.Validate("Tariff No.", TariffNumber."No.");

        IntrastatJnlLine.TestField("Tariff No.", TariffNumber."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvHeaderBuyfromAddressLength()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 319361] Length of "Purch. Inv. Header"."Buy-from Address" is equal to length of "Purchase Header"."Buy-from Address".
        LibraryTablesUT.CompareFieldTypeAndLength(
          PurchInvHeader,
          PurchInvHeader.FieldNo("Buy-from Address"),
          PurchaseHeader,
          PurchaseHeader.FieldNo("Buy-from Address"));
    end;

    local procedure CreateAccountingPeriod(var AccountingPeriod: Record "Accounting Period"; StartingDate: Date; IsNewFiscalYear: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get;
        AccountingPeriod."Starting Date" := StartingDate;
        AccountingPeriod."New Fiscal Year" := IsNewFiscalYear;
        AccountingPeriod."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
        AccountingPeriod."Average Cost Period" := InventorySetup."Average Cost Period";
        AccountingPeriod.Insert(true);
    end;

    local procedure FindNextAccountingPeriodStartingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.FindLast then;
        exit(CalcDate('<-CM+1M>', AccountingPeriod."Starting Date"));
    end;

    local procedure MockDtldCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustNo: Code[20]; PostingDate: Date; InitialEntryDueDate: Date)
    begin
        with DetailedCustLedgEntry do begin
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Customer No." := CustNo;
            "Posting Date" := PostingDate;
            "Initial Entry Due Date" := InitialEntryDueDate;
            Amount := LibraryRandom.RandDec(100, 2);
            "Amount (LCY)" := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure MockDtldVendLedgEntry(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendNo: Code[20]; PostingDate: Date; InitialEntryDueDate: Date)
    begin
        with DetailedVendLedgEntry do begin
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedVendLedgEntry, FieldNo("Entry No."));
            "Vendor No." := VendNo;
            "Posting Date" := PostingDate;
            "Initial Entry Due Date" := InitialEntryDueDate;
            Amount := LibraryRandom.RandDec(100, 2);
            "Amount (LCY)" := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure MockItem(var Item: Record Item)
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        Clear(Item);
        Item."No." := NoSeriesManagement.GetNextNo(LibraryUtility.GetGlobalNoSeriesCode, WorkDate, true);
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Cost is Adjusted" := true;
        Item.Insert;
    end;

    local procedure MockValueEntry(ItemNo: Code[20]; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Valuation Date" := ValuationDate;
        ValueEntry.Insert;
    end;

    local procedure VerifyAvgCostAdjmtEntryPoint(ItemNo: Code[20]; ValuationDate: Date)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        with AvgCostAdjmtEntryPoint do begin
            SetRange("Item No.", ItemNo);
            SetRange("Valuation Date", ValuationDate);
            FindFirst;
            TestField("Cost Is Adjusted", false);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VerifyingConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Question);
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;
}

