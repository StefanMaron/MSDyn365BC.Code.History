codeunit 134564 "ERM Insert Std. Purch. Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Standard Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        ValueMustExistMsg: Label '%1 must exist.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        isInitialized: Boolean;
        InvalidNotificationIdMsg: Label 'Invalid notification ID';
        RefDocType: Option Quote,"Order",Invoice,"Credit Memo";
        RefMode: Option Manual,Automatic,"Always Ask";
        FieldNotVisibleErr: Label 'Field must be visible.';
        ResourceErr: Label 'Wrong values after validate from resource';

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Quote]
        // [SCENARIO] Purch lines are not created on quote validate Buy-from Vendor No. when where Insert Rec. Lines On Quotes = Manual
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Manual);
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Quote]
        // [SCENARIO] Recurring purchase line created on quote validate Buy-from Vendor No. when Insert Rec. Lines On Quotes = Automatic
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Automatic);
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Quote]
        // [SCENARIO] Standard codes notification created on quote validate Buy-from Vendor No. when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::"Always Ask");
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Quote]
        // [SCENARIO] Purch lines are not created on quote validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchCodesCancelQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Automatic mode] [Quote]
        // [SCENARIO] There is no purchase standard codes notification on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = Automatic
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);

        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = Automatic
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::Automatic, VendorNo);

        // [WHEN] Function GetPurchRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchCodesCancelQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Quote]
        // [SCENARIO] There is no purchase standard codes notification on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);

        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = "Always Ask"
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::"Always Ask", VendorNo);

        // [WHEN] Function GetPurchRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticMultiplePurchCodesQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Quote]
        // [SCENARIO] Purch lines created by GetPurchRecurringLines for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = Automatic
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);
        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = Automatic
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::Automatic, VendorNo);
        // [WHEN] StandardCodesMgt.GetPurchRecurringLines is being run
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] Purch line created with Item from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskMultiplePurchCodesQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Quote]
        // [SCENARIO] Purch lines created on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);
        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = "Always Ask"
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::"Always Ask", VendorNo);

        // [WHEN] StandardCodesMgt.GetPurchRecurringLines is being run
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] Purch line created with Item from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Order]
        // [SCENARIO] Purch lines are not created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = Manual
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Order]
        // [SCENARIO] Recurring purchase line created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = Automatic
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Order]
        // [SCENARIO] Standard codes notification created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::"Always Ask");
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Order]
        // [SCENARIO] Purch lines are not created on order validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Invoice]
        // [SCENARIO] Purch lines are not created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = Manual
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Manual);
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Invoice]
        // [SCENARIO] Recurring purchase line created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = Automatic
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Automatic);
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Invoice]
        // [SCENARIO] Standard codes notification created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::"Always Ask");
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] Purch lines are not created on invoice validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize;

        // [GIVEN] Vendor VEND without standard purch code
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Credit Memo]
        // [SCENARIO] Purch lines are not created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = Manual
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Manual);
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomatiPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Credit Memo]
        // [SCENARIO] Recurring purchase line created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = Automatic
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Automatic);
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Credit Memo]
        // [SCENARIO] Standard codes notification created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = "Always Ask"
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::"Always Ask");
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] Purch lines are not created on cr memo validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize;

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo;
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseOrderFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Automatic mode] [Order]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Order is created from Vendor List
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit;
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Order
        PurchaseOrder.Trap;
        VendorList.NewPurchaseOrder.Invoke;

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseOrder."Buy-from Vendor No.".Activate;
        PurchaseOrder.PurchLines.First;

        // [THEN] Standard purchase code notification created
        // Verify only notification ID due to test limitations
        VerifyPurchStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseInvoiceFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Automatic mode] [Invoice]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Invoice is created from Vendor List
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit;
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Invoice
        PurchaseInvoice.Trap;
        VendorList.NewPurchaseInvoice.Invoke;

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseInvoice."Buy-from Vendor No.".Activate;

        // [THEN] Standard purchase code notification created
        // Verify only notification ID due to test limitations
        VerifyPurchStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseQuoteFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Automatic mode] [Quote]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Quote is created from Vendor List
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit;
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Quote
        PurchaseQuote.Trap;
        VendorList.NewPurchaseQuote.Invoke;

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseQuote."Buy-from Vendor No.".Activate;

        // [THEN] Standard purchase code notification created
        // Verify only notification ID due to test limitations
        VerifyPurchStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseCreditMemoFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Automatic mode] [Credit Memo]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Credit Memo is created from Vendor List
        Initialize;

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit;
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Credit Memo
        PurchaseCreditMemo.Trap;
        VendorList.NewPurchaseCrMemo.Invoke;

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseCreditMemo."Buy-from Vendor No.".Activate;

        // [THEN] Standard purchase code notification created
        // Verify only notification ID due to test limitations
        VerifyPurchStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesFieldsVisibleForSuiteAppArea()
    var
        StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Standard Vendor Purchase Codes new fields are visible for application area #Suite

        // [GIVEN] Enable #suite application area
        LibraryApplicationArea.EnableFoundationSetup;

        // [WHEN] Open page Standard Vendor Purchase Codes
        StandardVendorPurchaseCodes.OpenEdit;

        // [THEN] Fields "Insert Rec Lines On..." are visible
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Quotes".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Orders".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Invoices".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Cr. Memos".Visible, FieldNotVisibleErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoPurchBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Blanket Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for blanket order
        Initialize;

        // [GIVEN] Vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new purchase blanket order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoPurchReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for return order
        Initialize;

        // [GIVEN] Vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new purchase return order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchCodeAndPurchOrderWithDifferentCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created when Standard Purchase Code currency code <> currency code of purchase document
        Initialize;

        // [GIVEN] Local currency vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);

        // [GIVEN] Set Currency Code = "XXX" for standard purchase code "AA"
        UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo, LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Create new purchase order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeNotificationOnCurrencyCodeValidate()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT] 
        // [SCENARIO 311677] Standard codes notification created when currency code of purchase document became same with Standard Purchase Code currency code
        Initialize;

        // [GIVEN] Local currency vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);

        // [GIVEN] Set Currency Code = "XXX" for standard purchase code "AA"
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo, CurrencyCode);

        // [GIVEN] Create new purchase order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [WHEN] Specify PurchaseHeader."Currency Code" = "XXX"
        PurchaseHeader.Validate("Currency Code", CurrencyCode);

        // [THEN] Standard Purchase code notification created
        Assert.AreEqual(PurchaseHeader."Document Type", LibraryVariableStorage.DequeueInteger, 'Unexpected document type');
        Assert.AreEqual(PurchaseHeader."No.", LibraryVariableStorage.DequeueText, 'Unexpected document number');
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeWithResource()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create standard purchase code with resource line
        Initialize();

        // [GIVEN] Resource
        LibraryResource.CreateResourceNew(Resource);

        // [WHEN] Create standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, Resource."No.");

        // [THEN] Standard purchase line values are filled from resource
        VerifyStandardPurchaseLineWithResource(StandardPurchaseLine, Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineFromStdPurchaseCodeWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create purchase line in purchase order from standard purchase code with resource
        Initialize();

        // [GIVEN] Standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, LibraryResource.CreateResourceNo());

        // [GIVEN] Purchase header (order)
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Standard vendor purchase code
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, PurchaseHeader."Buy-from Vendor No.", StandardPurchaseCode.Code);

        // [WHEN] Run StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines (this function run on "Get Recurring Purchase Line" action)
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Purchase line with resource is created from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('ResourceListPageHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseLineLookupNoResource()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." from standard puchase line with resource
        Initialize();

        // [GIVEN] Standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, LibraryResource.CreateResourceNo());

        // [WHEN] Lookup "No." from standard purchase line with resource
        StandardPurchaseCodeCard.OpenView();
        StandardPurchaseCodeCard.GoToRecord(StandardPurchaseCode);
        StandardPurchaseCodeCard.StdPurchaseLines."No.".Lookup();

        // [THEN] "Resource List" page opened (ResourceListPageHandler)
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");
        LibraryVariableStorage.Clear;
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc;
        LibraryNotificationMgt.ClearTemporaryNotificationContext;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");

        LibraryERMCountryData.CreateVATData;
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");
    end;

    local procedure CreateMultipleStandardVendorPurchaseCodesForVendor(DocType: Option; Mode: Integer; VendorNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateNewStandardVendorPurhcaseCodeForVendor(DocType, Mode, VendorNo);
    end;

    local procedure CreateNewStandardVendorPurhcaseCodeForVendor(DocType: Option; Mode: Integer; VendorNo: Code[20])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.Init();
        StandardVendorPurchaseCode."Vendor No." := VendorNo;
        StandardVendorPurchaseCode.Code := CreateStandardPurchaseCodeWithItemLine;
        case DocType of
            RefDocType::Quote:
                StandardVendorPurchaseCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardVendorPurchaseCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardVendorPurchaseCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardVendorPurchaseCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardVendorPurchaseCode.Insert();
        LibraryVariableStorage.Enqueue(StandardVendorPurchaseCode.Code);  // Enqueue value for StandardVendorPurchaseCodesModalPageHandler or StandardVendorPurchaseCodesCancelModalPageHandler.
    end;

    local procedure CreateStandardPurchaseCode(): Code[10]
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        exit(StandardPurchaseCode.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode;
        PurchaseHeader."Document Date" := WorkDate;
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchQuote(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
    end;

    local procedure CreatePurchInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
    end;

    local procedure CreatePurchCrMemo(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure CreateStandardPurchaseCodeWithItemLine(): Code[10]
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        StandardPurchaseLine."Standard Purchase Code" := CreateStandardPurchaseCode;
        StandardPurchaseLine.Type := StandardPurchaseLine.Type::Item;
        StandardPurchaseLine."No." := LibraryInventory.CreateItemNo;
        StandardPurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        StandardPurchaseLine.Insert();
        exit(StandardPurchaseLine."Standard Purchase Code");
    end;

    local procedure FilterOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
    end;

    local procedure FindStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; VendorNo: Code[20])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.SetRange("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.FindFirst;
        StandardPurchaseLine.SetRange("Standard Purchase Code", StandardVendorPurchaseCode.Code);
        StandardPurchaseLine.FindFirst;
    end;

    local procedure GetNewVendNoWithStandardPurchCode(DocType: Option; Mode: Integer): Code[20]
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.Init();
        StandardVendorPurchaseCode."Vendor No." := LibraryPurchase.CreateVendorNo;
        StandardVendorPurchaseCode.Code := CreateStandardPurchaseCodeWithItemLine;
        case DocType of
            RefDocType::Quote:
                StandardVendorPurchaseCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardVendorPurchaseCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardVendorPurchaseCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardVendorPurchaseCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardVendorPurchaseCode.Insert();

        LibraryVariableStorage.Enqueue(StandardVendorPurchaseCode.Code);  // Enqueue value for StandardVendorPurchaseCodesPageHandler or StandardVendorPurchaseCodesCancelPageHandler.
        exit(StandardVendorPurchaseCode."Vendor No.")
    end;

    local procedure SetPurchaseQuoteVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseQuote."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseInvoiceVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseInvoice."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseOrderVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseOrder."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseCreditMemoVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetBlanketPurchaseOrderVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.Filter.setfilter("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseReturnOrderVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure UpdatePurchHeaderBuyFromVendorNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Modify();
    end;

    local procedure UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        StandardVendorPurchaseCode.SetRange("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.FindFirst();
        StandardPurchaseCode.Get(StandardVendorPurchaseCode.Code);
        StandardPurchaseCode.Validate("Currency Code", CurrencyCode);
        StandardPurchaseCode.Modify();
    end;

    local procedure VerifyPurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        FilterOnPurchaseLine(PurchaseLine, PurchaseHeader);
        Assert.IsTrue(PurchaseLine.FindFirst, StrSubstNo(ValueMustExistMsg, PurchaseLine.TableCaption));
        FindStandardPurchaseLine(StandardPurchaseLine, PurchaseLine."Buy-from Vendor No.");
        PurchaseLine.TestField("No.", StandardPurchaseLine."No.");
        PurchaseLine.TestField(Quantity, StandardPurchaseLine.Quantity);
    end;

    local procedure VerifyNoPurchStdCodesNotification()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Notification ID", StandardCodesMgt.GetPurchRecurringLinesNotificationId);
        Assert.RecordIsEmpty(TempNotificationContext);
    end;

    local procedure VerifyPurchStdCodesNotification(PurchaseHeader: Record "Purchase Header")
    var
        TempNotificationContext: Record "Notification Context" temporary;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Record ID", PurchaseHeader.RecordId);
        Assert.IsTrue(TempNotificationContext.FindFirst, 'Notification not found');
        Assert.AreEqual(
          StandardCodesMgt.GetPurchRecurringLinesNotificationId,
          TempNotificationContext."Notification ID",
          InvalidNotificationIdMsg);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure VerifyPurchStdCodesNotificationId()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        Assert.AreEqual(
          StandardCodesMgt.GetPurchRecurringLinesNotificationId,
          TempNotificationContext."Notification ID",
          InvalidNotificationIdMsg);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CreateStdPurchaseCodeWithResourceLine(var StandardPurchaseCode: Record "Standard Purchase Code"; var StandardPurchaseLine: Record "Standard Purchase Line"; ResourceNo: Code[20])
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Validate(Type, StandardPurchaseLine.Type::Resource);
        StandardPurchaseLine.Validate("No.", ResourceNo);
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardPurchaseLine.Modify(true);
    end;

    local procedure VerifyStandardPurchaseLineWithResource(StandardPurchaseLine: Record "Standard Purchase Line"; Resource: Record Resource)
    begin
        Assert.AreEqual(StandardPurchaseLine."No.", Resource."No.", ResourceErr);
        Assert.AreEqual(StandardPurchaseLine.Description, Resource.Name, ResourceErr);
        Assert.AreEqual(StandardPurchaseLine."Unit of Measure Code", Resource."Base Unit of Measure", ResourceErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesModalPageHandler(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        StandardVendorPurchaseCodes.FILTER.SetFilter(Code, Code);
        StandardVendorPurchaseCodes.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesCancelModalPageHandler(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    begin
        StandardVendorPurchaseCodes.Cancel.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        if not (Notification.Id = StandardCodesMgt.GetPurchRecurringLinesNotificationId()) then
            exit;
        LibraryVariableStorage.Clear;
        Evaluate(PurchaseHeader."Document Type", Notification.GetData(PurchaseHeader.FieldName("Document Type")));
        PurchaseHeader."No." := Notification.GetData(PurchaseHeader.FieldName("No."));
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListPageHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.Cancel().Invoke();
    end;
}

