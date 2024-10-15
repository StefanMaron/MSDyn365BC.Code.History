namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;

codeunit 133008 "Item Tracking Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [Ignore Expiration Date]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarytestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        ItemTrackingTest: Codeunit "Item Tracking Test";
        ConfirmHandlerReply: Boolean;
        ExpirationSubscriberExpectedToBeCalled: Boolean;
        ModalHandlerExpectedToBeCalledNTimes: Integer;
        SubscriberCalls: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TrackingCodeAssignmentError()
    var
        ItemTrackingCodeNoExp: Record "Item Tracking Code";
        Item: Record Item;
        ExpirationDateFormula: DateFormula;
    begin
        // [SCENARIO] It is not possible to assign a tracking code that ignores expiration date, if the item has expiration date calculation set
        Initialize();

        // [GIVEN] A tracking code that ignores expiration date, and an item with an Expiration calculation
        CreateTrackingCodeNoExp(ItemTrackingCodeNoExp);
        LibraryInventory.CreateItem(Item);
        Evaluate(ExpirationDateFormula, '<+1D>');
        Item."Expiration Calculation" := ExpirationDateFormula; // force it without validation to simulate the case when items already existed with expiration calculation but no item tracking code
        Item.Modify();

        // [WHEN] The user tries to assign the item tracking code to this item
        asserterror Item.Validate("Item Tracking Code", ItemTrackingCodeNoExp.Code);

        // [THEN] An error tells him it is not valid
        Assert.AreEqual(
          'The settings for expiration dates do not match on the item tracking code' +
          ' and the item. Both must either use, or not use, expiration dates.',
          GetLastErrorText, 'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpirationDateCalcDisabled()
    var
        ItemTrackingCodeNoExp: Record "Item Tracking Code";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO] It is not possible to edit Item Calculation Date, if the item tracking code ignores expiration date
        Initialize();

        // [GIVEN] A tracking code that ignores expiration date, and an item
        CreateTrackingCodeNoExp(ItemTrackingCodeNoExp);
        LibraryInventory.CreateItem(Item);

        // [WHEN] The user opens the item card
        ItemCard.OpenEdit;
        ItemCard.GotoRecord(Item);

        // [THEN] He can not edit the expiration calculation since there is no tracking code yet
        Assert.IsFalse(ItemCard."Expiration Calculation".Editable, 'Expiration calculation should not be editable at this point.');

        // [WHEN] The user assigns the tracking code that ignores expiration dates to this item
        ItemCard."Item Tracking Code".Value := ItemTrackingCodeNoExp.Code;

        // [THEN] Expiration calculation can't be edited anymore
        Assert.IsFalse(ItemCard."Expiration Calculation".Editable, 'Expiration calculation should not be editable at this point.');

        // [WHEN] The user clears the item tracking code for this item
        ItemCard."Item Tracking Code".Value := '';

        // [THEN] He still can not edit the expiration calculation again
        Assert.IsFalse(ItemCard."Expiration Calculation".Editable, 'Expiration calculation should not be editable at this point.');

        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualExprReqdError()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to ignore expiration date, if "manual exp date reqd" is set
        Initialize();

        // [GIVEN] An item tracking code with "manual expiration date required" set
        CreateTrackingCodeWithExp(ItemTrackingCode);
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);
        ItemTrackingCodeCard."Man. Expir. Date Entry Reqd.".Value := 'Yes';

        // [WHEN] The user tries to ignore expiration date
        asserterror ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] An error tells him it is not possible
        Assert.IsTrue(
          StrPos(GetLastErrorText,
            'You cannot stop using expiration dates if you require manual expiration date entry on the item tracking code.') > 0,
          'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StrictExpirationPostingError()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to ignore expiration date, if strict expiration posting is set
        Initialize();

        // [GIVEN] An item tracking code with "string expiration posting" set
        CreateTrackingCodeWithExp(ItemTrackingCode);
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);
        ItemTrackingCodeCard."Strict Expiration Posting".Value := 'Yes';

        // [WHEN] The user tries to ignore expiration date
        asserterror ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] An error tells him it is not possible
        Assert.IsTrue(
          StrPos(GetLastErrorText,
            'You cannot stop using expiration dates if you require strict expiration posting on the item tracking code.') > 0,
          'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreMakesOtherFieldsNotEditable()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to set strict expiration date or manual expiration date, if we ignore expiration dates
        // [GIVEN] A regular item tracking code
        Initialize();
        CreateTrackingCodeWithExp(ItemTrackingCode);

        // [WHEN] the user opens the item tracking code card
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);

        // [THEN] "Manual expiration date required" and "string expiration posting" are editable
        Assert.IsTrue(ItemTrackingCodeCard."Man. Expir. Date Entry Reqd.".Editable,
          'Manual expiration date entry required should be editable at this point.');
        Assert.IsTrue(ItemTrackingCodeCard."Strict Expiration Posting".Editable,
          'String expiration posting should be editable at this point.');

        // [WHEN] Ignore expiration date is set
        ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] "Manual expiration date required" and "string expiration posting" are not editable anymore
        Assert.IsFalse(ItemTrackingCodeCard."Man. Expir. Date Entry Reqd.".Editable,
          'Manual expiration date entry required should not be editable at this point.');
        Assert.IsFalse(ItemTrackingCodeCard."Strict Expiration Posting".Editable,
          'String expiration posting should not be editable at this point.');

        // [WHEN] Ignore expiration date is unset
        ItemTrackingCodeCard."Use Expiration Dates".Value := 'Yes';

        // [THEN] "Manual expiration date required" and "string expiration posting" are editable again
        Assert.IsTrue(ItemTrackingCodeCard."Man. Expir. Date Entry Reqd.".Editable,
          'Manual expiration date entry required should be editable at this point.');
        Assert.IsTrue(ItemTrackingCodeCard."Strict Expiration Posting".Editable,
          'String expiration posting should be editable at this point.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemsWithNoExpirationDate()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO] Post a purchase order with an item with ignore expiration date
        Initialize();

        // [GIVEN] An item tracking code with ignore expiraiton date, an item using this tracking code, and a purchase order using this item
        CreateTrackingCodeNoExp(ItemTrackingCode);
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item, ItemTrackingCode, '');
        CreatePurchOrder(Item, PurchaseHeader);

        // [WHEN] the order is posted
        if BindSubscription(ItemTrackingTest) then;
        ItemTrackingTest.SetExpirationDateSubscriberExpectedToBeCalled(false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] the expiration date check is skipped. Performance happens here!
        Assert.AreEqual(0, ItemTrackingTest.GetSubscriberCallNumber,
          'Subscriber should not have been invoked');
        UnbindSubscription(ItemTrackingTest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemsWithExpirationDateError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to ignore expiration date, if some posted items with this tracking code have expiration date
        Initialize();

        // [GIVEN] An item with an expiration date, posted in a purchase order
        CreateTrackingCodeWithExp(ItemTrackingCode);
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item, ItemTrackingCode, '+1D');
        CreatePurchOrder(Item, PurchaseHeader);
        if BindSubscription(ItemTrackingTest) then;
        ItemTrackingTest.SetExpirationDateSubscriberExpectedToBeCalled(true);

        // [WHEN] the order is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] the expiration subscriber is called, which could be slow on big databases
        Assert.IsTrue(ItemTrackingTest.GetSubscriberCallNumber > 0,
          'Subscriber should have been invoked');
        ItemTrackingTest.SetExpirationDateSubscriberExpectedToBeCalled(false);
        UnbindSubscription(ItemTrackingTest);

        // [GIVEN] The item now has item ledger entries with expiration date, since we posted the order

        // [WHEN] The user tries to set "ignore expiration date" for this item's tracking code
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);
        asserterror ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] An error tells him it is not possible
        Assert.IsTrue(StrPos(GetLastErrorText,
            StrSubstNo(
              'You cannot stop using expiration dates because item ledger entries with expiration dates exist for item %1.',
              Item."No.")) > 0,
          'Invalid error message.');
    end;

    local procedure CreatePurchOrder(Item: Record Item; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        LibraryRandom: Codeunit "Library - Random";
        SerialNoAssgnCount: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2)); // Use Random Direct Unit Cost.
        PurchaseLine.Modify(true);

        for SerialNoAssgnCount := 1 to PurchaseLine."Quantity (Base)" do
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine,
              LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification"),
              '', 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemsWithExpirationDateCalcToFixClickNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item1: Record Item;
        Item2: Record Item;
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to ignore expiration date, if some items using this tracking code have expiration calculation set. User doesn't fix case.
        Initialize();

        // [GIVEN] 2 items with the same item tracking code
        CreateTrackingCodeWithExp(ItemTrackingCode);
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item1, ItemTrackingCode, '+1D');
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item2, ItemTrackingCode, '+2D');

        // [WHEN] the user tries to ignore the expiration date on this item tracking code, then click No when asked to fix the items.
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);
        ConfirmHandlerReply := false;
        asserterror ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] An error tells him he can't ignore expiration date as items are using it with this tracking code
        Assert.IsTrue(StrPos(GetLastErrorText,
            'You cannot stop using expiration dates because they are set up for 2 item(s).') > 0,
          'Invalid error message.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PageHandler')]
    [Scope('OnPrem')]
    procedure ItemsWithExpirationDateCalcToFixClickYes()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item1: Record Item;
        Item2: Record Item;
        ItemTrackingCodeCard: TestPage "Item Tracking Code Card";
    begin
        // [SCENARIO] It is not possible to ignore expiration date, if some items using this tracking code have expiration calculation set. User fixes case.
        Initialize();

        // [GIVEN] 2 items with the same item tracking code
        CreateTrackingCodeWithExp(ItemTrackingCode);
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item1, ItemTrackingCode, '+1D');
        CreateItemWithExpirationCalcFormulaAndItemTrackingCode(Item2, ItemTrackingCode, '+2D');

        // [WHEN] the user tries to ignore the expiration date on this item tracking code, then click Yes when asked to fix the items. And fixes them one by one.
        ItemTrackingCodeCard.OpenEdit;
        ItemTrackingCodeCard.GotoRecord(ItemTrackingCode);
        ConfirmHandlerReply := true;
        ModalHandlerExpectedToBeCalledNTimes := 2;
        ItemTrackingCodeCard."Use Expiration Dates".Value := 'No';

        // [THEN] No error occurs
    end;

    //================================TESTS FOR BARCODE SCANNING===========================================

    procedure CreateItemTrackingLines(var ItemJournalLine: Record "Item Journal Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.InitFromItemJnlLine(ItemJournalLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
        ItemTrackingLines.RunModal();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continiously scan the serial number, and all the quantity should be set to 1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] The qty of Serial1 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
        // [GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] The qty of Serial2 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
        // [GIVEN] Scan Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] The qty of Serial3 is 1  
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [THEN] Now there are five lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be five records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoInBoundWithDulplicatedSerialNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continiously scan the serial number with dulpicalted serial number, throw new error message and all the quantity should be set to 1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in ItemTrackingLine
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial No. Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');

        // [THEN] Now the quantity of Serial1 is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [GIVEN] Scan Serial No. Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');

        // [THEN] Now the initial quantity of every line is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan 'Serial1' again 
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial2');

        // [THEN] Get error message. 
        Assert.ExpectedError('Serial No. SERIAL2 already exists.');

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [THEN] Now the initial quantity of every line is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continiously scan the serial number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoInBoundWithDulplicatedSerialNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Serial No]
        // Continiously scan the serial number with dulpicalted serial number and minus qty itemtrackingline, throw new error message and all the quantity should be set to -1.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Serial No. Serial1
        ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial No. Serial2
        ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Serial No. Serial3
        ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial1 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial1');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL1 already exists.');
        // [THEN] Now the quantity of Serial1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial2 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL2 already exists.');
        // [THEN] Now the quantity of Serial2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Try to Add Scan Serial No. Serial3 again
        asserterror ItemTrackingLines.ScanSerialNoInBound('Serial3');
        // [THEN] Get error message. 
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL3 already exists.');
        // [THEN] Now the quantity of Serial3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number, and all the quantity should be set to 0.

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot3
        ItemTrackingLines.ScanLotNoInBound('Lot3');
        // [THEN] Now the quantity of Lot3 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 record inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoInBoundWithDulplicatedLotNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number with dulplicated lot numbers.
        // [SCENARIO] The rule is: for the first time scan, set qty as 0, for the second time, it should be set to 2, and then 3,4,5...

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoInPOWithDulplicatedLotNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number with dulplicated lot numbers.
        // [SCENARIO] The rule is: for the first time scan, set qty as 0, for the second time, it should be set to 2, and then 3,4,5...

        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 3 records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot3');
        // [THEN] Now the quantity of Lot3 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are 3 lines in item tracking lines.
        Assert.AreEqual(3, ItemTrackingLines.CountLines(), 'After test, there should be 3 record inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoInBoundWithDulplicatedLotNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number with dulplicated lot number in minus qty itemTrackingLines.
        Initialize();

        // [GIVEN] Create 'Lot No' specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Lot1 
        ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Now the quantity of Lot1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Now the quantity of Lot2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');

        // [GIVEN] Scan Lot1 
        asserterror ItemTrackingLines.ScanLotNoInBound('Lot1');
        // [THEN] Get error message. The error message contains Lot No. Lot1.
        Assert.ExpectedError('Lot No. LOT1');
        // [THEN] Now the quantity of Lot1 is still -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Lot2 
        asserterror ItemTrackingLines.ScanLotNoInBound('Lot2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Lot No. LOT2');
        // [THEN] Now the quantity of Lot2 is still -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be 2 records inserted.');
    end;

    local procedure CheckQuantityInTrackingSpecification(ItemTrackingLines: Page "Item Tracking Lines"; TrackingSpecification: Record "Tracking Specification"; expectedQuantity: Integer)
    begin
        ItemTrackingLines.GetRecord(TrackingSpecification);
        Assert.AreEqual(expectedQuantity, TrackingSpecification."Quantity (Base)", 'The expected quantity is unequal to current quantity!');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanPackageNoInBoundTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Lot No]
        // [SCENARIO] Continiously scan the lot number
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Add Scan Serial No. five times
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the initial quantity of every line is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the initial quantity of every line is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanPackageNoInBoundWithDulplicatedPackageNoTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // [SCENARIO] Continiously scan the package number, and all the quantity should be set to 0.
        Initialize();

        // [GIVEN] Create item 
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 2);

        // [GIVEN] Scan Pack1
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [GIVEN] Scan Pack2
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is 3.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 3);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanPackageNoInBoundMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [package No]
        // [SCENARIO] Continiously scan the package number with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanPackageNoInBoundWithDulplicatedPackageNoMinusTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [InBound] [Package No]
        // [SCENARIO] Continiously scan the dulplicated package numbers with a minus qty ItemJnlLine, and quantity should be set to -1.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", -10, '');

        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [THEN] There is no line in item tracking lines
        Assert.AreEqual(0, ItemTrackingLines.CountLines(), 'Before starting test, the item tracking line should contain nothing!');

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack1 again.
        asserterror ItemTrackingLines.ScanPackageNoInBound('Pack1');
        // [THEN] Get error message. 
        Assert.ExpectedError('Package PACK1');
        // [THEN] Now the quantity of Pack1 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [GIVEN] Scan Pack2 again.
        asserterror ItemTrackingLines.ScanPackageNoInBound('Pack2');
        // [THEN] Get error message. 
        Assert.ExpectedError('Package PACK2');
        // [THEN] Now the quantity of Pack2 is -1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, -1);

        // [THEN] Now there are two lines in item tracking lines.
        Assert.AreEqual(2, ItemTrackingLines.CountLines(), 'After test, there should be two records inserted.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoOutBoundWithExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Serial No]
        // Continiously scan the serial number, and set the corresponding quantity to 1 if serial no has been post.
        // Set the quantity to 0 if it is not post.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        CreateItemJournalLineWithItemTrackingOnLines(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        ItemJournalLine."Serial No." := 'Serial1';
        ItemJournalLine.Modify(true);

        // [GIVEN] Post this journal line
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        //[GIVEN] Scan Serial1
        ItemTrackingLines.ScanSerialNoOutBound('Serial1');
        // [THEN] Now the quantity of Serial1 is 1.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 1);

        //[GIVEN] Scan Serial2
        ItemTrackingLines.ScanSerialNoOutBound('Serial2');
        // [THEN] Now the quantity of Serial1 is 2.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

    end;

    local procedure CreateItemJournalLineWithItemTrackingOnLines(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournal(ItemJournalBatch);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, EntryType, ItemNo, Qty);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanSerialNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Serial No]
        // Continiously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Serial1.
        ItemTrackingLines.ScanSerialNoOutBound('Serial1');
        // [THEN] Now the quantity of Serial1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Serial2.
        ItemTrackingLines.ScanSerialNoOutBound('Serial2');
        // [THEN] Now the quantity of Serial2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanLotNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Lot No]
        // Continiously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create serial specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Lot1.
        ItemTrackingLines.ScanLotNoOutBound('Lot1');
        // [THEN] Now the quantity of Lot1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Lot2.
        ItemTrackingLines.ScanLotNoOutBound('Lot2');
        // [THEN] Now the quantity of Lot2 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalHandler')]
    procedure ContiniousScanPackageNoOutBoundWithOutExistingItemTest()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO] [Barcode Scanner] [OutBound] [Package No]
        // Continiously scan the serial number for out bound, the serail number doesn't exist, so init it with 0.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", WorkDate(), Item."No.", 10, '');
        // [GIVEN] Init ItemTrackingLines
        CreateItemTrackingLines(ItemJournalLine, ItemTrackingLines);

        // [GIVEN] Scan Pack1.
        ItemTrackingLines.ScanPackageNoOutBound('Pack1');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);

        // [GIVEN] Scan Pack2.
        ItemTrackingLines.ScanPackageNoOutBound('Pack2');
        // [THEN] Now the quantity of Pack1 is 0.
        CheckQuantityInTrackingSpecification(ItemTrackingLines, TrackingSpecification, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinePageModalWithQtyZeroHandler,ExitingWithQtyZeroComfirmHandler')]
    procedure WarningOfBlankQtyLinesWhenExitingWithYesReplyTest()
    var
        Item: Record Item;
        TrackingSpecification: Record "Tracking Specification";
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // [SCENARIO][DELIVERABLE 481052][Barcode Scanner] 
        // When user exits the page "Item Tracking Lines", if any line's qty is 0, inform user.
        Initialize();

        // [GIVEN] Create item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Add items 
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] Init ItemTrackingLines
        TrackingSpecification.InitFromItemJnlLine(ItemJournalLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());

        // [GIVEN] Choose 'yes' for ConfirmDialog 
        ConfirmHandlerReply := true;

        // [THEN] Open the Item Tracking Lines, and call the ItemTrackingLinePageModalWithQtyZeroHandler, an warning will show up.
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesDuplicateSNModalPageHandler')]
    procedure DuplicateSerialNumberIsNotAllowedPageOnInsert()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] It is not allowed to enter duplicate serial numbers on the item tracking lines page
        Initialize();

        // [GIVEN] Serial specific tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] User opens the item tracking lines page 
        asserterror ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] User enters the same serial number twice
        // [THEN] The line is not inserted
        Assert.ExpectedError('Tracking specification with Serial No. SERIAL1 already exists.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesDuplicateLotModalPageHandler')]
    procedure DuplicateLotNumberIsNotAllowedPageOnInsert()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingLinesTestPage: TestPage "Item Tracking Lines";
    begin
        // [SCENARIO] It is not allowed to enter duplicate lot numbers on the item tracking lines page
        Initialize();

        // [GIVEN] Lot specific tracked item
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Positive adjustment Item journal line for the item
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');

        // [GIVEN] User opens the item tracking lines page 
        ItemTrackingLinesTestPage.Trap();
        asserterror ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] User enters the same serial number twice
        // [THEN] The line is not inserted
        Assert.ExpectedError('Lot No. LOT1');
    end;

    local procedure Initialize()
    begin
        LibrarytestInitialize.OnTestInitialize(Codeunit::"Item Tracking Test");
    end;

    local procedure CreateTrackingCodeWithExp(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify();
    end;

    local procedure CreateTrackingCodeNoExp(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("Use Expiration Dates", false);
        ItemTrackingCode.Modify();
    end;

    local procedure CreateItemWithExpirationCalcFormulaAndItemTrackingCode(var Item: Record Item; ItemTrackingCode: Record "Item Tracking Code"; ExpirationDateFormulaText: Text)
    var
        ExpirationDateFormula: DateFormula;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Evaluate(ExpirationDateFormula, ExpirationDateFormulaText);
        Item.Validate("Expiration Calculation", ExpirationDateFormula);
        Item.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := ConfirmHandlerReply;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandler(var ItemList: TestPage "Item List")
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // Make sure the page handler is only called when we expect it to be called
        Assert.IsTrue(ModalHandlerExpectedToBeCalledNTimes > 0,
          'Unexpected call to the modal page handler.');

        // Go to the first item
        ItemList.First;

        // Open the item card for this item
        Item.Get(ItemList."No.".Value());
        ItemCard.OpenEdit;
        ItemCard.GotoRecord(Item);
        // Fix the item by removing the expiration date calculation
        ItemCard."Expiration Calculation".Value := '';
        ItemCard.Close();

        // Decrease the number of expected calls
        ModalHandlerExpectedToBeCalledNTimes -= 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnBeforeExistingExpirationDate', '', false, false)]
    local procedure ExpirationDateSubscriber(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; TestMultiple: Boolean; var EntriesExist: Boolean; var ExpDate: Date; var IsHandled: Boolean)
    begin
        // Make sure the subscriber is only called when expected
        Assert.IsTrue(ExpirationSubscriberExpectedToBeCalled,
          'Subscriber was not supposed to be called');
        SubscriberCalls += 1;
    end;

    [Scope('OnPrem')]
    procedure SetExpirationDateSubscriberExpectedToBeCalled(Value: Boolean)
    begin
        ExpirationSubscriberExpectedToBeCalled := Value;
        SubscriberCalls := 0; // reset subscriber calls
    end;

    [Scope('OnPrem')]
    procedure GetSubscriberCallNumber(): Integer
    begin
        exit(SubscriberCalls);
    end;

    [MessageHandler]
    procedure AlreadyExistMessageHandler(MessageText: Text[1024])
    begin
        Assert.IsSubstring(MessageText, 'already exists');
    end;

    [ConfirmHandler]
    procedure ExitingWithQtyZeroComfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := ConfirmHandlerReply;
        Assert.IsSubstring(Question, 'One or more lines have tracking specified, but Quantity (Base) is zero.');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesDuplicateSNModalPageHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines");
    var
        SerialNo: Code[50];
    begin
        // [WHEN] User enters the same serial number twice
        SerialNo := 'SERIAL1';
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Serial No.".SetValue(SerialNo);
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(1);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Serial No.".SetValue(SerialNo); //AlreadyExistMessageHandler handles the message

        // [THEN] the line is not inserted
        ItemTrackingLinesTestPage.First();
        Assert.AreEqual(1, ItemTrackingLinesTestPage."Quantity (Base)".AsDecimal(), 'The first line should be inserted');
        ItemTrackingLinesTestPage.Next();
        Assert.AreEqual(0, ItemTrackingLinesTestPage."Quantity (Base)".AsDecimal(), 'The second line should not be inserted');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesDuplicateLotModalPageHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines");
    var
        LotNo: Code[50];
    begin
        // [WHEN] User enters the same lot number twice
        LotNo := 'LOT1';
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue(LotNo);
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(5);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue(LotNo); //AlreadyExistMessageHandler handles the message

        // [THEN] the line is not inserted
        ItemTrackingLinesTestPage.First();
        Assert.AreEqual(5, ItemTrackingLinesTestPage."Quantity (Base)".AsDecimal(), 'The first line should be inserted');
        ItemTrackingLinesTestPage.Next();
        Assert.AreEqual(0, ItemTrackingLinesTestPage."Quantity (Base)".AsDecimal(), 'The second line should not be inserted');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinePageModalWithQtyZeroHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
        // [WHEN] User enters the three lot number with Qty=0
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot1');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot2');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
        ItemTrackingLinesTestPage.New();
        ItemTrackingLinesTestPage."Lot No.".SetValue('Lot3');
        ItemTrackingLinesTestPage."Quantity (Base)".SetValue(0);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinePageModalHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
    end;

    [PageHandler]
    procedure ItemTrackingLinePageHandler(var ItemTrackingLinesTestPage: TestPage "Item Tracking Lines")
    begin
    end;
}

