codeunit 147506 "Cartera Payable Unit Tests"
{
    // // [FEATURE] [UT] [Cartera] [Payables]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LocalTxt: Label 'LOCAL', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePaymentOrderWithCustomNo()
    var
        CarteraSetup: Record "Cartera Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PaymentOrder: Record "Payment Order";
        OldPaymentOrderNoSeries: Code[20];
        PaymentOrderNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // Setup
        CarteraSetup.Get();
        OldPaymentOrderNoSeries := CarteraSetup."Payment Order Nos.";
        CarteraSetup.Validate("Payment Order Nos.", NoSeries.Code);
        CarteraSetup.Modify(true);

        // Pre-Exercise
        PaymentOrderNo := LibraryUtility.GenerateRandomCode(PaymentOrder.FieldNo("No."), DATABASE::"Payment Order");

        // Exercise
        PaymentOrder.Init();
        PaymentOrder.Validate("No.", PaymentOrderNo);
        PaymentOrder.Insert(true);

        // Verify
        Assert.AreEqual(0, PaymentOrder."No. Printed", '');
        Assert.AreEqual(PaymentOrder.TableCaption + ' ' + PaymentOrderNo, PaymentOrder."Posting Description", '');

        // Teadown
        CarteraSetup.Get();
        CarteraSetup.Validate("Payment Order Nos.", OldPaymentOrderNoSeries);
        CarteraSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('POCommentSheetPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentOrderWithComments()
    var
        PaymentOrder: Record "Payment Order";
        POCommentLine: Record "BG/PO Comment Line";
        Comment: Variant;
    begin
        Initialize();

        // Setup
        CreatePaymentOrderWithBankAccount(PaymentOrder);

        // Exercise
        AddCommentLineFromList(PaymentOrder."No.");

        // Post-Exercise
        Commit();

        // Pre-Verify
        LibraryVariableStorage.Dequeue(Comment);

        // Verify
        POCommentLine.SetRange("BG/PO No.", PaymentOrder."No.");
        POCommentLine.SetRange(Type, POCommentLine.Type::Payable);
        POCommentLine.SetRange(Comment, Comment);
        Assert.IsFalse(POCommentLine.IsEmpty, '');

        // Teardown
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('POCommentSheetPageHandler')]
    [Scope('OnPrem')]
    procedure DeletePaymentOrder()
    var
        PaymentOrder: Record "Payment Order";
        POCommentLine: Record "BG/PO Comment Line";
        PaymentOrderNo: Code[20];
    begin
        Initialize();

        // Setup
        PaymentOrderNo := CreatePaymentOrderWithBankAccount(PaymentOrder);
        AddCommentLineFromCard(PaymentOrderNo);

        // Exercise
        PaymentOrder.Get(PaymentOrderNo);
        PaymentOrder.Delete(true);

        // Verify
        Assert.IsFalse(PaymentOrder.Get(PaymentOrderNo), '');
        POCommentLine.SetRange("BG/PO No.", PaymentOrderNo);
        Assert.IsTrue(POCommentLine.IsEmpty, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunPaymentOrdersMaturityGeneralActionForSelectedPmtOrder()
    var
        PaymentOrder: array[2] of Record "Payment Order";
        PaymentOrdersList: TestPage "Payment Orders List";
        PaymentOrdersMaturity: TestPage "Payment Orders Maturity";
    begin
        // [FEATURE] [Payment Order] [UI]
        // [SCENARIO 363721] Action "Payment Orders Maturity" on "Bill Groups List" with multiple lines should open page for selected Payment Order
        Initialize();

        // [GIVEN] Two Payment Orders in "Payment Orders List" page: "PO1" and "PO2"
        CreatePaymentOrderWithBankAccount(PaymentOrder[1]);
        CreatePaymentOrderWithBankAccount(PaymentOrder[2]);

        // [GIVEN] Select Payment Order "PO2" from "Payment Orders List" page
        PaymentOrdersList.OpenView;
        PaymentOrdersList.GotoRecord(PaymentOrder[2]);

        // [WHEN] Run General Action "Payment Orders Maturity"
        PaymentOrdersMaturity.Trap;
        PaymentOrdersList.GeneralPaymentOrdersMaturity.Invoke;

        // [THEN] "Payment Orders Maturity" page is opened for Payment Order "PO2"
        Assert.AreEqual(PaymentOrder[2]."No.", PaymentOrdersMaturity.FILTER.GetFilter("No."), PaymentOrder[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPaymentOrdersMaturityActionFromList()
    var
        PaymentOrder: array[2] of Record "Payment Order";
        PaymentOrders: TestPage "Payment Orders";
        PaymentOrdersMaturity: TestPage "Payment Orders Maturity";
    begin
        // [FEATURE] [Payment Order] [UI]
        // [SCENARIO 380645] Action "Maturity" on "Payment Orders" should open a page for the selected Payment Order.
        Initialize();

        // [GIVEN] Two Payment Orders created: "PO1" and "PO2".
        CreatePaymentOrderWithBankAccount(PaymentOrder[1]);
        CreatePaymentOrderWithBankAccount(PaymentOrder[2]);

        // [GIVEN] Select Payment Order "PO2" from "Payment Orders" page.
        PaymentOrders.OpenView;
        PaymentOrders.GotoRecord(PaymentOrder[2]);

        // [WHEN] Run Action "Payment Orders Maturity".
        PaymentOrdersMaturity.Trap;
        PaymentOrders."Page Payment Orders Maturity Process".Invoke;

        // [THEN] "Payment Orders Maturity" page is opened for Payment Order "PO2"
        Assert.AreEqual(
          PaymentOrder[2]."No.", PaymentOrdersMaturity.FILTER.GetFilter("No."), PaymentOrder[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedPmtOrdersMaturityActionFromCard()
    var
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrders: TestPage "Posted Payment Orders";
        PostedPaymentOrdersMaturity: TestPage "Posted Payment Orders Maturity";
    begin
        // [FEATURE] [Payment Order] [UI]
        // [SCENARIO 380645] Action "Maturity" on "Posted Payment Orders" should open a page for the selected Posted Payment Order.
        Initialize();

        // [GIVEN] Mock two Posted Payment Orders: "PPO1" and "PPO2".
        MockPostedPaymentOrder(PostedPaymentOrder);
        MockPostedPaymentOrder(PostedPaymentOrder);

        // [GIVEN] Select Posted Payment Order "PPO2" from "Posted Payment Orders" page.
        PostedPaymentOrders.OpenView;
        PostedPaymentOrders.GotoRecord(PostedPaymentOrder);

        // [WHEN] Run Action "Posted Payment Orders Maturity".
        PostedPaymentOrdersMaturity.Trap;
        PostedPaymentOrders."Page Posted Payment Orders Maturity Process".Invoke;

        // [THEN] "Posted Payment Orders Maturity" page is opened for Posted Payment Order "PPO2".
        Assert.AreEqual(
          PostedPaymentOrder."No.", PostedPaymentOrdersMaturity.FILTER.GetFilter("No."), PostedPaymentOrder.FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedPmtOrdersMaturityActionFromList()
    var
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersList: TestPage "Posted Payment Orders List";
        PostedPaymentOrdersMaturity: TestPage "Posted Payment Orders Maturity";
    begin
        // [FEATURE] [Payment Order] [UI]
        // [SCENARIO 380645] Action "Maturity" on "Posted Payment Orders List" should open a page for the selected Posted Payment Order.
        Initialize();

        // [GIVEN] Mock two Posted Payment Orders: "PPO1" and "PPO2".
        MockPostedPaymentOrder(PostedPaymentOrder);
        MockPostedPaymentOrder(PostedPaymentOrder);

        // [GIVEN] Select Posted Payment Order "PPO2" from "Posted Payment Orders List" page.
        PostedPaymentOrdersList.OpenView;
        PostedPaymentOrdersList.GotoRecord(PostedPaymentOrder);

        // [WHEN] Run Action "Posted Payment Orders Maturity".
        PostedPaymentOrdersMaturity.Trap;
        PostedPaymentOrdersList."Page Posted Payment Orders Maturity Process".Invoke;

        // [THEN] "Posted Payment Orders Maturity" page is opened for Posted Payment Order "PPO2".
        Assert.AreEqual(
          PostedPaymentOrder."No.", PostedPaymentOrdersMaturity.FILTER.GetFilter("No."), PostedPaymentOrder.FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentsMaturityFromPayablesCarteraDocs()
    var
        CarteraDoc: Record "Cartera Doc.";
        DocumentsMaturity: TestPage "Documents Maturity";
        PayablesCarteraDocs: TestPage "Payables Cartera Docs";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Documents Maturity" should open a page for the Payables type.
        Initialize();

        // [GIVEN] Cartera Document
        MockPayableCarteraDoc(CarteraDoc);

        // [GIVEN] Open a Page for Payables Cartera Docs
        PayablesCarteraDocs.OpenView;

        // [WHEN] Run Action "Documents Maturity"
        DocumentsMaturity.Trap;
        PayablesCarteraDocs."Documents Maturity".Invoke;

        // [THEN] A filter for the field "Type" is transfered to the Documents Maturity Page.
        Assert.AreEqual(
          Format(CarteraDoc.Type),
          DocumentsMaturity.FILTER.GetFilter(Type),
          Format(CarteraDoc.Type::Payable));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedPaymentOrdersMaturityFromPostedPaymentOrdersSelect()
    var
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersSelect: TestPage "Posted Payment Orders Select.";
        PostedPaymentOrdersMaturity: TestPage "Posted Payment Orders Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Posted Payment Orders Maturity" should open a page for the selected Posted Payment Order.
        Initialize();

        // [GIVEN] Two Posted Payment Orders created: "PPO1" and "PPO2"
        MockPostedPaymentOrder(PostedPaymentOrder);
        MockPostedPaymentOrder(PostedPaymentOrder);

        // [GIVEN] Open "Posted Payment Orders Select." page on "PPO2"
        PostedPaymentOrdersSelect.OpenView;
        PostedPaymentOrdersSelect.GotoRecord(PostedPaymentOrder);

        // [WHEN] Run Action "Posted Payment Orders Maturity".
        PostedPaymentOrdersMaturity.Trap;
        PostedPaymentOrdersSelect."Posted Payment Orders Maturity".Invoke;

        // [THEN] "Posted Payment Orders Maturity" page is opened for Posted Payment Order "PPO2".
        Assert.AreEqual(
          PostedPaymentOrder."No.",
          PostedPaymentOrdersMaturity.FILTER.GetFilter("No."),
          PostedPaymentOrder.FieldCaption("No."));
    end;

    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure IndirectCarteraDocPermissionFromVendorLedgerEntry()
    var
        CarteraDoc: Record "Cartera Doc.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentMethod: Record "Payment Method";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Permission] [UI]
        // [SCENARIO 257878] Vendor Ledger Entry's "Payment Method Code" can be modified (including linked "Cartera Doc." update) via indirect customer license
        Initialize();
        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        MockPayableCarteraDoc(CarteraDoc);
        MockVendorLedgerEntry(VendorLedgerEntry, CarteraDoc);
        ModifyPermissionData(LocalTxt, DATABASE::"Cartera Doc.", 2, 0, 2, 0);
        Commit();

        // [GIVEN] Customer license with indirect permissions (RxMx) to "Cartera Doc."
        // TODO: Uncomment LibraryLowerPermissions.SetVendorView; // includes "LOCAL" role with changed permissions to "Cartera Doc."
        // [GIVEN] "Cartera Doc." can not be read or modified directly due to indirect permissions
        asserterror CarteraDoc.Find();
        Assert.ExpectedErrorCode('DB:ClientReadDenied');
        Assert.ExpectedError(CarteraDoc.TableName);
        asserterror CarteraDoc.Modify();
        Assert.ExpectedErrorCode('DB:ClientModifyDenied');
        Assert.ExpectedError(CarteraDoc.TableName);

        // [GIVEN] Vendor Ledger Entry page
        // [WHEN] Modify "Payment Method Code"
        // [THEN] "Payment Method Code" has been validated and linked "Cartera Doc." record has been updated
        VendorLedgerEntries.OpenEdit;
        VendorLedgerEntries.GotoRecord(VendorLedgerEntry);
        VendorLedgerEntries."Payment Method Code".SetValue(PaymentMethod.Code);
        VendorLedgerEntries.Close();

        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        CarteraDoc.Find();
        CarteraDoc.TestField("Payment Method Code", PaymentMethod.Code);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePaymentOrderWithBankAccount(var PaymentOrder: Record "Payment Order"): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');
        exit(LibraryCarteraPayables.CreatePaymentOrder(PaymentOrder, '', BankAccount."No."));
    end;

    local procedure MockPostedPaymentOrder(var PostedPaymentOrder: Record "Posted Payment Order")
    begin
        PostedPaymentOrder.Init();
        PostedPaymentOrder."No." :=
          LibraryUtility.GenerateRandomCode(PostedPaymentOrder.FieldNo("No."), DATABASE::"Posted Payment Order");
        PostedPaymentOrder.Insert();
    end;

    local procedure MockPayableCarteraDoc(var CarteraDoc: Record "Cartera Doc.")
    begin
        with CarteraDoc do begin
            Init();
            Type := Type::Payable;
            "Entry No." := LibraryUtility.GetNewRecNo(CarteraDoc, FieldNo("Entry No."));
            "Document Type" := "Document Type"::Bill;
            "Document No." := LibraryUtility.GenerateGUID();
            "Account No." := LibraryUtility.GenerateGUID();
            "No." := LibraryUtility.GenerateGUID();
            Insert();
        end;
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CarteraDoc: Record "Cartera Doc.")
    begin
        with VendorLedgerEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, FieldNo("Entry No."));
            Open := true;
            "Document No." := CarteraDoc."Document No.";
            "Vendor No." := CarteraDoc."Account No.";
            "Bill No." := CarteraDoc."No.";
            Insert();
        end;
    end;

    local procedure ModifyPermissionData(RoleID: Code[20]; ObjectID: Integer; NewReadPermission: Integer; NewInsertPermission: Integer; NewModifyPermission: Integer; NewDeletePermission: Integer)
    var
        Permission: Record Permission;
    begin
        with Permission do begin
            Get(RoleID, "Object Type"::"Table Data", ObjectID);
            "Read Permission" := NewReadPermission;
            "Insert Permission" := NewInsertPermission;
            "Modify Permission" := NewModifyPermission;
            "Delete Permission" := NewDeletePermission;
            "Execute Permission" := "Execute Permission"::" ";
            Modify();
        end;
    end;

    local procedure AddCommentLineFromList(PaymentOrderNo: Code[20])
    var
        PaymentOrdersList: TestPage "Payment Orders List";
    begin
        PaymentOrdersList.OpenEdit;
        PaymentOrdersList.GotoKey(PaymentOrderNo);
        PaymentOrdersList.Comments.Invoke;
    end;

    local procedure AddCommentLineFromCard(PaymentOrderNo: Code[20])
    var
        PaymentOrders: TestPage "Payment Orders";
    begin
        PaymentOrders.OpenEdit;
        PaymentOrders.GotoKey(PaymentOrderNo);
        PaymentOrders.Comments.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure POCommentSheetPageHandler(var POCommentSheet: TestPage "BG/PO Comment Sheet")
    var
        Comment: Text[80];
    begin
        Comment := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(Comment);

        POCommentSheet.New;
        POCommentSheet.Date.SetValue(WorkDate());
        POCommentSheet.Comment.SetValue(Comment);
        POCommentSheet.OK.Invoke;
    end;
}

