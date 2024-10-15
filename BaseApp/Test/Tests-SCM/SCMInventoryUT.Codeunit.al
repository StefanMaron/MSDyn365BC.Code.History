codeunit 137821 "SCM - Inventory UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        CannotChangeItemTrackingCodeErr: Label 'You cannot change Item Tracking Code because there is at least one outstanding Purchase Order that include this item.';
        AvailProblemOccursOnSNTrackingErr: Label 'No availability problem should occur if SN Specific Tracking = FALSE.';
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        MustHaveValueErr: Label '%1 must have a value in %2: Primary Key=. It cannot be zero or empty.', Comment = '%1 : field name, %2 : table name.';

    [Test]
    [Scope('OnPrem')]
    procedure WrongErrorMessageWhenDeletingITCodeFromItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 6816] Item Tracking Code in Item could not be changed if an outstanding Purchase Order including this Item exists.
        Initialize();

        // [GIVEN] Item with Item Tracking Code. "Lot Specific Tracking" := TRUE.
        MockItemTrackingCode(ItemTrackingCode, true);
        MockItem(Item, LibraryUtility.GenerateGUID(), ItemTrackingCode.Code);

        // [GIVEN] Purchase Line with Item.
        MockPurchaseLine(PurchaseLine, Item."No.");

        // [WHEN] Delete the Item Tracking Code from Item.
        asserterror Item.Validate("Item Tracking Code", '');

        // [THEN] The error message refers to the purchase order line.
        Assert.ExpectedError(CannotChangeItemTrackingCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSNAvailabilityWhenSNTrackingIsFalse()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        LookupMode: Enum "Item Tracking Type";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 6744] Check of Serial No. availability in Item Tracking should be passed successfully when "SN Specific Tracking" = FALSE in Item Tracking Code.
        Initialize();

        // [GIVEN] Item Tracking Code with "SN Specific Tracking" = FALSE.
        MockItemTrackingCode(ItemTrackingCode, false);

        // [GIVEN] Demand Reservation Entry and Tracking Specification.
        MockReservationEntry(ReservationEntry, LibraryUtility.GenerateGUID());
        MockTrackingSpecification(TrackingSpecification, ReservationEntry);

        // [WHEN] Call TrackingAvailable function checking whether any availability problem occurs.
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode('', ItemTrackingCode);
        Assert.IsTrue(
          ItemTrackingDataCollection.TrackingAvailable(TrackingSpecification, LookupMode::"Serial No."),
          AvailProblemOccursOnSNTrackingErr);

        // [THEN] TrackingAvailable function returns TRUE (no availability problem).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoEntriesExistCheckSkippedOnEmptyItem()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 380565] Update of Costing Method for an Item with so far undefined "No.", should not check existence of Purchase Lines with "Item" Type and blank "No.".
        Initialize();

        // [GIVEN] Item with blank "No." and "Costing Method" = FIFO.
        MockItem(Item, '', '');

        // [GIVEN] Purchase Line with "Type" = Item and blank "No.".
        MockPurchaseLine(PurchaseLine, Item."No.");

        // [WHEN] Validate "Costing Method" of Item to Standard.
        Item.Validate("Costing Method", Item."Costing Method"::Standard);

        // [THEN] No error is thrown.
        // [THEN] "Costing Method" is updated.
        Item.TestField("Costing Method", Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankCustomerNos()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 381935]  If delete the content of "Customer Nos." field in the "Sales & Receivables Setup" table, it should not be possible to create a record "Customer" with an empty value of the prinary key "No.".
        Initialize();

        with SalesReceivablesSetup do begin
            // [GIVEN] "Sales & Receivables Setup" with a blank field "Customer Nos."
            Get();
            Validate("Customer Nos.", '');
            Modify(true);
        end;

        with Customer do begin
            // [WHEN] Insert "Customer" with blank "No."
            Init();
            Validate(Name, LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::Customer));

            // [THEN] Error occurs : "Customer Nos. must have a value in Sales & Receivables Setup: Primary Key=. It cannot be zero or empty."
            asserterror Insert(true);
        end;
        with SalesReceivablesSetup do
            Assert.ExpectedError(StrSubstNo(MustHaveValueErr, FieldName("Customer Nos."), TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankVendorNos()
    var
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 381935]  If delete the content of "Vendor Nos." field in the "Purchases & Payables Setup" table, it should not be possible to create a record "Vendor" with an empty value of the prinary key "No.".
        Initialize();

        with PurchasesPayablesSetup do begin
            // [GIVEN] "Purchases & Payables Setup" with a blank field "Vendor Nos."
            Get();
            Validate("Vendor Nos.", '');
            Modify(true);
        end;

        with Vendor do begin
            // [WHEN] Insert "Vendor" with blank "No."
            Init();
            Validate(Name, LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::Vendor));

            // [THEN] Error occurs : "Vendor Nos. must have a value in Purchases & Payables Setup: Primary Key=. It cannot be zero or empty."
            asserterror Insert(true);
        end;
        with PurchasesPayablesSetup do
            Assert.ExpectedError(StrSubstNo(MustHaveValueErr, FieldName("Vendor Nos."), TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankItemNos()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 381935]  If delete the content of "Item Nos." field in the "Inventory Setup" table, it should not be possible to create a record "Item" with an empty value of the prinary key "No.".
        Initialize();

        with InventorySetup do begin
            // [GIVEN] "Inventory Setup" with a blank field "Item Nos."
            Get();
            Validate("Item Nos.", '');
            Modify(true);
        end;

        with Item do begin
            // [WHEN] Insert "Item" with blank "No."
            Init();
            Validate(Description, LibraryUtility.GenerateRandomCode(FieldNo(Description), DATABASE::Item));

            // [THEN] Error occurs : "Item Nos. must have a value in Inventory Setup: Primary Key=. It cannot be zero or empty."
            asserterror Insert(true);
        end;

        with InventorySetup do
            Assert.ExpectedError(StrSubstNo(MustHaveValueErr, FieldName("Item Nos."), TableCaption));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Inventory UT");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM - Inventory UT");

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM - Inventory UT");
    end;

    local procedure MockItem(var Item: Record Item; No: Code[20]; ItemTrackingCode: Code[10])
    begin
        with Item do begin
            Init();
            "No." := No;
            "Item Tracking Code" := ItemTrackingCode;
            "Costing Method" := "Costing Method"::FIFO;
            Insert();
        end;
    end;

    local procedure MockItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; IsSpecificTracking: Boolean)
    begin
        with ItemTrackingCode do begin
            Init();
            Code := LibraryUtility.GenerateGUID();
            "Lot Specific Tracking" := IsSpecificTracking;
            "SN Specific Tracking" := IsSpecificTracking;
            Insert();
        end;
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        with PurchaseLine do begin
            "Document Type" := "Document Type"::Order;
            "Document No." := LibraryUtility.GenerateGUID();
            Type := Type::Item;
            "No." := ItemNo;
            Insert();
        end;
    end;

    local procedure MockReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        with ReservationEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, FieldNo("Entry No."));
            Positive := false;
            "Item No." := ItemNo;
            Quantity := -LibraryRandom.RandInt(10);
            "Quantity (Base)" := Quantity;
            "Item Tracking" := "Item Tracking"::"Serial No.";
            "Serial No." := LibraryUtility.GenerateGUID();
            Insert();
        end;
    end;

    local procedure MockTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        with TrackingSpecification do begin
            Init();
            "Item No." := ReservationEntry."Item No.";
            "Quantity (Base)" := ReservationEntry."Quantity (Base)";
            "Serial No." := ReservationEntry."Serial No.";
            Insert();
        end;
    end;
}

