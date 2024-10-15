codeunit 144057 "UT COD Telebank"
{
    // // [FEATURE] [Telebank] [UT]
    //  1. Test to verify that Transaction Mode Code and Bank Account Code are same on Customer Ledger Entry after running Cust. Entry-Edit.
    //  2. Test to verify that Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
    // 
    //  Covers Test Cases for WI - 343638
    //  ------------------------------------------------------
    //  Test Function Name                             TFS ID
    //  ------------------------------------------------------
    //  OnRunCustomerEntryEdit
    //  OnRunVendorEntryEdit

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryHumanResource: Codeunit "Library - Human Resource";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunCustomerEntryEdit()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::103, Cust. Entry-Edit.

        // Setup: Create Customer, create Customer Ledger Entry.
        CreateCustomer(Customer);
        CreateCustomerLedgerEntry(CustLedgerEntry, Customer."No.", Customer."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);

        // Verify: Verify that Transaction Mode Code and Bank Account Code are same on Customer Ledger Entry after running Cust. Entry-Edit.
        CustLedgerEntry2.SetRange("Document No.", CustLedgerEntry."Document No.");
        CustLedgerEntry2.FindFirst;
        CustLedgerEntry2.TestField("Transaction Mode Code", CustLedgerEntry."Transaction Mode Code");
        CustLedgerEntry2.TestField("Recipient Bank Account", CustLedgerEntry."Recipient Bank Account");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunVendorEntryEdit()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::113, Vend. Entry-Edit.

        // Setup: Create Vendor, create Vendor Ledger Entry.
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", Vendor."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);

        // Verify: Verify the Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
        VendorLedgerEntry2.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VendorLedgerEntry2.FindFirst;
        VendorLedgerEntry2.TestField("Transaction Mode Code", VendorLedgerEntry."Transaction Mode Code");
        VendorLedgerEntry2.TestField("Recipient Bank Account", VendorLedgerEntry."Recipient Bank Account");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunEmployeeEntryEdit()
    var
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::113, Vend. Entry-Edit.

        // Setup: Create Vendor, create Vendor Ledger Entry.
        CreateEmployee(Employee);
        CreateEmployeeLedgerEntry(EmployeeLedgerEntry, Employee."No.", Employee."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgerEntry);

        // Verify: Verify the Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
        EmployeeLedgerEntry2.SetRange("Document No.", EmployeeLedgerEntry."Document No.");
        EmployeeLedgerEntry2.FindFirst;
        EmployeeLedgerEntry2.TestField("Transaction Mode Code", EmployeeLedgerEntry."Transaction Mode Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunSEPACTPrepareSource()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        PaymentHistoryLine: Record "Payment History Line";
        AppliesToDocNo: Code[20];
    begin
        CreatePaymentHistoryLines(PaymentHistoryLine, AppliesToDocNo);

        // Exercise.
        TempGenJnlLine.SetRange("Bal. Account No.", PaymentHistoryLine."Our Bank");
        TempGenJnlLine.SetRange("Document No.", PaymentHistoryLine."Run No.");
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Prepare Source", TempGenJnlLine);

        // Verify.
        VerifyTempJnlLineVsPmtHistoryLine(TempGenJnlLine, PaymentHistoryLine, AppliesToDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLinesAreUpdatedWithStatusPostedAfterSetApplyCVLedgerEntriesWithPost()
    var
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
    begin
        // [SCENARIO 209402] COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() updates "Detail Line".Status from "In process" to "Posted"
        // [SCENARIO 209402] in case of Post = TRUE and several detail lines

        // [GIVEN] Payment History Line with several related Detail Lines with Status = "In process"
        CreatePaymentHistoryLineWithTwoDetailLines(PaymentHistoryLine, DetailLine);

        // [WHEN] Perform COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() with Post = TRUE
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        Assert.RecordCount(DetailLine, 2);
        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistoryLine, '', true, false);

        // [THEN] Detail Lines are updated with Status = "Posted"
        Assert.RecordIsEmpty(DetailLine);
        DetailLine.SetRange(Status, DetailLine.Status::Posted);
        Assert.RecordCount(DetailLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLinesAreNotUpdatedWithStatusPostedAfterSetApplyCVLedgerEntriesWithoutPost()
    var
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
    begin
        // [SCENARIO 209402] COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() doesn't update "Detail Line".Status from "In process" to "Posted"
        // [SCENARIO 209402] in case of Post = FALSE and several detail lines

        // [GIVEN] Payment History Line with several related Detail Lines with Status = "In process"
        CreatePaymentHistoryLineWithTwoDetailLines(PaymentHistoryLine, DetailLine);

        // [WHEN] Perform COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() with Post = FALSE
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        Assert.RecordCount(DetailLine, 2);
        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistoryLine, '', false, false);

        // [THEN] Detail Lines are updated with Status = "Posted"
        Assert.RecordCount(DetailLine, 2);
        DetailLine.SetRange(Status, DetailLine.Status::Posted);
        Assert.RecordIsEmpty(DetailLine);
    end;

    local procedure CreatePaymentHistoryLineWithTwoDetailLines(var PaymentHistoryLine: Record "Payment History Line"; var DetailLine: Record "Detail Line")
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PaymentHistory: Record "Payment History";
    begin
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry[1], Vendor."No.", Vendor."Transaction Mode Code");
        CreateVendorLedgerEntry(VendorLedgerEntry[2], Vendor."No.", Vendor."Transaction Mode Code");

        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory);
        MockDetailLine(DetailLine, PaymentHistoryLine, VendorLedgerEntry[1]."Entry No.");
        MockDetailLine(DetailLine, PaymentHistoryLine, VendorLedgerEntry[2]."Entry No.");

        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Customer);
        Customer.Insert;
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; TransactionModeCode: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry2.FindLast then
            CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1
        else
            CustLedgerEntry."Entry No." := 1;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        CustLedgerEntry."Recipient Bank Account" := LibraryUTUtility.GetNewCode10;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert;
    end;

    local procedure CreatePaymentHistoryLines(var PaymentHistoryLine: Record "Payment History Line"; var AppliesToDocNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
        DetailLine: Record "Detail Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        MockPaymentHistory(PaymentHistory);

        with PaymentHistoryLine do begin
            MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory);

            // second line
            "Line No." += 1;
            "Account Type" := "Account Type"::Vendor;
            Insert;

            VendLedgEntry.SetFilter("External Document No.", '<>%1', '');
            VendLedgEntry.FindFirst;
            AppliesToDocNo := VendLedgEntry."External Document No.";
            MockDetailLine(DetailLine, PaymentHistoryLine, VendLedgEntry."Entry No.");

            SetRange("Our Bank", PaymentHistory."Our Bank");
            SetRange("Run No.", PaymentHistory."Run No.");
        end;
    end;

    local procedure CreateTransactionMode(AccountType: Option): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.Code := LibraryUTUtility.GetNewCode;
        TransactionMode."Account Type" := AccountType;
        TransactionMode.Insert;
        exit(TransactionMode.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Vendor);
        Vendor.Insert;
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; TransactionModeCode: Code[20])
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry2.FindLast then
            VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1
        else
            VendorLedgerEntry."Entry No." := 1;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        VendorLedgerEntry."Recipient Bank Account" := LibraryUTUtility.GetNewCode10;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert;
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        Employee."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Employee);
        Employee.Modify(true);
    end;

    local procedure CreateEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeNo: Code[20]; TransactionModeCode: Code[20])
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        if EmployeeLedgerEntry2.FindLast then
            EmployeeLedgerEntry."Entry No." := EmployeeLedgerEntry2."Entry No." + 1
        else
            EmployeeLedgerEntry."Entry No." := 1;
        EmployeeLedgerEntry."Document No." := LibraryUTUtility.GetNewCode;
        EmployeeLedgerEntry."Employee No." := EmployeeNo;
        EmployeeLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Insert;
    end;

    local procedure MockPaymentHistory(var PaymentHistory: Record "Payment History")
    begin
        with PaymentHistory do begin
            Init;
            "Our Bank" := LibraryUTUtility.GetNewCode;
            "Run No." := LibraryUTUtility.GetNewCode;
            Insert;
        end;
    end;

    local procedure MockPaymentHistoryLine(var PaymentHistoryLine: Record "Payment History Line"; PaymentHistory: Record "Payment History")
    begin
        with PaymentHistoryLine do begin
            Init;
            "Our Bank" := PaymentHistory."Our Bank";
            "Run No." := PaymentHistory."Run No.";
            "Line No." := 1;
            "Account Type" := "Account Type"::Customer;
            "Account No." := LibraryUTUtility.GetNewCode;
            Date := WorkDate;
            Amount := 1;
            Bank := LibraryUTUtility.GetNewCode10;
            "Currency Code" := LibraryUTUtility.GetNewCode10;
            "Description 1" := LibraryUTUtility.GetNewCode;
            Insert;
        end;
    end;

    local procedure MockDetailLine(var DetailLine: Record "Detail Line"; PaymentHistoryLine: Record "Payment History Line"; SerialNoEntry: Integer)
    begin
        with DetailLine do begin
            Init;
            "Transaction No." := LibraryUtility.GetNewRecNo(DetailLine, FieldNo("Transaction No."));
            "Our Bank" := PaymentHistoryLine."Our Bank";
            Status := Status::"In process";
            "Connect Batches" := PaymentHistoryLine."Run No.";
            "Connect Lines" := PaymentHistoryLine."Line No.";
            "Account Type" := "Account Type"::Vendor;
            "Serial No. (Entry)" := SerialNoEntry;
            Insert;
        end;
    end;

    local procedure VerifyTempJnlLineVsPmtHistoryLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var PaymentHistoryLine: Record "Payment History Line"; AppliesToDocNo: Code[20])
    var
        DocumentType: Option;
    begin
        with TempGenJnlLine do begin
            Assert.AreEqual(PaymentHistoryLine.Count, Count, 'Wrong count');
            PaymentHistoryLine.FindSet;
            FindSet;
            repeat
                Assert.AreEqual('', "Journal Template Name", FieldName("Journal Template Name"));
                Assert.AreEqual('', "Journal Batch Name", FieldName("Journal Batch Name"));
                Assert.AreEqual("Bal. Account Type"::"Bank Account", "Bal. Account Type", FieldName("Bal. Account Type"));
                Assert.AreEqual(PaymentHistoryLine."Our Bank", "Bal. Account No.", FieldName("Bal. Account No."));
                Assert.AreEqual(PaymentHistoryLine."Run No.", "Document No.", FieldName("Document No."));
                Assert.AreEqual(PaymentHistoryLine."Line No.", "Line No.", FieldName("Line No."));
                Assert.AreEqual(PaymentHistoryLine."Account Type" + 1, "Account Type", FieldName("Account Type"));
                if "Account Type" = "Account Type"::Customer then
                    DocumentType := "Document Type"::Refund
                else
                    DocumentType := "Document Type"::Payment;
                Assert.AreEqual(DocumentType, "Document Type", FieldName("Document Type"));
                Assert.AreEqual(PaymentHistoryLine."Account No.", "Account No.", FieldName("Account No."));
                Assert.AreEqual(PaymentHistoryLine.Date, "Posting Date", FieldName("Posting Date"));
                Assert.AreEqual(PaymentHistoryLine.Amount, Amount, FieldName(Amount));
                Assert.AreEqual(PaymentHistoryLine."Currency Code", "Currency Code", FieldName("Currency Code"));
                Assert.AreEqual(PaymentHistoryLine.Bank, "Recipient Bank Account", FieldName("Recipient Bank Account"));
                if "Account Type" = "Account Type"::Vendor then
                    PaymentHistoryLine."Description 1" := AppliesToDocNo;
                Assert.AreEqual(PaymentHistoryLine."Description 1", Description, FieldName(Description));
                PaymentHistoryLine.Next;
            until Next = 0;
        end;
    end;
}

