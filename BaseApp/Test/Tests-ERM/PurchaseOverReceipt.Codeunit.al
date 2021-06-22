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
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OverReceiptFeatureIsEnabled: Boolean;
        QuantityAfterOverReceiptErr: Label 'Quantity is wrong after over receipt.';
        OverReceiptNotificationTxt: Label 'An over-receipt quantity is recorded on purchase order %1.';
        QtyToReceiveOverReceiptErr: Label 'Validation error for Field: Qty. to Receive,  Message = ''You cannot enter more than 10 in the Over-Receipt Quantity field.''';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformControlVisibilityFeatureEnabled()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: testPage "Purchase Order";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PstdRcptDocNo: Code[20];
    begin
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
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code" = PurchaseLine."Over-Receipt Code", 'Over Receipt Code is wrong in purchase receipt line.');
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
        OverReceiptCodeTxt: Code[10];
    begin
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
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DocNo: Code[20];
    begin
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

    procedure SetOverReceiptFeatureEnabled(Enabled: Boolean)
    begin
        OverReceiptFeatureIsEnabled := Enabled;
    end;

    local procedure CreateOverReceiptCode(): Code[10]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Code := LibraryUtility.GenerateGUID();
        OverReceiptCode.Description := OverReceiptCode.Code;
        OverReceiptCode."Over-Receipt Tolerance %" := 100;
        OverReceiptCode.Insert();

        exit(OverReceiptCode.Code);
    end;

    local procedure CreateOverReceiptCode(DeleteExisting: Boolean): Code[10]
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
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

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
        WarehouseReceiptHeader.Get(LibraryWarehouse.FindWhseReceiptNoBySourceDoc(Database::"Purchase Line", PurchaseHeader."Document Type", PurchaseHeader."No."));
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure VerifyDefaultOverReceiptCode(OverReceiptCodeTxt: Code[10])
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
}