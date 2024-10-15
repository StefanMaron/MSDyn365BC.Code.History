codeunit 144126 "UT TAB Miscellaneous"
{
    // 1.  Purpose of the test is to validate OnValidate - DirectComponentsAmount Trigger of Table Before Start Item Cost(12133).
    // 2.  Purpose of the test is to validate OnValidate - SubcontractedAmount Trigger of Table Before Start Item Cost(12133).
    // 3.  Purpose of the test is to validate OnValidate - DirectRoutingAmount Trigger of Table Before Start Item Cost(12133).
    // 4.  Purpose of the test is to validate OnValidate - OverheadRoutingAmount Trigger of Table Before Start Item Cost(12133).
    // 5.  Purpose of the test is to validate OnDelete Trigger of Table Bill(12180).
    // 6.  Purpose of the test is to validate OnDelete Trigger of Table Contribution Bracket(12108).
    // 7.  Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173).
    // 8.  Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173) when To-Date conflicts with another period.
    // 9.  Purpose of the test is to validate OnDelete Trigger of Table Contribution Code(12106).
    // 10. Purpose of the test is to validate OnDelete Trigger of Table Withhold Code(12104).
    // 11. Purpose of the test is to validate OnValidate - SourceWithholdingTax Trigger of Table Withhold Code(12104).
    // 12. Purpose of the test is to validate OnValidate - RecipientMayReportIncome Trigger of Table Withhold Code(12104).
    // 13. Purpose of the test is to validate OnAfterGetRecord - CustomerBill Trigger of Report List of Bank Receipts(12170).
    // 14. Purpose of the test is to validate OnValidate - DueDatePaymentLine Trigger of Table Payment Line(12170).
    // 15. Purpose of the test is to validate OnValidate - PrepmtDueDatePaymentLine Trigger of Table Payment Line(12170).
    // 16. Purpose of the test is to validate OnValidate - BankAccountNo Trigger of Table Vendor Bill Header(12181).
    // 17. Purpose of the test is to validate OnValidate - ListDate Trigger of Table Vendor Bill Header(12181).
    // 18. Purpose of the test is to validate OnValidate - CurrencyCode Trigger of Table Vendor Bill Header(12181).
    // 
    // Covers Test Cases for WI - 345563
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // -------------------------------------------------------------------------------------------------------
    // OnValidateDirectCompsAmtBeforeStartItemCost, OnValidateSubContrdAmtBeforeStartItemCost
    // OnValidateDirectRoutingAmtBeforeStartItemCost, OnValidateOverheadRoutingAmtBeforeStartItemCost    278245
    // OnDeleteBillError                                                                                 278236
    // OnDeleteContributionBracket                                                                       278105
    // OnInsertDeferringDueDatesError, OnInsertToDateDeferringDueDatesError                              278369
    // OnDeleteContributionCode                                                                          278487
    // OnDeleteWithholdCode, OnValidateSourceWithholdingTaxWithholdCode                                  279350
    // OnValidateRecipientMayReportIncomeWithholdCode                                                    278157
    // OnAfterGetRecordCustomerBillLineListOfBankRcpt                                                    278275
    // OnValidateDueDatePaymentLineError, OnValidatePrepmtDueDatePaymentLineError                        278748
    // OnValidateBankAccountNoVendorBillHeaderError                                                      279687
    // OnValidateListDateVendorBillHeaderError                                                           279682
    // OnValidateCurrencyCodeVendorBillHeaderError                                                       279511

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DialogCap: Label 'Dialog';
        DisablingFieldMsg: Label 'Disabling the Source-Withholding Tax field will also disable the Recipient May Report Income field. Do you want to continue?';
        RecipientMayReportMsg: Label 'You cannot set the Recipient May Report Income field if the Source-Withholding Tax field is disabled.';
        RecordExistErr: Label 'Record must not exist.';
        ValueMatchErr: Label 'Values must match.';
        LibraryTablesUT: Codeunit "Library - Tables UT";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDirectCompsAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - DirectComponentsAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize;
        BeforeStartItemCost."Direct Routing Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Direct Components Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Direct Components Amount" + BeforeStartItemCost."Direct Routing Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSubContrdAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - SubcontractedAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize;
        BeforeStartItemCost."Direct Components Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Subcontracted Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Direct Components Amount" + BeforeStartItemCost."Subcontracted Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDirectRoutingAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - DirectRoutingAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize;
        BeforeStartItemCost."Overhead Routing Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Direct Routing Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Overhead Routing Amount" + BeforeStartItemCost."Direct Routing Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateOverheadRoutingAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - OverheadRoutingAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize;
        BeforeStartItemCost."Subcontracted Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Overhead Routing Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Overhead Routing Amount" + BeforeStartItemCost."Subcontracted Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteBillError()
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Bill(12180).
        // Setup.
        Initialize;
        Bill.Code := LibraryUTUtility.GetNewCode;
        Bill.Insert;
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10;
        PaymentMethod."Bill Code" := Bill.Code;
        PaymentMethod.Insert;

        // Exercise.
        asserterror Bill.Delete(true);

        // Verify actual error: "You cannot delete Bill because there are one or more payment methods for this code."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteContributionBracket()
    var
        ContributionBracketLine: Record "Contribution Bracket Line";
        ContributionBracket: Record "Contribution Bracket";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Contribution Bracket(12108).
        // Setup.
        Initialize;
        ContributionBracket.Code := LibraryUTUtility.GetNewCode10;
        ContributionBracket.Insert;
        ContributionBracketLine.Code := ContributionBracket.Code;
        ContributionBracketLine.Insert;

        // Exercise.
        ContributionBracket.Delete(true);

        // Verify: Verify ContributionBracketLine is deleted successfully.
        ContributionBracketLine.SetRange(Code, ContributionBracket.Code);
        Assert.IsTrue(ContributionBracketLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertDeferringDueDatesError()
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173).
        // Setup.
        Initialize;
        DeferringDueDates."No." := CreateDeferringDueDates;
        DeferringDueDates."From-Date" := WorkDate;

        // Exercise.
        asserterror DeferringDueDates.Insert(true);

        // Verify actual error: "From-Date conflicts with another period in Deferring Due Dates."
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertToDateDeferringDueDatesError()
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173) when To-Date conflicts with another period.
        // Setup.
        Initialize;
        DeferringDueDates."No." := CreateDeferringDueDates;
        DeferringDueDates."From-Date" := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate);
        DeferringDueDates."To-Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate);

        // Exercise.
        asserterror DeferringDueDates.Insert(true);

        // Verify actual error: "To-Date conflicts with another period in Deferring Due Dates."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteContributionCode()
    var
        ContributionCode: Record "Contribution Code";
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Contribution Code(12106).
        // Setup.
        Initialize;
        ContributionCode.Code := LibraryUTUtility.GetNewCode;
        ContributionCode.Insert;
        ContributionCodeLine.Code := ContributionCode.Code;
        ContributionCodeLine.Insert;

        // Exercise.
        ContributionCode.Delete(true);

        // Verify: Verify ContributionCodeLine is deleted successfully.
        ContributionCodeLine.SetRange(Code, ContributionCode.Code);
        Assert.IsTrue(ContributionCodeLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize;
        WithholdCode.Code := LibraryUTUtility.GetNewCode;
        WithholdCode.Insert;
        WithholdCodeLine."Withhold Code" := WithholdCode.Code;
        WithholdCodeLine.Insert;

        // Exercise.
        WithholdCode.Delete(true);

        // Verify: Verify WithholdCodeLine is deleted successfully.
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode.Code);
        Assert.IsTrue(WithholdCodeLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSourceWithholdingTaxWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
    begin
        // Purpose of the test is to validate OnValidate - SourceWithholdingTax Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize;
        WithholdCode.Code := LibraryUTUtility.GetNewCode;
        WithholdCode."Recipient May Report Income" := true;

        // Exercise.
        WithholdCode.Validate("Source-Withholding Tax", false);

        // Verify: Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateRecipientMayReportIncomeWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
    begin
        // Purpose of the test is to validate OnValidate - RecipientMayReportIncome Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize;
        WithholdCode.Code := LibraryUTUtility.GetNewCode;

        // Exercise.
        WithholdCode.Validate("Recipient May Report Income", true);

        // Verify: Verification done in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ListOfBankReceiptsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerBillLineListOfBankRcpt()
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - CustomerBill Trigger of Report List of Bank Receipts(12170).
        // Setup.
        Initialize;
        CreateCustomerBill(CustomerBillLine);
        LibraryVariableStorage.Enqueue(CustomerBillLine."Customer Bill No.");  // Enqueue for ListOfBankReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"List of Bank Receipts");

        // Verify: Verify values of No_CustBillHdr, CustNo_CustBillLine on Report List of Bank Receipts(12170).
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_CustBillHdr', CustomerBillLine."Customer Bill No.");
        LibraryReportDataset.AssertElementWithValueExists('CustNo_CustBillLine', CustomerBillLine."Customer No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDueDatePaymentLineError()
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Purpose of the test is to validate OnValidate - DueDatePaymentLine Trigger of Table Payment Line(12170).
        // Setup.
        Initialize;
        CreatePaymentLine(PaymentLines, PaymentLines."Sales/Purchase"::Sales, CreateSalesHeader);

        // Exercise.
        asserterror PaymentLines.Validate("Due Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Verify actual error: "Due Date must be greater than or equal to Document Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtDueDatePaymentLineError()
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Purpose of the test is to validate OnValidate - PrepmtDueDatePaymentLine Trigger of Table Payment Line(12170).
        // Setup.
        Initialize;
        CreatePaymentLine(PaymentLines, PaymentLines."Sales/Purchase"::Purchase, CreatePurchaseHeader);

        // Exercise.
        asserterror
          PaymentLines.Validate("Pmt. Discount Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Verify actual error: "Pmt. Discount Date must be greater than or equal to Document Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBankAccountNoVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - BankAccountNo Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize;
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode;

        // Exercise.
        asserterror VendorBillHeader.Validate("Bank Account No.", CreateBankAccount(true));  // Blocekd as True.

        // Verify actual error: "Bank Account No. is blocked."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateListDateVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - ListDate Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize;
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode;
        VendorBillHeader."Posting Date" := WorkDate;

        // Exercise.
        asserterror VendorBillHeader.Validate("List Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Verify actual error: "List Date must not be greater than Posting Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCurrencyCodeVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - CurrencyCode Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize;
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode;

        // Exercise.
        asserterror VendorBillHeader.Validate("Currency Code", LibraryUTUtility.GetNewCode10);

        // Verify actual error: "It's not possible to change Currency Code because there are Vendor Bill Line associated to this Vendor Bill Header."
        Assert.ExpectedErrorCode('DB:PrimRecordNotFound');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccountLengthOfSalesInvoiceHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 304160] Length of "Sales Invoice Header"."Bank Account" must be equal to lenght of "Sales Header"."Bank Account"
        Initialize;

        LibraryTablesUT.CompareFieldTypeAndLength(
          SalesHeader, SalesHeader.FieldNo("Bank Account"),
          SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bank Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccountLengthOfServiceInvoiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 304160] Length of "Service Invoice Header"."Bank Account" must be equal to lenght of "Service Header"."Bank Account"
        Initialize;

        LibraryTablesUT.CompareFieldTypeAndLength(
          ServiceHeader, ServiceHeader.FieldNo("Bank Account"),
          ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Bank Account"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateBankAccount(Blocked: Boolean): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Blocked := Blocked;
        BankAccount.Insert;
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Insert;
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBill(var CustomerBillLine: Record "Customer Bill Line")
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        CustomerBillHeader."No." := LibraryUTUtility.GetNewCode;
        CustomerBillHeader."Bank Account No." := CreateBankAccount(false);  // Blocked as false.
        CustomerBillHeader.Insert;
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine."Customer No." := CreateCustomer;
        CustomerBillLine.Insert;
    end;

    local procedure CreateDeferringDueDates(): Code[20]
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        DeferringDueDates."No." := LibraryUTUtility.GetNewCode;
        DeferringDueDates."From-Date" := WorkDate;
        DeferringDueDates."To-Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);  // Use random Date.
        DeferringDueDates.Insert;
        exit(DeferringDueDates."No.");
    end;

    local procedure CreatePaymentLine(var PaymentLines: Record "Payment Lines"; SalesPurchase: Option; "Code": Code[20])
    begin
        PaymentLines."Sales/Purchase" := SalesPurchase;
        PaymentLines.Type := PaymentLines.Type::Order;
        PaymentLines.Code := Code;
        PaymentLines.Insert;
    end;

    local procedure CreatePurchaseHeader(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode;
        PurchaseHeader."Document Date" := WorkDate;
        PurchaseHeader.Insert;
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesHeader(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode;
        SalesHeader."Document Date" := WorkDate;
        SalesHeader.Insert;
        exit(SalesHeader."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, StrSubstNo(DisablingFieldMsg), ValueMatchErr);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(Message, StrSubstNo(RecipientMayReportMsg), ValueMatchErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ListOfBankReceiptsRequestPageHandler(var ListOfBankReceipts: TestRequestPage "List of Bank Receipts")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ListOfBankReceipts."Customer Bill Header".SetFilter("No.", No);
        ListOfBankReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

