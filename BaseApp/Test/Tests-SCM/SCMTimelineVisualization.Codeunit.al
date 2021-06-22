codeunit 137023 "SCM Timeline Visualization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Timeline] [SCM]
    end;

    var
        Transfer_Item: Record Item;
        Transfer_TransferLine: Record "Transfer Line";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        [RunOnClient]
        TimelineAddIn: DotNet "Microsoft.Dynamics.Nav.Client.TimelineVisualization";
        [RunOnClient]
        Control: DotNet "System.Windows.Forms.Control";
        IsInitialized: Boolean;
        Transfer_IsInitialized: Boolean;
        Text001: Label 'Unexpected requisition line. Product change in planning?';
        RefNo: Code[20];
        InvEventBufferRefOrderTypeErr: Label 'Wrong "Inventory Event Buffer"."Ref. Order Type" option value';

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Timeline Visualization");
        RequisitionLine.DeleteAll(true);
        Commit();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Timeline Visualization");
        IsInitialized := true;

        RefNo := 'REF_NO_1';

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        TimelineSetup;
        NoSeriesSetup;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Timeline Visualization");
    end;

    local procedure NoSeriesSetup()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
    end;

    local procedure Setup(var Item: Record Item; var Location: Record Location)
    begin
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
    end;

    local procedure SetupPlanning_RescheduleAndChangeQty(var RequisitionLine: Record "Requisition Line"; var TimelineEventChange: Record "Timeline Event Change"; ActionMessage: Enum "Action Message Type")
    var
        Item: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        DateSales: Date;
        DatePurchase: Date;
        QuantitySales: Integer;
        QuantityPurchase: Integer;
    begin
        // Set up items and orders to create planning line with rescheduling
        Setup(Item, Location);

        DateSales := WorkDate + LibraryRandom.RandInt(10);
        DatePurchase := DateSales;
        if ActionMessage in [RequisitionLine."Action Message"::Reschedule, RequisitionLine."Action Message"::"Resched. & Chg. Qty."] then
            DatePurchase += LibraryRandom.RandInt(10);

        QuantitySales := LibraryRandom.RandInt(20);
        QuantityPurchase := QuantitySales;
        if ActionMessage in [RequisitionLine."Action Message"::"Change Qty.",
                             RequisitionLine."Action Message"::"Resched. & Chg. Qty."]
        then
            QuantityPurchase := (QuantityPurchase - 1 + LibraryRandom.RandInt(19)) mod 20 + 1; // Random int from domain ([1..20] / {QuantitySales})

        CreateSalesOrder(Item, Location.Code, DateSales, SalesLine, SalesHeader."Document Type"::Order, QuantityPurchase);
        CreatePurchaseOrder(Item, Location.Code, DatePurchase, PurchaseLine, PurchHeader."Document Type"::Order, QuantitySales);

        SetPlanningParameters(Item, Item."Reordering Policy"::"Lot-for-Lot", 0, '<30D>');
        CreatePlanningLine(Item, RequisitionLine, DateSales, DatePurchase);

        // Test result depends on planning. Assert correct behaviour before proceeding.
        Assert.AreEqual(1, RequisitionLine.Count, Text001);
        Assert.AreEqual(ActionMessage, RequisitionLine."Action Message", Text001);

        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');
        TimelineRoundtrip(TimelineEvent, TimelineEventChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_Sunshine_OneSupply()
    begin
        Save_Sunshine(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_Sunshine_SeveralSupplies()
    begin
        Save_Sunshine(LibraryRandom.RandInt(20) + 1);
    end;

    local procedure Save_Sunshine("Count": Integer)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
        Qty: array[21] of Decimal;
        QtyAcc: Decimal;
        Date: array[21] of Date;
        LastDate: Date;
        i: Integer;
    begin
        // SETUP Location + Variant
        Setup(Item, Location);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        SetupTimeline(Item, Location.Code, ItemVariant.Code);

        // EXECUTE Create supplies and save
        LastDate := WorkDate - 20;
        for i := 1 to Count do begin
            Qty[i] := LibraryRandom.RandDecInRange(0, 20, 4);
            QtyAcc += Qty[i];
            Date[i] := LastDate + LibraryRandom.RandInt(20);
            LastDate := Date[i];
            CreateNewSupply(QtyAcc, Date[i], TimelineEventChange);
        end;

        Save(TimelineEventChange, Item, Location.Code, ItemVariant.Code);

        // VALIDATE Correct requisition lines saved
        ValidateRequsitionLineCount(RequisitionLine, Item, Count);
        for i := 1 to Count do
            ValidateRequsitionLine(RequisitionLine, Qty[i], Date[i], Location.Code, ItemVariant.Code);
    end;

    local procedure Save_ComplexFilter("Filter": Code[250]; ExpectBlank: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        Location: Record Location;
        Location2: Record Location;
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
        LocationCode: Code[10];
        VariantCode: Code[10];
        LocationFilter: Code[250];
        VariantFilter: Code[250];
        Qty: Decimal;
        Date: Date;
    begin
        // Setup: Two locations and variants
        Setup(Item, Location);
        LibraryWarehouse.CreateLocation(Location2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create and set complex filter, and save
        LocationFilter := StrSubstNo(Filter, Location.Code, Location2.Code);
        VariantFilter := StrSubstNo(Filter, ItemVariant.Code, ItemVariant2.Code);

        SetupTimeline(Item, LocationFilter, VariantFilter);

        CreateNewRandomSupply(Qty, Date, TimelineEventChange);

        Save(TimelineEventChange, Item, LocationFilter, VariantFilter);

        if ExpectBlank then begin
            LocationCode := '';
            VariantCode := '';
        end else begin
            Location.Reset();
            Location.SetFilter(Code, LocationFilter);
            Location.FindFirst;
            LocationCode := Location.Code;

            ItemVariant.Reset();
            ItemVariant.SetFilter(Code, VariantFilter);
            ItemVariant.FindFirst;
            VariantCode := ItemVariant.Code
        end;

        // Validate: Correct locations and variants on requisition lines
        ValidateRequsitionLineCount(RequisitionLine, Item, 1);
        ValidateRequsitionLine(RequisitionLine, Qty, Date, LocationCode, VariantCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_ComplexFilter_Or()
    begin
        Save_ComplexFilter('%1|%2', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_ComplexFilter_Star()
    begin
        Save_ComplexFilter('*', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_ComplexFilter_Blank()
    begin
        Save_ComplexFilter('', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Save_LocationVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        Location: Record Location;
        Location2: Record Location;
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
        Qty2: Decimal;
        Date: Date;
        Date2: Date;
    begin
        // Setup: Two locations and variants
        Setup(Item, Location);
        LibraryWarehouse.CreateLocation(Location2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Execute: Save supply to first location/variant
        SetupTimeline(Item, Location.Code, ItemVariant.Code);
        CreateNewRandomSupply(Qty, Date, TimelineEventChange);
        Save(TimelineEventChange, Item, Location.Code, ItemVariant.Code);

        // Execute: Save supply to second location/variant
        Qty2 := LibraryRandom.RandDecInRange(0, 20, 5);
        Date2 := Date + LibraryRandom.RandInt(10);
        SetupTimeline(Item, Location2.Code, ItemVariant2.Code);
        CreateNewSupply(Qty2, Date2, TimelineEventChange); // Create second supply with later date to guarantee order when validating
        Save(TimelineEventChange, Item, Location2.Code, ItemVariant2.Code);

        // Validate: Correct location/variant on requisition lines
        ValidateRequsitionLineCount(RequisitionLine, Item, 2);
        ValidateRequsitionLine(RequisitionLine, Qty, Date, Location.Code, ItemVariant.Code);
        ValidateRequsitionLine(RequisitionLine, Qty2, Date2, Location2.Code, ItemVariant2.Code);
    end;

    local procedure ValidateRequsitionLineCount(var RequisitionLine: Record "Requisition Line"; Item: Record Item; "Count": Integer)
    begin
        RequisitionLine.SetFilter("No.", Item."No.");
        Assert.AreEqual(Count, RequisitionLine.Count,
          'Excess or missing requisition lines after creating one new supply in timeline, and saving.');
        RequisitionLine.FindSet;
    end;

    local procedure ValidateRequsitionLine(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal; Date: Date; Location: Code[10]; Variant: Code[10])
    begin
        Assert.AreEqual(Quantity, RequisitionLine.Quantity,
          'Wrong quantity on requisition line after creating one new supply in timeline, and saving.');
        Assert.AreEqual(Date, RequisitionLine."Due Date",
          'Wrong due date on requisition line after creating one new supply in timeline, and saving.');
        Assert.AreEqual(Location, RequisitionLine."Location Code",
          'Wrong location on requisition line after creating one new supply in timeline, and saving.');
        Assert.AreEqual(Variant, RequisitionLine."Variant Code",
          'Wrong variant on requisition line after creating one new supply in timeline, and saving.');

        RequisitionLine.Next;
    end;

    local procedure SetupTimeline(Item: Record Item; Location: Code[250]; Variant: Code[250])
    var
        TimelineEvent: Record "Timeline Event";
        TimelineEventChange: Record "Timeline Event Change";
    begin
        GetTimelineEvents(TimelineEvent, Item, true, Location, Variant);
        TimelineRoundtrip(TimelineEvent, TimelineEventChange);
    end;

    local procedure CreateNewSupply(Qty: Decimal; Date: Date; var TimelineEventChange: Record "Timeline Event Change")
    begin
        TimelineAddIn.CreateUserTransaction(IncStr(RefNo), CreateDateTime(Date, 0T), Qty);
        ImportChangesFromTimeline(TimelineEventChange);
    end;

    local procedure CreateNewRandomSupply(var Qty: Decimal; var Date: Date; var TimelineEventChange: Record "Timeline Event Change")
    begin
        Qty := LibraryRandom.RandDecInRange(0, 20, 5);
        Date := WorkDate - 10 + LibraryRandom.RandInt(20);
        CreateNewSupply(Qty, Date, TimelineEventChange);
    end;

    local procedure Save(var TimelineEventChange: Record "Timeline Event Change"; Item: Record Item; LocationCode: Code[250]; VariantCode: Code[250])
    var
        TimelineEvent: Record "Timeline Event";
        CalcItemAvailTimeline: Codeunit "Calc. Item Avail. Timeline";
        transactionTable: DotNet DataModel_TransactionDataTable;
    begin
        CalcItemAvailTimeline.TransferChangesToPlanningWksh(TimelineEventChange, Item."No.", LocationCode, VariantCode, '', '');
        GetTimelineEvents(TimelineEvent, Item, true, LocationCode, '');
        ExportDataToTimeline(TimelineEvent, transactionTable);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_Reschedule()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::Reschedule);

        // VALIDATE: Check new/original dates & quantities
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine.Quantity, RequisitionLine.Quantity,
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_ChangeQty()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::"Change Qty.");

        // VALIDATE: Check new/original dates & quantities
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine.Quantity, RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_RescheduleAndChangeQty()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(
          RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::"Resched. & Chg. Qty.");

        // VALIDATE: Check new/original dates & quantities
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine.Quantity, RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_RescheduleAndChangeQty_Change()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(
          RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::"Resched. & Chg. Qty.");

        // EXECUTE: Change qty. and date
        SetQuantity(TimelineEventChange, 100);
        SetDate(TimelineEventChange, WorkDate);
        ImportChangesFromTimeline(TimelineEventChange);

        // VALIDATE: Check Synchronization
        ValidateTimelineEventChange(TimelineEventChange, 1,
          100, RequisitionLine."Original Quantity",
          WorkDate, RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_RescheduleAndChangeQty_Delete()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(
          RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::"Resched. & Chg. Qty.");

        // EXECUTE: Delete transaction
        TimelineAddIn.DeleteTransaction(TimelineEventChange."Reference No.");
        ImportChangesFromTimeline(TimelineEventChange);

        // TODO: Update test after correct behaviour specified
        if true then
            exit;

        // VALIDATE: Quantity is zero, date is reset
        ValidateTimelineEventChange(TimelineEventChange, 1,
          0, RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_RescheduleAndChangeQty_ManualRevertDeletesEventChange()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_RescheduleAndChangeQty(
          RequisitionLine, TimelineEventChange, RequisitionLine."Action Message"::"Resched. & Chg. Qty.");

        // EXECUTE: Manually revert changes. Line is deleted
        SetQuantity(TimelineEventChange, TimelineEventChange."Original Quantity");
        SetDate(TimelineEventChange, TimelineEventChange."Original Due Date");
        ImportChangesFromTimeline(TimelineEventChange);

        // VALIDATE: No Event change left
        Assert.AreEqual(0, TimelineEventChange.Count, 'Expected zero event line changes');
    end;

    local procedure SetupPlanning_Cancel(var RequisitionLine: Record "Requisition Line"; var TimelineEventChange: Record "Timeline Event Change")
    var
        Item: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        PurchHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Set up items and orders to create planning line with rescheduling
        Setup(Item, Location);

        CreatePurchaseOrder(
          Item, Location.Code, WorkDate + LibraryRandom.RandInt(10),
          PurchaseLine, PurchHeader."Document Type"::Order, LibraryRandom.RandInt(20));

        SetPlanningParameters(Item, Item."Reordering Policy"::"Lot-for-Lot", 0, '');
        CreatePlanningLine(Item, RequisitionLine, WorkDate, WorkDate + 10);

        // Test result depends on planning. Assert correct behaviour before proceeding.
        Assert.AreEqual(1, RequisitionLine.Count, Text001);
        Assert.AreEqual(RequisitionLine."Action Message"::Cancel, RequisitionLine."Action Message", Text001);

        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');
        TimelineRoundtrip(TimelineEvent, TimelineEventChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_Cancel()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_Cancel(RequisitionLine, TimelineEventChange);

        // VALIDATE: Check new/original dates & quantities
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine.Quantity, RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_Cancel_Change()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_Cancel(RequisitionLine, TimelineEventChange);

        // EXECUTE: Change qty. and date
        SetQuantity(TimelineEventChange, 100);
        SetDate(TimelineEventChange, WorkDate);
        ImportChangesFromTimeline(TimelineEventChange);

        // VALIDATE: Check Synchronization
        ValidateTimelineEventChange(TimelineEventChange, 1,
          100, RequisitionLine."Original Quantity",
          WorkDate, RequisitionLine."Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_Cancel_ChangeMany()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
        LibraryRandom: Codeunit "Library - Random";
        i: Integer;
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_Cancel(RequisitionLine, TimelineEventChange);

        // EXECUTE: Change qty. and date
        for i := 1 to 100 do begin
            SetQuantity(TimelineEventChange, LibraryRandom.RandDecInRange(1, 1000, 5));
            SetDate(TimelineEventChange, WorkDate + LibraryRandom.RandInt(400) - 200);
        end;
        SetQuantity(TimelineEventChange, 100);
        SetDate(TimelineEventChange, WorkDate);
        ImportChangesFromTimeline(TimelineEventChange);

        // VALIDATE: Check Synchronization
        ValidateTimelineEventChange(TimelineEventChange, 1,
          100, RequisitionLine."Original Quantity",
          WorkDate, RequisitionLine."Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_Cancel_Delete()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_Cancel(RequisitionLine, TimelineEventChange);

        // EXECUTE: Delete transactions
        TimelineAddIn.DeleteTransaction(TimelineEventChange."Reference No.");
        ImportChangesFromTimeline(TimelineEventChange);

        // TODO: Update test after correct behaviour specified
        if true then
            exit;

        // VALIDATE: Quantity is zero, date is reset
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine."Original Quantity", RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    local procedure SetupPlanning_New(var RequisitionLine: Record "Requisition Line"; var TimelineEventChange: Record "Timeline Event Change")
    var
        Item: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        Date: Date;
    begin
        // Set up items and orders to create planning line with rescheduling
        Setup(Item, Location);

        Date := WorkDate + LibraryRandom.RandInt(10) - 1;
        SetPlanningParameters(
          Item, Item."Reordering Policy"::"Lot-for-Lot", LibraryRandom.RandInt(20), '');
        CreatePlanningLine(Item, RequisitionLine, Date, Date);

        // Test result depends on planning. Assert correct behaviour before proceeding.
        Assert.AreEqual(1, RequisitionLine.Count, Text001);
        Assert.AreEqual(RequisitionLine."Action Message"::New, RequisitionLine."Action Message", Text001);

        // Hack. Planning engine doesn't produce a Requisition Line
        // when setting location code to non-blank in this scenario
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Modify(true);

        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');
        TimelineRoundtrip(TimelineEvent, TimelineEventChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_New()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_New(RequisitionLine, TimelineEventChange);

        // VALIDATE: Check new/original dates & quantities
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine.Quantity, RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_New_Change()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_New(RequisitionLine, TimelineEventChange);

        // EXECUTE: Change qty. and date
        SetQuantity(TimelineEventChange, 100);
        SetDate(TimelineEventChange, WorkDate);
        ImportChangesFromTimeline(TimelineEventChange);

        // VALIDATE: Check Synchronization
        ValidateTimelineEventChange(TimelineEventChange, 1,
          100, RequisitionLine."Original Quantity",
          WorkDate, RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_New_Delete()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_New(RequisitionLine, TimelineEventChange);

        // EXECUTE: Delete transactions
        TimelineAddIn.DeleteTransaction(TimelineEventChange."Reference No.");
        ImportChangesFromTimeline(TimelineEventChange);

        // TODO: Update test after correct behaviour specified
        if true then
            exit;

        // VALIDATE: Quantity is zero, date is reset
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine."Original Quantity", RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EventChange_New_DeleteTwice()
    var
        TimelineEventChange: Record "Timeline Event Change";
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP: Setup with planning line with Reschedule + Change qty.
        SetupPlanning_New(RequisitionLine, TimelineEventChange);

        // EXECUTE: Delete transactions
        TimelineAddIn.DeleteTransaction(TimelineEventChange."Reference No.");
        TimelineAddIn.DeleteTransaction(TimelineEventChange."Reference No.");
        ImportChangesFromTimeline(TimelineEventChange);

        // TODO: Update test after correct behaviour specified
        if true then
            exit;

        // VALIDATE: Quantity is zero, date is reset
        ValidateTimelineEventChange(TimelineEventChange, 1,
          RequisitionLine."Original Quantity", RequisitionLine."Original Quantity",
          RequisitionLine."Due Date", RequisitionLine."Original Due Date",
          Format(RequisitionLine."Action Message"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPurchase()
    var
        Item: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRefSales: RecordRef;
        RecRefPurchase: RecordRef;
        DateSales: Date;
        DatePurchase: Date;
    begin
        // Setup
        Setup(Item, Location);

        DateSales := WorkDate + LibraryRandom.RandInt(10);
        DatePurchase := DateSales + LibraryRandom.RandInt(10);

        CreateSalesOrder(Item, Location.Code, DateSales, SalesLine, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(20) + 1);
        CreatePurchaseOrder(
          Item, Location.Code, DatePurchase, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandInt(20) + 1);

        RecRefSales.GetTable(SalesLine);
        RecRefPurchase.GetTable(PurchaseLine);

        // Exercise
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');

        // Validate
        ValidateTimelineEventCount(TimelineEvent, Item, 3);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefSales), DateSales, FixedDemand, -SalesLine.Quantity);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefPurchase), DatePurchase, FixedSupply, PurchaseLine.Quantity);
    end;

    local procedure SalesOrderSetup(DocumentType: Enum "Sales Document Type"; Supply: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
        Date: Date;
        Quantity: Integer;
        Type: Option;
    begin
        // SETUP
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);
        CreateSalesOrder(Item, Location.Code, Date, SalesLine, DocumentType, LibraryRandom.RandInt(20) + 1);
        RecRef.GetTable(SalesLine);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        if Supply then begin
            Quantity := SalesLine.Quantity;
            Type := FixedSupply;
        end else begin
            Quantity := -SalesLine.Quantity;
            Type := FixedDemand;
        end;
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), Date, Type, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesOrderSetup(SalesHeader."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesOrderSetup(SalesHeader."Document Type"::"Return Order", true);
    end;

    local procedure PurchaseOrderSetup(DocumentType: Enum "Purchase Document Type"; Supply: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
        Date: Date;
        Quantity: Integer;
        Type: Option;
    begin
        // SETUP
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);
        CreatePurchaseOrder(Item, Location.Code, Date, PurchaseLine, DocumentType, LibraryRandom.RandInt(20) + 1);
        RecRef.GetTable(PurchaseLine);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');

        if Supply then begin
            Quantity := PurchaseLine.Quantity;
            Type := FixedSupply;
        end else begin
            Quantity := -PurchaseLine.Quantity;
            Type := FixedDemand;
        end;

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), Date, Type, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseOrderSetup(PurchaseHeader."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseOrderSetup(PurchaseHeader."Document Type"::"Return Order", false);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrder()
    var
        KitItem: Record Item;
        CompItem: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        RecRefHeader: RecordRef;
        RecRefLine: RecordRef;
        Date: Date;
    begin
        // SETUP
        Setup(KitItem, Location);
        LibraryInventory.CreateItem(CompItem);
        Date := WorkDate + LibraryRandom.RandInt(10);
        CreateAssemblyOrder(KitItem, CompItem, AssemblyHeader, AssemblyLine, Location.Code, Date);
        RecRefHeader.GetTable(AssemblyHeader);
        RecRefLine.GetTable(AssemblyLine);

        // EXCECUTE
        GetTimelineEvents(TimelineEvent, KitItem, IncludePlanning(true), Location.Code, '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, KitItem, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefHeader), Date, FixedSupply, AssemblyHeader.Quantity);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, CompItem, IncludePlanning(true), Location.Code, '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, CompItem, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefLine), Date - 1, FixedDemand, -AssemblyLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AssemblyRecursive()
    var
        Item: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TimelineEvent: Record "Timeline Event";
        RecRefHeader: RecordRef;
        RecRefLine: RecordRef;
        Date: Date;
    begin
        // SETUP
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);

        // EXECUTE
        CreateAssemblyOrder(Item, Item, AssemblyHeader, AssemblyLine, Location.Code, Date);
        RecRefHeader.GetTable(AssemblyHeader);
        RecRefLine.GetTable(AssemblyLine);

        // VALIDATE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');
        ValidateTimelineEventCount(TimelineEvent, Item, 3);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefLine), Date - 1, FixedDemand, -AssemblyLine.Quantity);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefHeader), Date, FixedSupply, AssemblyHeader.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderATO()
    var
        KitItem: Record Item;
        CompItem: Record Item;
        location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesLine: Record "Sales Line";
        TimelineEvent: Record "Timeline Event";
        RecRefSales: RecordRef;
        RecRefHeader: RecordRef;
        RecRefLine: RecordRef;
        Date: Date;
    begin
        // SETUP
        Setup(KitItem, location);
        Date := WorkDate + LibraryRandom.RandInt(10);

        CreateAssemblyOrderATO(KitItem, CompItem, SalesLine, AssemblyHeader, AssemblyLine, location.Code, Date);
        RecRefSales.GetTable(SalesLine);
        RecRefHeader.GetTable(AssemblyHeader);
        RecRefLine.GetTable(AssemblyLine);

        // EXECUTE KitItem
        GetTimelineEvents(TimelineEvent, KitItem, IncludePlanning(false), location.Code, '');

        // VALIDATE KitItem
        ValidateTimelineEventCount(TimelineEvent, KitItem, 3);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefSales), Date, FixedDemand, -SalesLine.Quantity);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefHeader), Date, FixedSupply, AssemblyHeader.Quantity);

        // EXECUTE CompItem
        GetTimelineEvents(TimelineEvent, CompItem, IncludePlanning(true), location.Code, '');

        // VALIDATE CompItem
        ValidateTimelineEventCount(TimelineEvent, CompItem, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefLine), Date - 1, FixedDemand, -AssemblyLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialInventory()
    var
        Item: Record Item;
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
    begin
        // SETUP
        Setup(Item, Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        CreateILE(Item, Location.Code, LibraryRandom.RandInt(20) + 1);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 1);
        Commit();
        ExpectTimelineEventILE(TimelineEvent, Item, Location.Code);

        // SETUP
        CreateILE(Item, '', LibraryRandom.RandInt(20) + 1);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), '=''''', '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 1);
        Commit();
        ExpectTimelineEventILE(TimelineEvent, Item, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLine_Demand()
    var
        item: Record Item;
        TransferLine: Record "Transfer Line";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
    begin
        // SETUP
        Initialize;
        CreateTransferLine(item, TransferLine);

        // EXCECUTE
        GetTimelineEvents(TimelineEvent, item, IncludePlanning(true), TransferLine."Transfer-from Code", '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, item, 2);
        RecRef.GetTable(TransferLine);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), TransferLine."Shipment Date", FixedDemand, -TransferLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLine_Supply()
    var
        item: Record Item;
        TransferLine: Record "Transfer Line";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
    begin
        // SETUP
        Initialize;
        CreateTransferLine(item, TransferLine);

        // EXCECUTE
        GetTimelineEvents(TimelineEvent, item, IncludePlanning(true), TransferLine."Transfer-to Code", '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, item, 2);
        RecRef.GetTable(TransferLine);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), TransferLine."Receipt Date", FixedSupply, TransferLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLine()
    var
        Item: Record Item;
        TimelineEvent: Record "Timeline Event";
        RequisitionLine: Record "Requisition Line";
        RecRef: RecordRef;
    begin
        // SETUP
        Initialize;
        LibraryInventory.CreateItem(Item);

        SetPlanningParameters(Item, Item."Reordering Policy"::"Lot-for-Lot", LibraryRandom.RandInt(10) + 1, '');
        CreatePlanningLine(Item, RequisitionLine, WorkDate, WorkDate + 1);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), '', '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        RecRef.GetTable(RequisitionLine);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), RequisitionLine."Due Date", NewSupply, RequisitionLine.Quantity);

        // EXECUTE
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(false), '', '');

        // VALIDATE
        ValidateTimelineEventCount(TimelineEvent, Item, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrder()
    var
        Item: Record Item;
        CompItem: Record Item;
        CompItem2: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
    begin
        // SETUP
        Initialize;
        CreateProductionOrder(Item, CompItem, CompItem2, ProdOrderLine, ProdOrderComponent);

        // EXECUTE Item
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(false), '', '');

        // VALIDATE Item
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        RecRef.GetTable(ProdOrderLine);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), ProdOrderLine."Due Date", FixedSupply, ProdOrderLine.Quantity);

        // EXECUTE CompItem
        GetTimelineEvents(TimelineEvent, CompItem, IncludePlanning(false), '', '');

        // VALIDATE CompItem
        RecRef.GetTable(ProdOrderComponent);
        ValidateTimelineEventCount(TimelineEvent, Item, 2); // Will just check the prod comp. line

        ExpectTimelineEvent(
          TimelineEvent, Show(RecRef), ProdOrderComponent."Due Date", FixedDemand, -ProdOrderComponent."Remaining Quantity");
        ExpectTimelineEventILE(TimelineEvent, CompItem, '');

        // EXECUTE CompItem2
        ProdOrderComponent.Next;
        GetTimelineEvents(TimelineEvent, CompItem2, IncludePlanning(false), '', '');

        // VALIDATE CompItem2
        RecRef.GetTable(ProdOrderComponent);
        ValidateTimelineEventCount(TimelineEvent, Item, 2); // Will just check the prod comp. line

        ExpectTimelineEvent(
          TimelineEvent, Show(RecRef), ProdOrderComponent."Due Date", FixedDemand, -ProdOrderComponent."Remaining Quantity");
        ExpectTimelineEventILE(TimelineEvent, CompItem2, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
    begin
        // SETUP
        Initialize;
        LibraryInventory.CreateItem(Item);
        CreateJobPlanningLine(Item, JobPlanningLine, WorkDate + LibraryRandom.RandInt(10), LibraryRandom.RandInt(20) + 1);

        // EXECUTE CompItem
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(false), '', '');

        // VALIDATE CompItem
        RecRef.GetTable(JobPlanningLine);
        ValidateTimelineEventCount(TimelineEvent, Item, 2);

        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), JobPlanningLine."Planning Date", FixedDemand, -JobPlanningLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrder()
    var
        Item: Record Item;
        CompItem: Record Item;
        ServiceLine: Record "Service Line";
        Location: Record Location;
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
        Date: Date;
    begin
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);

        CreateServiceOrder(Item, CompItem, ServiceLine, Date, Location);

        GetTimelineEventsNo(TimelineEvent, CompItem."No.", IncludePlanning(false), Location.Code);

        RecRef.GetTable(ServiceLine);

        ValidateTimelineEventCount(TimelineEvent, CompItem, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), Date, FixedDemand, -ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastEntry()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
        Date: Date;
    begin
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(3);

        CreateForecastEntry(ProductionForecastEntry, ProductionForecastName, Item, Location, LibraryRandom.RandInt(100) + 10, Date);

        GetTimelineEventsForecast(
          TimelineEvent, Item, IncludePlanning(false), Location.Code, '', ProductionForecastName.Name, true);

        RecRef.GetTable(ProductionForecastEntry);
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), Date, ExpectedDemand, -ProductionForecastEntry."Forecast Quantity (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastEntry_OtherDemands()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
        TimelineEvent: Record "Timeline Event";
        RecRefSales: RecordRef;
        RecRefForecast: RecordRef;
        Date: Date;
    begin
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);

        CreateSalesOrder(Item, Location.Code, Date, SalesLine, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(20) + 1);
        CreateForecastEntry(
          ProductionForecastEntry, ProductionForecastName, Item, Location, LibraryRandom.RandInt(100) + SalesLine.Quantity + 1, Date);

        GetTimelineEventsForecast(
          TimelineEvent, Item, IncludePlanning(false), Location.Code, '', ProductionForecastName.Name, true);

        RecRefSales.GetTable(SalesLine);
        RecRefForecast.GetTable(ProductionForecastEntry);

        ValidateTimelineEventCount(TimelineEvent, Item, 3);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRefSales), Date, FixedDemand, -SalesLine.Quantity);
        ExpectTimelineEvent(
          TimelineEvent, Show(RecRefForecast), Date, ExpectedDemand, -ProductionForecastEntry."Forecast Quantity" + SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TimelineEvent: Record "Timeline Event";
        RecRefBlanket: RecordRef;
        RecRefSales: RecordRef;
        Date: Date;
    begin
        Setup(Item, Location);
        Date := WorkDate + LibraryRandom.RandInt(10);
        CreateSalesOrder(
          Item, Location.Code, Date, SalesLine, SalesHeader."Document Type"::"Blanket Order", LibraryRandom.RandInt(100) + 21);
        CreateSalesOrder(
          Item, Location.Code, Date, SalesLine2, SalesHeader."Document Type"::Order, SalesLine.Quantity - LibraryRandom.RandInt(20));
        RecRefBlanket.GetTable(SalesLine);
        RecRefSales.GetTable(SalesLine2);

        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), Location.Code, '');
        ValidateTimelineEventCount(TimelineEvent, Item, 3);

        GetTimelineEventsSalesBlanketOrders(TimelineEvent, Item, IncludePlanning(true), Location.Code, false);
        ValidateTimelineEventCount(TimelineEvent, Item, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponent()
    var
        BOMComponent: Record "BOM Component";
        PlanningComponent: Record "Planning Component";
        Date: Date;
    begin
        Initialize;
        Date := WorkDate + LibraryRandom.RandInt(10);

        CreatePlanningComponent(BOMComponent, PlanningComponent, Date);

        repeat
            ValidatePlanningComponent(BOMComponent, PlanningComponent, Date);
        until (BOMComponent.Next = 0) or (PlanningComponent.Next = 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvEventBufferRefOrderTypeTransferFromPlanProdComp()
    var
        InventoryEventBuffer: array[5] of Record "Inventory Event Buffer";
        ReqLine: Record "Requisition Line";
    begin
        InvEventBuffTransferFromPlanProdComp(InventoryEventBuffer[1], ReqLine."Ref. Order Type"::" ");
        InvEventBuffTransferFromPlanProdComp(InventoryEventBuffer[2], ReqLine."Ref. Order Type"::Purchase);
        InvEventBuffTransferFromPlanProdComp(InventoryEventBuffer[3], ReqLine."Ref. Order Type"::"Prod. Order");
        InvEventBuffTransferFromPlanProdComp(InventoryEventBuffer[4], ReqLine."Ref. Order Type"::Transfer);
        InvEventBuffTransferFromPlanProdComp(InventoryEventBuffer[5], ReqLine."Ref. Order Type"::Assembly);

        VerifyInvEventBufferRefOrderType(InventoryEventBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvEventBufferRefOrderTypeTransferFromReqLineTransDemand()
    var
        InventoryEventBuffer: array[5] of Record "Inventory Event Buffer";
        ReqLine: Record "Requisition Line";
    begin
        InvEventBuffTransferFromReqLineTransDemand(InventoryEventBuffer[1], ReqLine."Ref. Order Type"::" ");
        InvEventBuffTransferFromReqLineTransDemand(InventoryEventBuffer[2], ReqLine."Ref. Order Type"::Purchase);
        InvEventBuffTransferFromReqLineTransDemand(InventoryEventBuffer[3], ReqLine."Ref. Order Type"::"Prod. Order");
        InvEventBuffTransferFromReqLineTransDemand(InventoryEventBuffer[4], ReqLine."Ref. Order Type"::Transfer);
        InvEventBuffTransferFromReqLineTransDemand(InventoryEventBuffer[5], ReqLine."Ref. Order Type"::Assembly);

        VerifyInvEventBufferRefOrderType(InventoryEventBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvEventBufferRefOrderTypeTransferFromReqLine()
    var
        InventoryEventBuffer: array[5] of Record "Inventory Event Buffer";
        ReqLine: Record "Requisition Line";
    begin
        InvEventBuffTransferFromReqLine(InventoryEventBuffer[1], ReqLine."Ref. Order Type"::" ");
        InvEventBuffTransferFromReqLine(InventoryEventBuffer[2], ReqLine."Ref. Order Type"::Purchase);
        InvEventBuffTransferFromReqLine(InventoryEventBuffer[3], ReqLine."Ref. Order Type"::"Prod. Order");
        InvEventBuffTransferFromReqLine(InventoryEventBuffer[4], ReqLine."Ref. Order Type"::Transfer);
        InvEventBuffTransferFromReqLine(InventoryEventBuffer[5], ReqLine."Ref. Order Type"::Assembly);

        VerifyInvEventBufferRefOrderType(InventoryEventBuffer);
    end;

    local procedure InvEventBuffTransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; RefOrderType: Option)
    var
        PlngComp: Record "Planning Component";
        ReqLine: Record "Requisition Line";
    begin
        MockReqLine(ReqLine, RefOrderType);
        PlngComp.Init();
        PlngComp."Worksheet Template Name" := ReqLine."Worksheet Template Name";
        PlngComp."Worksheet Batch Name" := ReqLine."Journal Batch Name";
        PlngComp."Worksheet Line No." := ReqLine."Line No.";
        InventoryEventBuffer.TransferFromPlanProdComp(PlngComp);
    end;

    local procedure InvEventBuffTransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; RefOrderType: Option)
    var
        ReqLine: Record "Requisition Line";
    begin
        MockReqLine(ReqLine, RefOrderType);
        InventoryEventBuffer.TransferFromReqLineTransDemand(ReqLine);
    end;

    local procedure InvEventBuffTransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; RefOrderType: Option)
    var
        ReqLine: Record "Requisition Line";
        RecRef: RecordRef;
    begin
        MockReqLine(ReqLine, RefOrderType);
        RecRef.GetTable(ReqLine);
        InventoryEventBuffer.TransferFromReqLine(ReqLine, '', WorkDate, 0, RecRef.RecordId);
    end;

    local procedure ValidatePlanningComponent(var BOMComponent: Record "BOM Component"; var PlanningComponent: Record "Planning Component"; Date: Date)
    var
        Item: Record Item;
        TimelineEvent: Record "Timeline Event";
        RecRef: RecordRef;
    begin
        Item.Get(BOMComponent."No.");
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning(true), '', '');
        RecRef.GetTable(PlanningComponent);

        ValidateTimelineEventCount(TimelineEvent, Item, 2);
        ExpectTimelineEventInitial(TimelineEvent);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), Date - 1, FixedDemand, -PlanningComponent."Expected Quantity (Base)");
    end;

    local procedure GetTimelineEvents(var TimelineEvent: Record "Timeline Event"; var Item: Record Item; IncludePlanning: Boolean; Location: Code[250]; Variant: Code[250])
    begin
        GetTimelineEventsForecast(TimelineEvent, Item, IncludePlanning, Location, Variant, '', true);
    end;

    local procedure GetTimelineEventsForecast(var TimelineEvent: Record "Timeline Event"; var Item: Record Item; IncludePlanning: Boolean; Location: Code[250]; Variant: Code[250]; Forecast: Code[10]; IncludeBlankedOrders: Boolean)
    var
        CalcItemAvailTimeline: Codeunit "Calc. Item Avail. Timeline";
    begin
        Clear(TimelineEvent);
        TimelineEvent.DeleteAll();

        Item.SetFilter("Location Filter", Location);
        Item.SetFilter("Variant Filter", Variant);
        CalcItemAvailTimeline.Initialize(Item, Forecast, IncludeBlankedOrders, 0D, IncludePlanning);

        CalcItemAvailTimeline.CreateTimelineEvents(TimelineEvent);
        Clear(TimelineEvent);
        TimelineEvent.FindSet;
    end;

    local procedure GetTimelineEventsNo(var TimelineEvent: Record "Timeline Event"; ItemNo: Code[20]; IncludePlanning: Boolean; Location: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        GetTimelineEvents(TimelineEvent, Item, IncludePlanning, Location, '');
    end;

    local procedure GetTimelineEventsSalesBlanketOrders(var TimelineEvent: Record "Timeline Event"; Item: Record Item; IncludePlanning: Boolean; Location: Code[10]; IncludeBlankedOrders: Boolean)
    begin
        GetTimelineEventsForecast(TimelineEvent, Item, IncludePlanning, Location, '', '', IncludeBlankedOrders);
    end;

    local procedure MockReqLine(var ReqLine: Record "Requisition Line"; RefOrderType: Option)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ReqLine);
        with ReqLine do begin
            Init;
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Type := Type::Item;
            "Ref. Order Type" := RefOrderType;
            Insert;
        end;
    end;

    local procedure CreateSalesOrder(Item: Record Item; LocationCode: Code[10]; ShipmentDate: Date; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Quantity: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', Item."No.", Quantity, LocationCode, ShipmentDate);
    end;

    local procedure CreatePurchaseOrder(Item: Record Item; LocationCode: Code[10]; ExpectedReceiptDate: Date; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', Item."No.", Quantity, LocationCode, ExpectedReceiptDate);
    end;

    local procedure CreateAssemblyOrder(KitItem: Record Item; CompItem: Record Item; var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Location: Code[10]; Date: Date)
    var
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate, KitItem."No.", Location, LibraryRandom.RandInt(5) + 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, CompItem."No.", '',
          LibraryRandom.RandInt(5) + 1, LibraryRandom.RandInt(5) + 1, '');
        AssemblyHeader.Validate("Due Date", Date);
        AssemblyHeader.Modify(true);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst;
    end;

    local procedure CreateAssemblyOrderATO(KitItem: Record Item; var CompItem: Record Item; var SalesLine: Record "Sales Line"; var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Location: Code[10]; Date: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(CompItem);

        CreateSalesOrder(KitItem, Location, Date, SalesLine, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(20) + 1);
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        AssemblyHeader.SetRange("Item No.", KitItem."No.");
        AssemblyHeader.FindFirst;

        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, LibraryRandom.RandInt(40) + 1);
    end;

    local procedure CreateAssemblyLine(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Item: Record Item; Quantity: Integer)
    var
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.",
          LibraryAssembly.GetUnitOfMeasureCode(AssemblyLine.Type::Item, Item."No.", true),
          Quantity, 0, '');

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindLast;
    end;

    local procedure CreateILE(Item: Record Item; Location: Code[10]; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        ItemJournalLine.DeleteAll();

        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        ItemJournalLine.Validate("Location Code", Location);
        ItemJournalLine.Validate("Variant Code", '');
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferLine(var Item: Record Item; var TransferLine: Record "Transfer Line")
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        Clear(Item);

        if Transfer_IsInitialized then begin
            Item := Transfer_Item;
            TransferLine := Transfer_TransferLine;
            exit;
        end;

        Transfer_IsInitialized := true;

        LibraryInventory.CreateItem(Transfer_Item);
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LocationInTransit.SetRange("Use As In-Transit", true);
        LocationInTransit.FindFirst;

        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(
          TransferHeader, Transfer_TransferLine, Transfer_Item."No.", LibraryRandom.RandInt(10) + 1);

        Item := Transfer_Item;
        TransferLine := Transfer_TransferLine;
    end;

    local procedure CreatePlanningLine(Item: Record Item; var RequisitionLine: Record "Requisition Line"; StartDate: Date; EndDate: Date)
    var
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        RequisitionLine.DeleteAll();
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, StartDate, EndDate, false);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst;
    end;

    local procedure CreateJobPlanningLine(Item: Record Item; var JobPlanningLine: Record "Job Planning Line"; Date: Date; Quantity: Integer)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Planning Date", Date);
        JobPlanningLine.Validate(Quantity, Quantity);

        JobPlanningLine.Modify(true);
    end;

    local procedure CreateProductionOrder(var Item: Record Item; var CompItem: Record Item; var CompItem2: Record Item; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    var
        ProductionOrder: Record "Production Order";
        CopyProdOrderComponent: Record "Prod. Order Component";
    begin
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);

        Item.Get(ProductionOrder."Source No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindSet;
        Assert.IsTrue(ProdOrderLine.Count = 1, 'Expected exactly one line on production order.');

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet;
        Assert.IsTrue(ProdOrderComponent.Count >= 2, 'Expected at least two components on production order line');

        CopyProdOrderComponent := ProdOrderComponent;
        CompItem.Get(CopyProdOrderComponent."Item No.");
        CopyProdOrderComponent.Next;
        CompItem2.Get(CopyProdOrderComponent."Item No.");
    end;

    local procedure CreateServiceOrder(Item: Record Item; var CompItem: Record Item; var ServiceLine: Record "Service Line"; Date: Date; Location: Record Location)
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryInventory.CreateItem(CompItem);
        LibrarySales.CreateCustomer(Customer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CompItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Needed by Date", Date);
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(30) + 1);
        ServiceLine.Modify(true);
    end;

    local procedure CreateForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; var ProductionForecastName: Record "Production Forecast Name"; Item: Record Item; Location: Record Location; Quantity: Integer; Date: Date)
    begin
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName.Name, Item."No.", Location.Code, Date, false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreatePlanningComponent(var BOMComponent: Record "BOM Component"; var PlanningComponent: Record "Planning Component"; Date: Date)
    var
        ItemBase: Record Item;
        Item1: Record Item;
        RequisitionLine: Record "Requisition Line";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        LibraryAssembly.CreateMultipleLvlTree(
          ItemBase, Item1, ItemBase."Replenishment System"::Assembly, ItemBase."Costing Method"::Standard, 2, 3);

        ItemBase.Validate("Reordering Policy", ItemBase."Reordering Policy"::"Fixed Reorder Qty.");
        ItemBase.Validate("Reorder Quantity", 10);
        ItemBase.Validate("Safety Stock Quantity", 20);
        ItemBase.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(ItemBase, Date, Date + 1, true);
        RequisitionLine.SetRange("No.", ItemBase."No.");
        Assert.AreEqual(1, RequisitionLine.Count, 'Unexpected- or missing planning lines');
        RequisitionLine.FindFirst;

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.FindSet;

        BOMComponent.SetRange("Parent Item No.", ItemBase."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindSet;

        Assert.AreEqual(BOMComponent.Count, PlanningComponent.Count, 'Bom component/planning component mismatch');
    end;

    local procedure ExpectTimelineEvent(var TimelineEvent: Record "Timeline Event"; ID: Text[1024]; Date: Date; Type: Option; Qty: Decimal)
    begin
        Assert.AreEqual(ID, Format(TimelineEvent."Source Line ID"),
          StrSubstNo('Wrong Source line id on Inventory Event Buffer %1', ID));
        if Date <> 0D then
            Assert.AreEqual(Date, TimelineEvent."New Date",
              StrSubstNo('Wrong Availabilty date on Inventory Event Buffer %1', ID));
        Assert.AreEqual(Type, TimelineEvent."Transaction Type",
          StrSubstNo('Wrong Type on Inventory Event Buffer %1', ID));
        Assert.AreEqual(Qty, TimelineEvent."New Quantity",
          StrSubstNo('Wrong Quantity on Inventory Event Buffer %1', ID));

        TimelineEvent.Next;
    end;

    local procedure ExpectTimelineEventInitial(var TimelineEvent: Record "Timeline Event")
    begin
        ExpectTimelineEvent(TimelineEvent, '', 0D, TimelineEvent."Transaction Type"::Initial, 0);
    end;

    local procedure ExpectTimelineEventILE(var TimelineEvent: Record "Timeline Event"; Item: Record Item; Location: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location);
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expects single posting per item');
        ItemLedgerEntry.FindFirst;

        RecRef.GetTable(ItemLedgerEntry);
        ExpectTimelineEvent(TimelineEvent, Show(RecRef), 0D, TimelineEvent."Transaction Type"::Initial, ItemLedgerEntry.Quantity);
    end;

    local procedure ValidateTimelineEventCount(var TimelineEvent: Record "Timeline Event"; Item: Record Item; Quantity: Integer)
    var
        CalcItemAvailTimeline: Codeunit "Calc. Item Avail. Timeline";
    begin
        TimelineEvent.SetFilter("Transaction Type", '<> %1', CalcItemAvailTimeline.FinalTransactionType);
        Assert.IsTrue(TimelineEvent.Count <= Quantity,
          StrSubstNo('Excess  transactions for Item %1. Expected: %2, Got: %3.', Item."No.", Quantity, TimelineEvent.Count));
        Assert.IsTrue(TimelineEvent.Count >= Quantity,
          StrSubstNo('Missing transactions for Item %1. Expected: %2, Got: %3.', Item."No.", Quantity, TimelineEvent.Count));
        TimelineEvent.FindSet;
    end;

    local procedure ValidateTimelineEventChange(var TimelineEventChange: Record "Timeline Event Change"; "Count": Integer; NewQty: Decimal; OriginalQty: Decimal; NewDate: Date; OriginalDate: Date; Type: Text[40])
    begin
        Assert.AreEqual(Count, TimelineEventChange.Count,
          StrSubstNo('Unexpected or missing TimelineEventChange line after setup with Planning line of type %1', Type));
        TimelineEventChange.TestField(Quantity, NewQty);
        TimelineEventChange.TestField("Original Quantity", OriginalQty);
        Assert.AreEqual(NewDate, TimelineEventChange."Due Date", 'Unexpected date on timeline event change');
        Assert.AreEqual(OriginalDate, TimelineEventChange."Original Due Date", 'Unexpected date on timeline event change');
        TimelineEventChange.Next;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: Page "Assembly Availability"; var Response: Action)
    begin
        Response := ACTION::Yes; // always confirm
    end;

    local procedure SetQuantity(var TimelineEventChange: Record "Timeline Event Change"; Quantity: Decimal)
    begin
        TimelineAddIn.ChangeTransactionQuantity(TimelineEventChange."Reference No.", Quantity);
    end;

    local procedure SetDate(var TimelineEventChange: Record "Timeline Event Change"; Date: Date)
    begin
        TimelineAddIn.RescheduleTransaction(TimelineEventChange."Reference No.", CreateDateTime(Date, 0T));
    end;

    local procedure Show(RecRef: RecordRef): Text[1024]
    begin
        exit(Format(RecRef.RecordId));
    end;

    local procedure IncludePlanning(Include: Boolean): Boolean
    begin
        exit(Include);
    end;

    local procedure FixedDemand(): Integer
    var
        TimelineEvent: Record "Timeline Event";
    begin
        exit(TimelineEvent."Transaction Type"::"Fixed Demand");
    end;

    local procedure FixedSupply(): Integer
    var
        TimelineEvent: Record "Timeline Event";
    begin
        exit(TimelineEvent."Transaction Type"::"Fixed Supply");
    end;

    local procedure NewSupply(): Integer
    var
        TimelineEvent: Record "Timeline Event";
    begin
        exit(TimelineEvent."Transaction Type"::"New Supply");
    end;

    local procedure ExpectedDemand(): Integer
    var
        TimelineEvent: Record "Timeline Event";
    begin
        exit(TimelineEvent."Transaction Type"::"Expected Demand");
    end;

    local procedure CreateProductionOrderSetup(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status")
    var
        Item: Record Item;
    begin
        // Create Parent and Child Items.
        CreateProdOrderItemsSetup(Item);

        // Create and Refresh Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrderStatus, Item."No.");
    end;

    local procedure CreateProdOrderItemsSetup(var Item: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        // Create Child Items.
        ClearJournal(ItemJournalBatch);
        ChildItemNo := CreateChildItemWithInventory;
        ChildItemNo2 := CreateChildItemWithInventory;

        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 100);  // Quantity per Value important.

        // Create Parent Item and attach Routing and Production BOM.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(5) + 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure ClearJournal(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateChildItemWithInventory(): Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        LibraryRandom: Codeunit "Library - Random";
    begin
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock");

        // Create Item Journal to populate Item Quantity.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(Item."No.");
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy")
    var
        LibraryRandom: Codeunit "Library - Random";
    begin
        // Random value unimportant for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, CostingMethod, LibraryRandom.RandDec(50, 2), Item."Reordering Policy",
          Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Manufacturing Policy", ItemManufacturingPolicy);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        LibraryRandom: Codeunit "Library - Random";
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure SetPlanningParameters(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; SafetyStockQuantity: Integer; ReschedulingPeriod: Text)
    var
        TmpDateformula: DateFormula;
    begin
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        if ReschedulingPeriod <> '' then begin
            Evaluate(TmpDateformula, ReschedulingPeriod);
            Item.Validate("Rescheduling Period", TmpDateformula);
            Item.Validate("Lot Accumulation Period", TmpDateformula);
        end;
        Item.Modify(true);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure TimelineRoundtrip(var TimelineEvent: Record "Timeline Event"; var TimelineEventChange: Record "Timeline Event Change")
    var
        transactionTable: DotNet DataModel_TransactionDataTable;
    begin
        ExportDataToTimeline(TimelineEvent, transactionTable);
        ImportChangesFromTimeline(TimelineEventChange);
    end;

    local procedure TimelineSetup()
    begin
        TimelineAddIn := TimelineAddIn.InteractiveTimelineVisualizationAddIn;
        Control := TimelineAddIn.Control;
        TimelineAddIn.AddSpecialDate(CurrentDateTime, 'Workdate');
    end;

    local procedure ExportDataToTimeline(var TimelineEvent: Record "Timeline Event"; var transactionTable: DotNet DataModel_TransactionDataTable)
    begin
        TimelineEvent.TransferToTransactionTable(TimelineEvent, transactionTable);
        TimelineAddIn.SetTransactions(transactionTable);
    end;

    local procedure ImportChangesFromTimeline(var TimelineEventChange: Record "Timeline Event Change")
    var
        changeTable: DotNet DataModel_TransactionChangesDataTable;
    begin
        changeTable := TimelineAddIn.GetTransactionChanges;
        TimelineEventChange.TransferFromTransactionChangeTable(TimelineEventChange, changeTable);
    end;

    local procedure VerifyInvEventBufferRefOrderType(InventoryEventBuffer: array[5] of Record "Inventory Event Buffer")
    begin
        Assert.AreEqual(
          InventoryEventBuffer[1]."Ref. Order Type"::" ",
          InventoryEventBuffer[1]."Ref. Order Type", InvEventBufferRefOrderTypeErr);
        Assert.AreEqual(
          InventoryEventBuffer[2]."Ref. Order Type"::Purchase,
          InventoryEventBuffer[2]."Ref. Order Type", InvEventBufferRefOrderTypeErr);
        Assert.AreEqual(
          InventoryEventBuffer[3]."Ref. Order Type"::"Prod. Order",
          InventoryEventBuffer[3]."Ref. Order Type", InvEventBufferRefOrderTypeErr);
        Assert.AreEqual(
          InventoryEventBuffer[4]."Ref. Order Type"::Transfer,
          InventoryEventBuffer[4]."Ref. Order Type", InvEventBufferRefOrderTypeErr);
        Assert.AreEqual(
          InventoryEventBuffer[5]."Ref. Order Type"::Assembly,
          InventoryEventBuffer[5]."Ref. Order Type", InvEventBufferRefOrderTypeErr);
    end;
}

