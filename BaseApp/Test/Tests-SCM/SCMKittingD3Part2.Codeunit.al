codeunit 137094 "SCM Kitting - D3 - Part 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Adjust Cost Item Entries] [SCM]
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        InventorySetup: Record "Inventory Setup";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        AdjSource: Option Purchase,Revaluation,"Item Card","Order Lines",Resource,"None";
        CreatePer: Option Location,Variant,"Location & Variant";
        isInitialized: Boolean;
        WorkDate2: Date;
        NothingToPostTxt: Label 'There is nothing to post to the general ledger.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Normal]
    local procedure Initialize()
    var
        MfgSetup: Record "Manufacturing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - D3 - Part 2");
        // Initialize setup.
        ClearLastError;
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - D3 - Part 2");

        // Setup Demonstration data.
        isInitialized := true;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        MfgSetup.Get;
        WorkDate2 := CalcDate(MfgSetup."Default Safety Lead Time", WorkDate); // to avoid Due Date Before Work Date message.
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryCosting.PostInvtCostToGL(false, WorkDate2, '');
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode);

        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - D3 - Part 2");
    end;

    [Normal]
    local procedure Adjustment(ParentCostingMethod: Option; CompCostingMethod: Option; AutCostPosting: Boolean; AutCostAdj: Option; AdjustHeader: Boolean; AdjSource1: Option; AdjSource2: Option): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
        ItemFilter: Text[250];
    begin
        // Setup.
        Initialize;
        LibraryAssembly.UpdateInventorySetup(InventorySetup, AutCostPosting, false, AutCostAdj,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);

        // Create Assembly BOM structure.
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, ParentCostingMethod, CompCostingMethod,
          Item."Replenishment System"::Assembly, '', not AdjustHeader);
        ItemFilter := LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);

        // Add inventory for components to allow posting.
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, LibraryRandom.RandDec(10, 2));

        // Introduce a source of adjustment.
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource1, ItemNo[1], ResourceNo[1]);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Exercise.
        // Post Assembly Order, introduce a second source of adjustment and adjust.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource2, ItemNo[1], ResourceNo[1]);
        LibraryCosting.AdjustCostItemEntries(ItemFilter, '');

        // Verify: Posted documents and entries.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyAdjustmentEntries(AssemblyHeader, AdjSource2);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        exit(AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGCompBeforePostPurchase()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Purchase, AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjFIFOCompBeforePostReval()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Revaluation, AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjSTDCompAfterPostReval()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::None, AdjSource::Revaluation);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGCompAfterPostPurchase()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::None, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGCompAfterPostItemCard()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::None, AdjSource::"Item Card");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjSTDParentBeforePostItemCard()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::"Item Card", AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjSTDParentBeforePostVariance()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::"Order Lines", AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGParentBeforePostPurchase()
    begin
        Adjustment(
          Item."Costing Method"::Average, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::Purchase, AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGParentAfterPostResource()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None, AdjSource::Resource);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjFIFOParentAfterPostReval()
    begin
        Adjustment(
          Item."Costing Method"::FIFO, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None, AdjSource::Revaluation);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjAVGParentAfterPostPurchase()
    begin
        Adjustment(
          Item."Costing Method"::Average, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AdjSTDParentAfterPostItemCard()
    begin
        Adjustment(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None, AdjSource::"Item Card");
    end;

    [Normal]
    local procedure AdjPostGL(ParentCostingMethod: Option; CompCostingMethod: Option; PerPostingGroup: Boolean; AdjustHeader: Boolean; AdjSource1: Option; AdjSource2: Option)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeaderNo: Code[20];
        DocNo: Code[20];
    begin
        // Setup. Perform adjustment scenario.
        Initialize;
        AssemblyHeaderNo :=
          Adjustment(ParentCostingMethod, CompCostingMethod, false, InventorySetup."Automatic Cost Adjustment"::Never,
            AdjustHeader, AdjSource1, AdjSource2);
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);

        // Exercise: Post Inventory cost to G/L for the selected items.
        PostedAssemblyHeader.Reset;
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo);
        PostedAssemblyHeader.FindFirst;
        if PerPostingGroup then
            DocNo := PostedAssemblyHeader."No."
        else
            DocNo := '';
        LibraryAssembly.PostInvtCostToGL(PerPostingGroup, PostedAssemblyHeader."Item No.", DocNo,
          TemporaryPath + PostedAssemblyHeader."No." + '.pdf');

        // Verify.
        LibraryAssembly.VerifyGLEntries(PostedAssemblyHeader, PerPostingGroup);

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAdjAVGCompBeforePost()
    begin
        AdjPostGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, false, AdjSource::Purchase, AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAdjFIFOCompBeforePost()
    begin
        AdjPostGL(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, false, AdjSource::Revaluation, AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAdjAVGCompAfterPost()
    begin
        AdjPostGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, false, AdjSource::None, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAdjAVGParentAfterPost()
    begin
        AdjPostGL(
          Item."Costing Method"::Average, Item."Costing Method"::Average, false, true, AdjSource::None, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAdjAVGParentPerPostGr()
    begin
        AdjPostGL(
          Item."Costing Method"::Average, Item."Costing Method"::Average, true, true, AdjSource::None, AdjSource::Purchase);
    end;

    [Normal]
    local procedure BatchAdjustment(var AssemblyHeaderNo1: Code[20]; var AssemblyHeaderNo2: Code[20]; ParentCostingMethod: Option; CompCostingMethod: Option; AutCostPosting: Boolean; AutCostAdj: Option; AdjustHeader: Boolean; AdjSource1: Option; AdjSource2: Option)
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemFilter: Text[250];
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
    begin
        // Setup.
        Initialize;
        LibraryAssembly.UpdateInventorySetup(InventorySetup, AutCostPosting, false, AutCostAdj,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);

        // First Assembly Order and its adjustment events, before and after posting.
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, ParentCostingMethod, CompCostingMethod,
          Item."Replenishment System"::Assembly, '', true);
        ItemFilter := LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, LibraryRandom.RandDec(10, 2));
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource1, ItemNo[1], ResourceNo[1]);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeaderNo1 := AssemblyHeader."No.";
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource2, ItemNo[1], ResourceNo[1]);

        // Second Assembly Order and its adjustment events, before and after posting.
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, ParentCostingMethod, CompCostingMethod,
          Item."Replenishment System"::Assembly, '', true);
        ItemFilter += '|' + CopyStr(LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader), 1, 1022);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, LibraryRandom.RandDec(10, 2));
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource1, ItemNo[1], ResourceNo[1]);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeaderNo2 := AssemblyHeader."No.";
        LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, AdjustHeader, AdjSource2, ItemNo[1], ResourceNo[1]);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ItemFilter, '');

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BatchAdjCompSTDParentAVGComp()
    begin
        BatchAdjustment(AssemblyLine."Document No.", AssemblyLine."Document No.",
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Purchase, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BatchAdjCompAVGParentFIFOComp()
    begin
        BatchAdjustment(AssemblyLine."Document No.", AssemblyLine."Document No.",
          Item."Costing Method"::Average, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Revaluation, AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BatchAdjParentSTDParentSTDComp()
    begin
        BatchAdjustment(AssemblyLine."Document No.", AssemblyLine."Document No.",
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::"Order Lines", AdjSource::"Item Card");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure BatchAdjParenFIFOParentAVGComp()
    begin
        BatchAdjustment(AssemblyLine."Document No.", AssemblyLine."Document No.",
          Item."Costing Method"::Standard, Item."Costing Method"::Average, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::Purchase, AdjSource::Revaluation);
    end;

    [Normal]
    local procedure BatchPostToGL(ParentCostingMethod: Option; CompCostingMethod: Option; AutCostPosting: Boolean; AutCostAdj: Option; AdjustHeader: Boolean; AdjSource: Option)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeaderNo1: Code[20];
        AssemblyHeaderNo2: Code[20];
    begin
        // Setup. Perform adjustment scenario.
        Initialize;
        BatchAdjustment(AssemblyHeaderNo1, AssemblyHeaderNo2,
          ParentCostingMethod, CompCostingMethod, AutCostPosting, AutCostAdj, AdjustHeader, AdjSource, AdjSource);
        LibraryAssembly.UpdateInventorySetup(InventorySetup, AutCostPosting, false, AutCostAdj,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);

        // Exercise. Post inventory cost to G/L for selected item.
        PostedAssemblyHeader.Reset;
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo1, AssemblyHeaderNo2);
        PostedAssemblyHeader.FindSet;
        LibraryAssembly.PostInvtCostToGL(false, PostedAssemblyHeader."Item No.", '',
          TemporaryPath + AssemblyHeaderNo1 + AssemblyHeaderNo2 + '.pdf');

        // Verify.
        repeat
            LibraryAssembly.VerifyGLEntries(PostedAssemblyHeader, false);
        until PostedAssemblyHeader.Next = 0;

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAdjComp()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAdjParent()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostNoAdj()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AutPostAdjComp()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, true, InventorySetup."Automatic Cost Adjustment"::Never, false,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AutPostAdjParent()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, true, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AutPostNoAdj()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, true, InventorySetup."Automatic Cost Adjustment"::Never, true,
          AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure AutPostAutAdjComp()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, true, InventorySetup."Automatic Cost Adjustment"::Always, false,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure AutPostAutAdjParent()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, true, InventorySetup."Automatic Cost Adjustment"::Always, true,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostNoAutAdj()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Always, true,
          AdjSource::None);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAutAdjComp()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::FIFO, false, InventorySetup."Automatic Cost Adjustment"::Always, false,
          AdjSource::Purchase);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAutAdjParent()
    begin
        BatchPostToGL(
          Item."Costing Method"::Standard, Item."Costing Method"::Standard, false, InventorySetup."Automatic Cost Adjustment"::Always, true,
          AdjSource::Purchase);
    end;

    [Normal]
    local procedure SKUPosting(ParentCostingMethod: Option; CompCostingMethod: Option; CreatePer: Option Location,Variant,"Location & Variant")
    var
        Item: Record Item;
        Item1: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Location: Record Location;
        BOMComponent: Record "BOM Component";
        BlankLocation: Record Location;
        LocationCode: Code[10];
        GenProdPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
    begin
        // Setup.
        Initialize;
        LocationCode := '';
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        // Prepare setup for creating SKU per Location.
        if CreatePer <> CreatePer::Variant then begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryAssembly.UpdateAssemblySetup(AssemblySetup,
              Location.Code, AssemblySetup."Copy Component Dimensions from"::"Order Header", LibraryUtility.GetGlobalNoSeriesCode);
            LocationCode := Location.Code;
        end;

        // Create Assembly BOM structure. Add inventory to allow posting.
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, LocationCode);
        BlankLocation.Init;
        LibraryInventory.UpdateInventoryPostingSetup(BlankLocation);
        LibraryAssembly.CreateItemWithSKU(
          Item, ParentCostingMethod, Item."Replenishment System"::Assembly, CreatePer, GenProdPostingGr, AsmInvtPostingGr, LocationCode);
        LibraryAssembly.CreateItemWithSKU(
          Item1, CompCostingMethod, Item."Replenishment System"::Purchase, CreatePer, GenProdPostingGr, CompInvtPostingGr, LocationCode);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", LibraryInventory.GetVariant(Item1."No.", ''),
          BOMComponent."Resource Usage Type"::Direct, LibraryRandom.RandDec(20, 5), true);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Verify: SKU cost is loaded correctly on the Assembly Order.
        LibraryAssembly.VerifySKUCost(TempAssemblyLine, AssemblyHeader);

        // Exercise. Post Assembly Order and adjust.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        LibraryCosting.AdjustCostItemEntries(Item."No." + '|' + Item1."No.", '');

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyAdjustmentEntries(AssemblyHeader, AdjSource::None);
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);

        // Tear down.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode);
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUSTDParentAVGCompVariant()
    begin
        SKUPosting(Item."Costing Method"::Standard, Item."Costing Method"::Average, CreatePer::Variant);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUFIFOParentSTDCompVariant()
    begin
        SKUPosting(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, CreatePer::Variant);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUAVGParentFIFOCompVariant()
    begin
        SKUPosting(Item."Costing Method"::Average, Item."Costing Method"::FIFO, CreatePer::Variant);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUSTDParentAVGCompLocVar()
    begin
        SKUPosting(Item."Costing Method"::Standard, Item."Costing Method"::Average, CreatePer::"Location & Variant");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUFIFOParentSTDCompLoc()
    begin
        SKUPosting(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, CreatePer::Location);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure SKUAVGParentFIFOCompLocVar()
    begin
        SKUPosting(Item."Costing Method"::Average, Item."Costing Method"::FIFO, CreatePer::"Location & Variant");
    end;

    [Normal]
    local procedure CircularRef(CostingMethod: Option; UseVariant: Boolean)
    var
        ItemVariant: Record "Item Variant";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        GenProdPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
    begin
        // Setup.
        Initialize;
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode);

        // Create circular assembly order and inventory.
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
        LibraryAssembly.CreateItem(Item, CostingMethod, Item."Replenishment System"::Purchase, GenProdPostingGr, AsmInvtPostingGr);
        if UseVariant then
            LibraryInventory.CreateVariant(ItemVariant, Item);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, WorkDate2, Item."No.", '', LibraryRandom.RandDec(10, 2), ItemVariant.Code);
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, AssemblyHeader."Item No.",
          LibraryAssembly.GetUnitOfMeasureCode(AssemblyLine.Type::Item, AssemblyHeader."Item No.", true),
          LibraryRandom.RandDec(10, 2), 0, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise. Post assembly header and adjust.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        LibraryCosting.AdjustCostItemEntries(AssemblyHeader."Item No.", '');

        // Validate.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyAdjustmentEntries(AssemblyHeader, AdjSource::None);
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDLoop()
    begin
        CircularRef(Item."Costing Method"::Standard, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AVGLoop()
    begin
        CircularRef(Item."Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure STDLoopVar()
    begin
        CircularRef(Item."Costing Method"::Standard, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AVGLoopVar()
    begin
        CircularRef(Item."Costing Method"::Average, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: Page "Assembly Availability"; var Response: Action)
    begin
        Response := ACTION::Yes; // always confirm
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingPostedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToPostTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

