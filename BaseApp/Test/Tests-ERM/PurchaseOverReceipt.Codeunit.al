codeunit 134851 "Purchase Over Receipt"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Over Receipt] [Purchase Order] [Warehouse Receipt]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OverReceiptFeatureIsEnabled: Boolean;
        IsInitialized: Boolean;
        QuantityAfterOverReceiptErr: Label 'Quantity is wrong after over receipt.';
        OverReceiptNotificationTxt: Label 'An over-receipt quantity is recorded on purchase order %1.';
        QtyToReceiveOverReceiptErr: Label 'Validation error for Field: Qty. to Receive,  Message = ''You cannot enter more than 10 in the Over-Receipt Quantity field.''';
        WarehouseRcvRequiredErr: Label 'Warehouse Receive is required for this line. The entered information may be disregarded by warehouse activities.';
        CheckOverReceiptAllowedForWhseReceiptLineErr: Label 'Source Document must be equal to ''%1''  in Warehouse Receipt Line: No.=%2, Line No.=%3. Current value is ''%4''.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformControlVisibilityFeatureEnabled()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: testPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [WHEN] Open purchase order
        PurchaseOrder.Trap();
        PurchaseOrder.OpenView();
        PurchaseOrder.First();
        // [THEN] "Over Receipt" controls are visible
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Code".Visible(), 'Over receipt controls should be visible.');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".Visible(), 'Over receipt controls should be visible.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformControlVisibilityFeatureDisabled()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: testPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is disabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(false);
        BindSubscription(PurchaseOverReceipt);
        // [WHEN] Open purchase order
        PurchaseOrder.Trap();
        PurchaseOrder.OpenView();
        PurchaseOrder.First();
        // [THEN] "Over Receipt" controls are not visible
        Assert.IsFalse(PurchaseOrder.PurchLines."Over-Receipt Code".Visible(), 'Over receipt controls should not be visible.');
        Assert.IsFalse(PurchaseOrder.PurchLines."Over-Receipt Quantity".Visible(), 'Over receipt controls should not be visible.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [THEN] "Q" = 13
        Assert.IsTrue(PurchaseLine.Quantity = 13, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValueTwoTimes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [WHEN] Validate "ORQ" = 5
        PurchaseLine.Validate("Over-Receipt Quantity", 5);
        // [THEN] "Q" = 15
        Assert.IsTrue(PurchaseLine.Quantity = 15, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValueDecreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [WHEN] Validate "ORQ" = 2
        PurchaseLine.Validate("Over-Receipt Quantity", 2);
        // [THEN] "Q" = 12
        Assert.IsTrue(PurchaseLine.Quantity = 12, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [THEN] "Q" = 7
        Assert.IsTrue(PurchaseLine.Quantity = 7, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValueTwoTimes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [WHEN] Validate "ORQ" = -5
        PurchaseLine.Validate("Over-Receipt Quantity", -5);
        // [THEN] "Q" = 5
        Assert.IsTrue(PurchaseLine.Quantity = 5, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValueIncreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [WHEN] Validate "ORQ" = -2
        PurchaseLine.Validate("Over-Receipt Quantity", -2);
        // [THEN] "Q" = 8
        Assert.IsTrue(PurchaseLine.Quantity = 8, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantitySameValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 5
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine."Over-Receipt Quantity" := 5;
        PurchaseLine.Modify(true);
        // [WHEN] Validate "ORQ" = 5, the same value
        PurchaseLine.Validate("Over-Receipt Quantity", 5);
        // [THEN] "Q" = 10, not changed
        Assert.IsTrue(PurchaseLine.Quantity = 10, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityZeroValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 7
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine."Over-Receipt Quantity" := 7;
        PurchaseLine.Modify(true);
        // [WHEN] Validate "ORQ" = 0
        PurchaseLine.Validate("Over-Receipt Quantity", 0);
        // [THEN] "Q" = 3, like as before over receipt
        Assert.IsTrue(PurchaseLine.Quantity = 3, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithOverReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PstdRcptDocNo: Code[20];
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 7
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Post purchase order
        PstdRcptDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [THEN] Purchase receipt line "Q" = purchase line "Q" = 17
        // [THEN] Purchase receipt line "ORQ" = purchase line "ORQ" = 7
        // [THEN] Purchase receipt line "Over-Receipt Code" = purchase line "Over-Receipt Code"
        PurchRcptLine.SetRange("Document No.", PstdRcptDocNo);
        PurchRcptLine.FindFirst();
        Assert.IsTrue(PurchRcptLine.Quantity = PurchaseLine.Quantity, 'Quantity is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Quantity" = PurchaseLine."Over-Receipt Quantity", 'Over Receipt Quantity is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code 2" = PurchaseLine."Over-Receipt Code", 'Over Receipt Code is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code 2" <> '', '2');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code" = '', 'empty');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithOverReceiptWithApproval()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OverReceiptCode: Record "Over-Receipt Code";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order
        // [GIVEN] Over-Receipt code with approval and default
        CreateOverReceiptCodeExtended(OverReceiptCode, true, true);
        CreatePurchaseOrderWithoutOverReceipt(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Post purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Order is not posted, error message about approval is appeared
        Assert.ExpectedError('There are lines with over-receipt required for approval.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        // [THEN] Notification is shown
        Assert.AreEqual(StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."), LibraryVariableStorage.DequeueText(), 'Wrong notification');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQtyToReceiveTwiceOverLimit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt = 100 % of quantity
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(20);
        // [WHEN] Validate "Qty. to Receive" = "Qty. to Receive" + 1 (over-receipt > 100 % of quantity)
        asserterror PurchaseOrder.PurchLines."Qty. to Receive".SetValue(21);
        // [THEN] Error is appeared
        Assert.ExpectedError(QtyToReceiveOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQtyToReceiveTwiceWithinLimit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(15);
        // [WHEN] Validate "Qty. to Receive" = 19
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(19);
        // [THEN] "Qty. to Receive" = 19
        // [THEN] "Over-Receipt Quantity" = 9
        Assert.IsTrue(PurchaseOrder.PurchLines."Qty. to Receive".AsInteger() = 19, 'Wrong Qty. to Receive');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".AsInteger() = 9, 'Wrong Over-Receipt Quantity');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQuantityToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(15);
        // [WHEN] Validate "Over-Receipt Quantity" = 0
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(0);
        // [THEN] "Qty. to Receive" = 10
        // [THEN] "Over-Receipt Quantity" = 0
        Assert.IsTrue(PurchaseOrder.PurchLines."Qty. to Receive".AsInteger() = 10, 'Wrong Qty. to Receive');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".AsInteger() = 0, 'Wrong Over-Receipt Quantity');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure ValidateDefaultOverReceiptCode()
    var
        OverReceiptCode: Record "Over-Receipt Code";
        OverReceiptCodes: TestPage "Over-Receipt Codes";
        OverReceiptCodeTxt: Code[20];
    begin
        Initialize();
        // [GIVEN] Three over-receipt codes
        CreateThreeOverReceiptCodes();

        // [WHEN] Invoke click on the "Default" field of over-receipt code (first record)
        OverReceiptCodes.OpenEdit();
        OverReceiptCodes.First();
        OverReceiptCodeTxt := OverReceiptCodes.Code.Value;
        OverReceiptCodes.Default.SetValue(true);
        OverReceiptCodes.Next();

        // [THEN] First over-receipt code has "Defaul" equal to true
        // [THEN] All other over-receipt codes have "Default" equal to false
        VerifyDefaultOverReceiptCode(OverReceiptCodeTxt);

        // [WHEN] Invoke click on the "Default" field of over-receipt code (last record)
        OverReceiptCodes.Last();
        OverReceiptCodeTxt := OverReceiptCodes.Code.Value;
        OverReceiptCodes.Default.SetValue(true);
        OverReceiptCodes.Previous();

        // [THEN] Last over-receipt code has "Defaul" equal to true
        // [THEN] All other over-receipt codes have "Default" equal to false
        VerifyDefaultOverReceiptCode(OverReceiptCodeTxt);

        // [WHEN]  Deselect "Default" field of over-receipt code (last record)
        OverReceiptCodes.Last();
        OverReceiptCodes.Default.SetValue(false);
        OverReceiptCodes.Previous();

        // [THEN] All over-receipt codes have "Default" equal to false
        OverReceiptCode.SetRange(Default, true);
        Assert.RecordIsEmpty(OverReceiptCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityUndoReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        DocNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 344787] "Over-Receipt Quantity" returned back to it's value before posting after undo receipt

        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Posted purchase receipt, "Q" = 10, "ORQ" = 3
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        PurchaseLine.Modify();
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo posted purchase receipt
        PurchRcptLine.SetRange("Document No.", DocNo);
        PurchRcptLine.SetRange("Line No.", PurchaseLine."Line No.");
        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Purchase line "Q" = 13, "ORQ" = 3
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.IsTrue(PurchaseLine.Quantity = 13, 'Wrong quantity after undo receipt');
        Assert.IsTrue(PurchaseLine."Over-Receipt Quantity" = 3, 'Wrong over-receipt quantity after undo receipt');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQtyClearsAfterClearOverReceiptCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        OverReceiptApprovalStatus: Enum "Over-Receipt Approval Status";
        OldQtyValue: Decimal;
    begin
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        OldQtyValue := PurchaseLine.Quantity;

        // [GIVEN] Make Over-Receipt for Purchase Order, increase = Y., Over-Receipt Status = Pending
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Validate("Over-Receipt Approval Status", OverReceiptApprovalStatus::Pending);
        PurchaseLine.Modify(true);

        // [WHEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Clear 'Over-Receipt Code' on Purchase Line
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines."Over-Receipt Code".SetValue('');

        // [THEN] 'Over-Receipt Quantity' = 0, Quantity = Qty. to Receive = Qty. To Invoice = Y. 
        PurchaseOrder.PurchLines."Over-Receipt Quantity".AssertEquals(0);
        PurchaseOrder.PurchLines.Quantity.AssertEquals(OldQtyValue);
        PurchaseOrder.PurchLines."Qty. to Receive".AssertEquals(OldQtyValue);
        PurchaseOrder.PurchLines."Qty. to Invoice".AssertEquals(OldQtyValue);
        PurchaseOrder.Close();

        // [THEN] 'Over Receipt Approval Status' = " ";
        PurchaseLine.Find();
        PurchaseLine.TestField("Over-Receipt Approval Status", OverReceiptApprovalStatus::" ");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OverReceiptQuantityFieldWarnRequireReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record "Location";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        MessageText: Text;
    begin
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Location "L" with Require Receipt = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Released Purchase Order with Item I, Quantity = X, Location Code = L
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Order for release Purchaser Order opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();

        // [WHEN] Set Over-Receipt Quantity = 1
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(1);

        // [THEN] Message 'Warehouse Receive is required for this line. The entered information may be disregarded by warehouse activities.' appears  
        MessageText := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(WarehouseRcvRequiredErr, MessageText);
        PurchaseOrder.Close();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityDoesNotUpdatesWhenOverReceiptQuantityHasWrongValue_PurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 357686] Over receipt quantity increase every time when you insert a value
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released purchase order with purchase line, quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Quantity".AssertEquals(10);

        // [GIVEN] Over-receipt qty = 100% of quantity so quantity should be 20
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(10);
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);
        Commit();

        // [GIVEN] "Over-Receipt Quantity" is validated with wrong value: "Over-Receipt Quantity" + 1 (over-receipt > 100% of quantity)
        asserterror PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(11);
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);

        // [WHEN] Validate "Over-Receipt Quantity" with previous correct value
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(10);

        // [THEN] Quantity still should be 20
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);
        PurchaseOrder.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityDoesNotUpdatesWhenOverReceiptQuantityHasWrongValue_WarehouseReceipt()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO 357686] Over receipt quantity increase every time when you insert a value
        Initialize();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Warehouse receipt with warehouse receipt line, quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceiptHeader.Find();
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.Filter.SetFilter("No.", WarehouseReceiptHeader."No.");
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(10);

        // [GIVEN] Over-receipt qty = 100% of quantity so quantity should be 20
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(10);
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);
        Commit();

        // [GIVEN] "Over-Receipt Quantity" is validated with wrong value: "Over-Receipt Quantity" + 1 (over-receipt > 100% of quantity)
        asserterror WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(11);
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);

        // [WHEN] Validate "Over-Receipt Quantity" with previous correct value
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(10);

        // [THEN] Quantity still should be 20
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);
        WarehouseReceipt.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQuantityOnWhseReceiptLineForSRO()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [UT] [Sales Return Order]
        // [SCENARIO 362553] Setting "Over-Receipt Quantity" on Warehouse Receipt Line raises error for Sales Return Order
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] WarehouseReceiptLine is created for SRO
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceiptLine.Validate("Source Document", WarehouseReceiptLine."Source Document"::"Sales Return Order");
        WarehouseReceiptLine.Modify(true);

        // [WHEN] Set "Over-Receipt Quantity"
        // [THEN] Error is raised: "Source Document must be Purchase Order.."
        asserterror WarehouseReceiptLine.Validate("Over-Receipt Quantity", LibraryRandom.RandInt(10));
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(CheckOverReceiptAllowedForWhseReceiptLineErr, WarehouseReceiptLine."Source Document"::"Purchase Order",
          WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.", WarehouseReceiptLine."Source Document"));
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure SetQtyToReceiveWithOverRcptWhenDefQtyToRcptBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        // [SCENARIO] Set Qty to Receive with Over-Receipt tolerance when Default Qty. to Receive = blank
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Blank);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Set 'Qty. to Receive' = X + 1
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        PurchaseLine.Find();
        PurchaseLine.TestField(Quantity, Qty + 1);
        PurchaseLine.TestField("Qty. to Receive", Qty + 1);
        PurchaseLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure ClearOverRcptValueWhenDefQtyToRcptBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Blank);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] 'Qty. to Receive' = X + 1 
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.PurchLines."Over-Receipt Quantity".AssertEquals(1);

        // [WHEN] Set 'Over-Reciept Quantity' = 0
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(0);

        // [THEN] 'Qty. to Receive' = 0
        PurchaseOrder.PurchLines."Qty. to Receive".AssertEquals(0);
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure SetPurchLineQtyToReceiveWithOverRcptWhenDeletedRevalidated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        // [SCENARIO 385845] Set Qty to Receive with Over-Receipt tolerance on Purchase Line after clearing Qty. To Receive
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Remainder);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] "Qty. to Receive" set to 0
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(0);

        // [WHEN] Set "Qty. to Receive" = X + 1
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        PurchaseLine.Find();
        PurchaseLine.TestField(Quantity, Qty + 1);
        PurchaseLine.TestField("Qty. to Receive", Qty + 1);
        PurchaseLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure SetWhseRcptQtyToReceiveWithOverRcptWhenDeletedRevalidated()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        WarehouseReceipt: TestPage "Warehouse Receipt";
        Qty: Decimal;
    begin
        // [SCENARIO 385845] Set Qty to Receive with Over-Receipt tolerance on Warehouse Receipt Line after clearing Qty. To Receive
        Initialize();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Remainder);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        Qty := WarehouseReceiptLine.Quantity;

        // [GIVEN] Open Warehouse Receipt page
        WarehouseReceiptHeader.Find();
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.Filter.SetFilter("No.", WarehouseReceiptHeader."No.");

        // [GIVEN] "Qty. to Receive" set to 0
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(0);

        // [WHEN] Set "Qty. to Receive" = X + 1
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(Qty + 1);
        WarehouseReceipt.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField(Quantity, Qty + 1);
        WarehouseReceiptLine.TestField("Qty. to Receive", Qty + 1);
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [THEN] Quantity = 13
        PurchaseLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        PurchaseLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveSameValueUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [THEN] Quantity = 13
        PurchaseLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        PurchaseLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptQuantityNonZeroUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Validate "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [THEN] Quantity = 17
        PurchaseLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        PurchaseLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptQuantityZeroUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [WHEN] Validate "Over-Receipt Quantity" = 0
        PurchaseLine.Validate("Over-Receipt Quantity", 0);
        PurchaseLine.Modify();

        // [THEN] Quantity = 10
        PurchaseLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        PurchaseLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        PurchaseLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptCodeEmptyValueUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [WHEN] Validate "Over-Receipt Code" = ''
        PurchaseLine.Validate("Over-Receipt Code", '');
        PurchaseLine.Modify();

        // [THEN] Quantity = 10
        PurchaseLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        PurchaseLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        PurchaseLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveTwoTimesUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        PurchaseLine.Validate("Qty. to Receive", 17);
        PurchaseLine.Modify();

        // [THEN] Quantity = 17
        PurchaseLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 17
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        PurchaseLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveTwoTimesWithReceiveUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10, "Qty. to Receive" = 2
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", 2);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] "Qty. to Receive" = 13
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        PurchaseLine.Validate("Qty. to Receive", 17);
        PurchaseLine.Modify();

        // [THEN] Quantity = 19
        PurchaseLine.TestField(Quantity, 19);
        // [THEN] "Qty. to Receive" = 17
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 9
        PurchaseLine.TestField("Over-Receipt Quantity", 9);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [WHEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 13
        WarehouseReceiptLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveSameValueUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 13
        WarehouseReceiptLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptQuantityNonZeroUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [WHEN] Validate "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 17
        WarehouseReceiptLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptQuantityZeroUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 0);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 10
        WarehouseReceiptLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        WarehouseReceiptLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptCodeEmptyValueUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Over-Receipt Code" = ''
        WarehouseReceiptLine.Validate("Over-Receipt Code", '');
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 10
        WarehouseReceiptLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        WarehouseReceiptLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveTwoTimesUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        WarehouseReceiptLine.Validate("Qty. to Receive", 17);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 17
        WarehouseReceiptLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 17
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveTwoTimesWithReceiveUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10, "Qty. to Receive" = 2
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceiptLine.Validate("Qty. to Receive", 2);
        WarehouseReceiptLine.Modify();
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.Get(WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.");
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        WarehouseReceiptLine.Validate("Qty. to Receive", 17);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 19
        WarehouseReceiptLine.TestField(Quantity, 19);
        // [THEN] "Qty. to Receive" = 17
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 9
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 9);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Purchase Over Receipt");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purchase Over Receipt");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purchase Over Receipt");
    end;

    procedure SetOverReceiptFeatureEnabled(Enabled: Boolean)
    begin
        OverReceiptFeatureIsEnabled := Enabled;
    end;

    local procedure CreateOverReceiptCode(): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Code := LibraryUtility.GenerateRandomCode20(OverReceiptCode.FieldNo(Code), Database::"Over-Receipt Code");
        OverReceiptCode.Description := OverReceiptCode.Code;
        OverReceiptCode."Over-Receipt Tolerance %" := 100;
        OverReceiptCode.Insert();

        exit(OverReceiptCode.Code);
    end;

    local procedure CreateOverReceiptCode(DeleteExisting: Boolean): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        if DeleteExisting then
            OverReceiptCode.DeleteAll();

        exit(CreateOverReceiptCode());
    end;

    local procedure CreateOverReceiptCodeExtended(var OverReceiptCode: Record "Over-Receipt Code"; Default: Boolean; RequireApproval: Boolean)
    begin
        OverReceiptCode.Get(CreateOverReceiptCode(true));
        OverReceiptCode.Default := Default;
        OverReceiptCode."Required Approval" := RequireApproval;
        OverReceiptCode.Modify();
    end;

    local procedure CreateThreeOverReceiptCodes()
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            CreateOverReceiptCode();
        end;
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithoutOverReceipt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine, PurchaseHeader);
        WarehouseReceiptLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure FindWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header")
    begin
        WarehouseReceiptHeader.Get(LibraryWarehouse.FindWhseReceiptNoBySourceDoc(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure VerifyDefaultOverReceiptCode(OverReceiptCodeTxt: Code[20])
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.SetRange(Default, true);
        Assert.RecordCount(OverReceiptCode, 1);
        OverReceiptCode.FindFirst();
        Assert.AreEqual(OverReceiptCodeTxt, OverReceiptCode.Code, 'Wrong over-receipt code with default');
    end;

    [SendNotificationHandler]
    procedure OverReceiptNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Over-Receipt Mgt.", 'OnIsOverReceiptAllowed', '', false, false)]
    local procedure OnBeforeOverReceiptAllowed(var OverReceiptAllowed: Boolean)
    begin
        OverReceiptAllowed := OverReceiptFeatureIsEnabled;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}