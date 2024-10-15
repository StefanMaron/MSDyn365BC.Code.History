codeunit 135407 "Prepayments Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Prepayments] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;
        TeamMemberErr: Label 'You are logged in as a Team Member role, so you cannot complete this task.';

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsBusinessManager()
    var
        TempCustomerDetails: Record Customer temporary;
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize;
        // [GIVEN] An item
        ItemNo := CreateItem;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsExternalAccountant()
    var
        TempCustomerDetails: Record Customer temporary;
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize;
        // [GIVEN] An item
        ItemNo := CreateItem;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] A user with External Accountant Plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsTeamMember()
    var
        TempCustomerDetails: Record Customer temporary;
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        asserterror CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsEssentialISVEmbUser()
    var
        TempCustomerDetails: Record Customer temporary;
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as an Essential ISV Emb User

        Initialize;
        // [GIVEN] An item
        ItemNo := CreateItem;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] A user with Essential ISV Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsTeamMemberISVEmb()
    var
        TempCustomerDetails: Record Customer temporary;
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Team Member ISV Emb

        Initialize;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);
        Commit();

        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        asserterror CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsDeviceISVEmbUser()
    var
        TempCustomerDetails: Record Customer temporary;
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as an Device ISV Emb User

        Initialize;
        // [GIVEN] An item
        ItemNo := CreateItem;
        FindCustomerPostingAndVATSetup(TempCustomerDetails);
        // [GIVEN] A user with Device ISV Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan;
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent, TempCustomerDetails);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsBusinessManager()
    var
        TempVendorDetails: Record Vendor temporary;
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as a Business Manager

        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);

        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsExternalAccountant()
    var
        TempVendorDetails: Record Vendor temporary;
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as a Business Manager

        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A user with External Accountant Plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);

        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsTeamMember()
    var
        TempVendorDetails: Record Vendor temporary;
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as a Business Manager

        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        asserterror CreatePurchaseOrder(VendorNo, ItemNo);
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        ErrorMessagesPage.Trap();
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, true);
        // [THEN] Posting should not be allowed by Team Member
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan;
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);
        LibraryE2EPlanPermissions.SetTeamMemberPlan;
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsEssentialISVEmbUser()
    var
        TempVendorDetails: Record Vendor temporary;
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as Essential ISV Emb

        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A user with Essential ISV Emb Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);

        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsTeamMemberISVEmb()
    var
        TempVendorDetails: Record Vendor temporary;
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as a Team Member ISV Emb
        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);
        Commit();

        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        asserterror CreatePurchaseOrder(VendorNo, ItemNo);
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        ErrorMessagesPage.Trap();
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, true);
        // [THEN] Posting should not be allowed by Team Member
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan;
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan;
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler,ConfirmHandlerYes,PostedPurchInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInPurchOrderAsDeviceISVEmbUser()
    var
        TempVendorDetails: Record Vendor temporary;
        PrepaymentPercent: Decimal;
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchaseOrderNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Purchase Order containing Prepayments as Device ISV Emb

        Initialize;
        FindVendorPostingAndVATSetup(TempVendorDetails);
        // [GIVEN] An item
        ItemNo := CreateItem;
        // [GIVEN] A user with Device ISV Emb Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan;
        // [GIVEN] A vendor with a Prepayment Setup
        VendorNo := CreateVendor(PrepaymentPercent, TempVendorDetails);

        // [WHEN] A purchase order is created, the lines are automatically filled with a prepayment amount
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo);
        // [WHEN] The prepayment invoice and the purchase order are posted
        PostPurchOrderPrepayments(PurchaseOrderNo);
        PostedPurchaseInvoiceNo := PostPurchOrder(PurchaseOrderNo, false);
        // [THEN] The posted purchase invoice contains lines deducting the prepayment amount
        VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo, PrepaymentPercent);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Prepayments Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
        LibraryVariableStorage.Clear;

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Prepayments Plan-based E2E");

        LibraryTemplates.DisableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings;
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.DisableWarningOnCloseUnpostedDoc;

        LibraryERMCountryData.CreateVATData;

        CreateSalesPrepmtInvNosInSetup;
        SetupNewSalesPrepaymentAccount;
        CreatePurchPrepmtInvNosInSetup;
        SetupNewPurchPrepaymentAccount;

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Prepayments Plan-based E2E");
    end;

    local procedure CreateSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) SalesOrderNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenNew;
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesOrder.SalesLines.New;
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 10));
        SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        SalesOrderNo := SalesOrder."No.".Value;
        SalesOrder.OK.Invoke;
    end;

    local procedure CreatePurchaseOrder(VendorNo: Code[20]; ItemNo: Code[20]) PurchaseOrderNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenNew;
        PurchaseOrder."Buy-from Vendor Name".SetValue(VendorNo);
        PurchaseOrder."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID);
        PurchaseOrder.PurchLines.New;
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseOrder.PurchLines."No.".SetValue(ItemNo);
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 10));
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        PurchaseOrderNo := PurchaseOrder."No.".Value;
        PurchaseOrder.OK.Invoke;
    end;

    local procedure PostSalesOrderPrepayments(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit;
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.PostPrepaymentInvoice.Invoke;
        SalesOrder.Close;
    end;

    local procedure PostSalesOrder(SalesOrderNo: Code[20]; ExpectFailure: Boolean) PostedSalesOrderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit;
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.Post.Invoke;
        if not ExpectFailure then
            PostedSalesOrderNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(PostedSalesOrderNo));
    end;

    local procedure PostPurchOrderPrepayments(PurchaseOrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoKey(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        PurchaseOrder.PostPrepaymentInvoice.Invoke;
        PurchaseOrder.Close;
    end;

    local procedure PostPurchOrder(PurchaseOrderNo: Code[20]; ExpectFailure: Boolean) PostedPurchaseOrderNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoKey(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        PurchaseOrder."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID);
        PurchaseOrder.Post.Invoke;
        if not ExpectFailure then
            PostedPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(PostedPurchaseOrderNo));
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew;
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value;
        ItemCard.OK.Invoke;
        Commit();
    end;

    local procedure CreateVendor(var PrepaymentPercentage: Decimal; TempVendorDetails: Record Vendor temporary) VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        PrepaymentPercentage := LibraryRandom.RandDecInRange(1, 100, 2);
        VendorCard.OpenNew;
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorCard."Gen. Bus. Posting Group".SetValue(TempVendorDetails."Gen. Bus. Posting Group");
        VendorCard."VAT Bus. Posting Group".SetValue(TempVendorDetails."VAT Bus. Posting Group");
        VendorCard."Vendor Posting Group".SetValue(TempVendorDetails."Vendor Posting Group");
        VendorCard."Prepayment %".SetValue(PrepaymentPercentage);
        VendorNo := VendorCard."No.".Value;
        VendorCard.OK.Invoke;
        Commit();
    end;

    local procedure CreateCustomer(var PrepaymentPercentage: Decimal; TempCustomerDetails: Record Customer temporary) CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        PrepaymentPercentage := LibraryRandom.RandDecInRange(1, 100, 2);
        CustomerCard.OpenNew;
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerCard."Gen. Bus. Posting Group".SetValue(TempCustomerDetails."Gen. Bus. Posting Group");
        CustomerCard."VAT Bus. Posting Group".SetValue(TempCustomerDetails."VAT Bus. Posting Group");
        CustomerCard."Customer Posting Group".SetValue(TempCustomerDetails."Customer Posting Group");
        CustomerCard."Prepayment %".SetValue(PrepaymentPercentage);
        CustomerNo := CustomerCard."No.".Value;
        CustomerCard.OK.Invoke;
        Commit();
    end;

    local procedure FindVendorPostingAndVATSetup(var TempVendorDetails: Record Vendor temporary)
    begin
        TempVendorDetails.Init();
        FindBusPostingGroups(TempVendorDetails."Gen. Bus. Posting Group", TempVendorDetails."VAT Bus. Posting Group");
        TempVendorDetails."Vendor Posting Group" := LibraryPurchase.FindVendorPostingGroup;
    end;

    local procedure FindCustomerPostingAndVATSetup(var TempCustomerDetails: Record Customer temporary)
    begin
        TempCustomerDetails.Init();
        FindBusPostingGroups(TempCustomerDetails."Gen. Bus. Posting Group", TempCustomerDetails."VAT Bus. Posting Group");
        TempCustomerDetails."Customer Posting Group" := LibrarySales.FindCustomerPostingGroup;
    end;

    local procedure FindBusPostingGroups(var GenBusPostingGroup: Code[20]; var VATBusPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        GenBusPostingGroup := GeneralPostingSetup."Gen. Bus. Posting Group";

        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        VATBusPostingGroup := VATPostingSetup."VAT Bus. Posting Group";
    end;

    local procedure VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo: Code[20]; ExpectedPrepaymentPercentage: Decimal)
    var
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PrepaymentAmount: Decimal;
        ItemLineAmount: Decimal;
        ExpectedPrepaymentAmount: Decimal;
    begin
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoKey(PostedSalesInvoiceNo);
        PostedSalesInvoice.SalesInvLines.Next;
        Assert.AreEqual(Format(SalesLine.Type::Item), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(ItemLineAmount, PostedSalesInvoice.SalesInvLines."Line Amount".Value), 'Evaluate Failed On Item Line Amount');
        ExpectedPrepaymentAmount := -ItemLineAmount * ExpectedPrepaymentPercentage / 100.0;
        PostedSalesInvoice.SalesInvLines.Next;
        Assert.AreEqual(Format(SalesLine.Type::"G/L Account"), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(PrepaymentAmount, PostedSalesInvoice.SalesInvLines."Line Amount".Value), 'Evaluate Failed On Prepayment Amount');
        Assert.AreNotEqual(0.0, PrepaymentAmount, '');
        Assert.AreNearlyEqual(ExpectedPrepaymentAmount, PrepaymentAmount, 0.01, '');
        PostedSalesInvoice.OK.Invoke;
    end;

    local procedure VerifyPostedPurchInvoicePrepayment(PostedPurchaseInvoiceNo: Code[20]; ExpectedPrepaymentPercentage: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PrepaymentAmount: Decimal;
        ItemLineAmount: Decimal;
        ExpectedPrepaymentAmount: Decimal;
    begin
        PostedPurchaseInvoice.OpenEdit;
        PostedPurchaseInvoice.GotoKey(PostedPurchaseInvoiceNo);
        PostedPurchaseInvoice.PurchInvLines.Next;
        Assert.AreEqual(Format(PurchaseLine.Type::Item), PostedPurchaseInvoice.PurchInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(ItemLineAmount, PostedPurchaseInvoice.PurchInvLines."Line Amount".Value), 'Evaluate Failed On Item Line Amount');
        ExpectedPrepaymentAmount := -ItemLineAmount * ExpectedPrepaymentPercentage / 100.0;
        PostedPurchaseInvoice.PurchInvLines.Next;
        Assert.AreEqual(Format(PurchaseLine.Type::"G/L Account"), PostedPurchaseInvoice.PurchInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(PrepaymentAmount, PostedPurchaseInvoice.PurchInvLines."Line Amount".Value), 'Evaluate Failed On Prepayment Amount');
        Assert.AreNotEqual(0.0, PrepaymentAmount, '');
        Assert.AreNearlyEqual(ExpectedPrepaymentAmount, PrepaymentAmount, 0.01, '');
        PostedPurchaseInvoice.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesModalPageHandler(var ConfigTemplates: TestPage "Config Templates")
    begin
        ConfigTemplates.First;
        ConfigTemplates.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OrderPostActionHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3 // Receive/Ship & Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value);
        PostedSalesInvoice.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedPurchaseInvoice."No.".Value);
        PostedPurchaseInvoice.Close;
    end;

    local procedure CreateSalesPrepmtInvNosInSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetupNewSalesPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup;
        GeneralPostingSetup.FindSet;
        repeat
            AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, GLAccountNo);
        until GeneralPostingSetup.Next = 0;
    end;

    local procedure AttachSalesPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; SalesPrepaymentsAccount: Code[20]) SalesPrepaymentsAccountOld: Code[20]
    begin
        SalesPrepaymentsAccountOld := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePurchPrepmtInvNosInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Prepmt. Inv. Nos.", PurchasesPayablesSetup."Posted Invoice Nos.");
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetupNewPurchPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup;
        GeneralPostingSetup.FindSet;
        repeat
            AttachPurchPrepaymentAccountInSetup(GeneralPostingSetup, GLAccountNo);
        until GeneralPostingSetup.Next = 0;
    end;

    local procedure AttachPurchPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; PurchPrepaymentsAccount: Code[20]) PurchPrepaymentsAccountOld: Code[20]
    begin
        PurchPrepaymentsAccountOld := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;
}

