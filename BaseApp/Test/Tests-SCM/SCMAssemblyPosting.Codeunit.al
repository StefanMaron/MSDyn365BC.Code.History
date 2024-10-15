codeunit 137915 "SCM Assembly Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        // [FEATURE] [SCM] [Assembly]
        Initialized := false;
        MfgSetup.Get();
        WorkDate2 := CalcDate(MfgSetup."Default Safety Lead Time", WorkDate()); // to avoid Due Date Before Work Date message.
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        TextGetLastErrorText: Label 'Actual error: ''%1''. Expected: ''%2''';
        ErrItemNoEmpty: Label 'Item No. must have a value in Assembly Header:';
        ErrNotOnInventory: Label 'on inventory.';
        ErrOrderDoesNotExist: Label 'The Assembly Header does not exist';
        ErrOrderAlreadyExists: Label 'cannot be created, because it already exists or has been posted.';
        DefaultBatch: Label 'DEFAULT';
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        WorkDate2: Date;
        Initialized: Boolean;
        CnfmUpdateDimensions: Label 'Do you want to update the Dimensions on the lines?';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Posting");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Posting");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Posting");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1A_PostWithoutItem()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();
        // Post assembly order without any parent item
        CreateAssemblyOrder(AssemblyHeader, '', 0);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ErrItemNoEmpty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1B_PostWithoutQtyToAsmb()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
    begin
        Initialize();
        // Post assembly order without any qty to assemble
        LibraryInventory.CreateItem(AssembledItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        AssemblyHeader.Validate("Quantity to Assemble", 0);
        AssemblyHeader.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1C_PostWithoutLines()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
    begin
        Initialize();
        // Post assembly order without any lines
        LibraryInventory.CreateItem(AssembledItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1D_PostOnlyTextLines()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        // Post assembly order with only text lines
        LibraryInventory.CreateItem(AssembledItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::" ", '', 1, '');
        AssemblyLine.Validate(Description, 'Text 1');
        AssemblyLine.Modify(true);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::" ", '', 2, '');
        AssemblyLine.Validate(Description, 'Text 2');
        AssemblyLine.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1E_PostWithoutQtyToConsume()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
        CompItem: Record Item;
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        // Post assembly order without any Quantity to Consume
        LibraryInventory.CreateItem(AssembledItem);
        LibraryInventory.CreateItem(CompItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 20, '');
        AssemblyLine.Validate("Quantity to Consume", 0);
        AssemblyLine.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC1F_PostWithoutCompAvailable()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
        CompItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        Initialize();
        // Post assembly order without component item availability
        LibraryInventory.CreateItem(AssembledItem);
        LibraryInventory.CreateItem(CompItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 20, CompItem."Base Unit of Measure");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ErrNotOnInventory);

        // insert items and post again
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", DefaultBatch);
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, DefaultBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem."No.", 20);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, DefaultBatch);
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC2A_PostFull()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine1: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        AssemblyLine3: Record "Assembly Line";
        AssemblyLine4: Record "Assembly Line";
        AssemblyHeaderToPost: Record "Assembly Header";
        AssemblyCommentLineHeader1: Record "Assembly Comment Line";
        AssemblyCommentLineHeader2: Record "Assembly Comment Line";
        AssemblyCommentLineTextLine1: Record "Assembly Comment Line";
        AssemblyCommentLineTextLine2: Record "Assembly Comment Line";
        AssemblyCommentLineItemLine1: Record "Assembly Comment Line";
        AssemblyCommentLineItemLine2: Record "Assembly Comment Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        Initialize();
        // Post assembly order with one line of each type and verify
        CreatePostableAssemblyOrder(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);

        AssemblyHeaderToPost := AssemblyHeader;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeaderToPost, '');

        // verify that posted document is created and correct.
        VerifyPostedAssembly(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);

        // verify original order is deleted.
        asserterror AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.IsTrue(StrPos(GetLastErrorText, ErrOrderDoesNotExist) > 0,
          StrSubstNo(TextGetLastErrorText, GetLastErrorText, ErrOrderDoesNotExist));

        // delete posted assembly order
        PostedAssemblyHeader.FindLast();
        PostedAssemblyHeader.Delete(true);
        VerifyPstdAssemblyOrderDeleted(PostedAssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC2B_PostPartial()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine1: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        AssemblyLine3: Record "Assembly Line";
        AssemblyLine4: Record "Assembly Line";
        AssemblyHeaderToPost: Record "Assembly Header";
        AssemblyCommentLineHeader1: Record "Assembly Comment Line";
        AssemblyCommentLineHeader2: Record "Assembly Comment Line";
        AssemblyCommentLineTextLine1: Record "Assembly Comment Line";
        AssemblyCommentLineTextLine2: Record "Assembly Comment Line";
        AssemblyCommentLineItemLine1: Record "Assembly Comment Line";
        AssemblyCommentLineItemLine2: Record "Assembly Comment Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        Initialize();
        // partially post order using different posting dates
        CreatePostableAssemblyOrder(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);

        // make 1st posting
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble" / 3);
        AssemblyHeader.Validate("Posting Date", CalcDate('<-2D>', AssemblyHeader."Posting Date"));
        AssemblyHeader.Modify(true);
        RefreshAssemblyLines(AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4);
        AssemblyHeaderToPost.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeaderToPost, '');
        // verify that posted document is created and correct.
        VerifyPostedAssembly(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);

        // delete posted assembly order
        PostedAssemblyHeader.FindLast();
        PostedAssemblyHeader.Delete(true);
        VerifyPstdAssemblyOrderDeleted(PostedAssemblyHeader."No.");

        // make 2nd posting
        AssemblyHeader.Get(AssemblyHeaderToPost."Document Type", AssemblyHeaderToPost."No.");
        LibraryAssembly.ReopenAO(AssemblyHeader);
        AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader."Quantity to Assemble" / 3);
        AssemblyHeader.Validate("Posting Date", CalcDate('<+1D>', AssemblyHeader."Posting Date"));
        AssemblyHeader.Modify(true);
        RefreshAssemblyLines(AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4);
        AssemblyHeaderToPost := AssemblyHeader;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeaderToPost, '');
        // verify that posted document is created and correct.
        VerifyPostedAssembly(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);

        // make last posting
        AssemblyHeader.Get(AssemblyHeaderToPost."Document Type", AssemblyHeaderToPost."No.");
        LibraryAssembly.ReopenAO(AssemblyHeader);
        AssemblyHeader.Validate("Posting Date", CalcDate('<+1D>', AssemblyHeader."Posting Date"));
        AssemblyHeader.Modify(true);
        RefreshAssemblyLines(AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4);
        AssemblyHeaderToPost := AssemblyHeader;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeaderToPost, '');
        // verify that posted document is created and correct.
        VerifyPostedAssembly(AssemblyHeader, AssemblyLine1, AssemblyLine2, AssemblyLine3, AssemblyLine4,
          AssemblyCommentLineHeader1, AssemblyCommentLineHeader2,
          AssemblyCommentLineTextLine1, AssemblyCommentLineTextLine2,
          AssemblyCommentLineItemLine1, AssemblyCommentLineItemLine2);
        // verify original order is deleted.
        asserterror AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        Assert.IsTrue(StrPos(GetLastErrorText, ErrOrderDoesNotExist) > 0,
          StrSubstNo(TextGetLastErrorText, GetLastErrorText, ErrOrderDoesNotExist));

        // delete last posted assembly order
        PostedAssemblyHeader.FindLast();
        PostedAssemblyHeader.Delete(true);
        VerifyPstdAssemblyOrderDeleted(PostedAssemblyHeader."No.");

        // delete posted assembly order created from 2nd posting here
        PostedAssemblyHeader.FindLast();
        PostedAssemblyHeader.Delete(true);
        VerifyPstdAssemblyOrderDeleted(PostedAssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B230131()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
        CompItem: Record Item;
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        // Post assembly order with only text lines
        LibraryInventory.CreateItem(AssembledItem);
        LibraryInventory.CreateItem(CompItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 20, '');
        AssemblyLine.Validate("Quantity to Consume", 10);
        AssemblyLine.Validate(Type, AssemblyLine.Type::" ");
        AssemblyLine.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B231901()
    var
        AssemblyHeader: Record "Assembly Header";
        AssembledItem: Record Item;
        CompItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        Resource: Record Resource;
    begin
        Initialize();
        // Post assembly order after changing Type to Resource
        LibraryInventory.CreateItem(AssembledItem);
        LibraryInventory.CreateItem(CompItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 2);
        AssemblyHeader.Validate("Quantity to Assemble", 1);
        AssemblyHeader.Modify(true);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 2, '');
        AssemblyLine.Validate(Type, AssemblyLine.Type::Resource);
        AssemblyLine.Modify(true);
        Assert.AreEqual('', AssemblyLine."Gen. Prod. Posting Group", 'Gen. Prod. Posting Group to be blank');
        Assert.AreEqual('', AssemblyLine."Inventory Posting Group", 'Inventory Posting Group to be blank');
        LibraryResource.CreateResourceNew(Resource);
        AssemblyLine.Validate("No.", Resource."No.");
        AssemblyLine.Modify(true);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B231812()
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Record "No. Series";
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        DocumentNo: Code[10];
        OriginalManualNo: Boolean;
    begin
        Initialize();
        // set the no series of Assembly order to accept manual nos.
        AssemblySetup.Get();
        NoSeries.Get(AssemblySetup."Assembly Order Nos.");
        OriginalManualNo := NoSeries."Manual Nos.";
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify(true);
        DocumentNo := 'X00001';
        while AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, DocumentNo) or B231812_PostedAsmOrderExists(DocumentNo) do
            DocumentNo := IncStr(DocumentNo);
        // create order
        B231812_CreateAssemblyOrder(AssemblyHeader, DocumentNo);
        // post order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("No.", DocumentNo);
        Assert.AreEqual(0, AssemblyHeader.Count, 'Order should have been deleted.');
        // create another order with same doc no. - should fail
        ClearLastError();
        asserterror B231812_CreateAssemblyOrder(AssemblyHeader, DocumentNo);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrOrderAlreadyExists) > 0, '');
        // adjust cost- adjusts for first order
        LibraryCosting.AdjustCostItemEntries('', '');
        // create another order with same doc no. - should fail
        ClearLastError();
        asserterror B231812_CreateAssemblyOrder(AssemblyHeader, DocumentNo);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrOrderAlreadyExists) > 0, '');
        // deleted posted order from 1st posting
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", DocumentNo);
        PostedAssemblyHeader.FindLast();
        PostedAssemblyHeader.Delete(true);
        // create another order with same doc no. - should fail
        ClearLastError();
        asserterror B231812_CreateAssemblyOrder(AssemblyHeader, DocumentNo);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrOrderAlreadyExists) > 0, '');
        ClearLastError();
        // reset the no series to non-manual
        NoSeries.Validate("Manual Nos.", OriginalManualNo);
        NoSeries.Modify(true);
    end;

    local procedure B231812_PostedAsmOrderExists(DocumentNo: Code[20]): Boolean
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        PostedAssemblyHeader.SetCurrentKey("Order No.");
        PostedAssemblyHeader.SetRange("Order No.", DocumentNo);
        if not PostedAssemblyHeader.IsEmpty() then
            exit(true);

        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Assembly);
        InvtAdjmtEntryOrder.SetRange("Order No.", DocumentNo);
        if not InvtAdjmtEntryOrder.IsEmpty() then
            exit(true);

        exit(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAssemblyOrderWithDefaultDimensionOnLocation()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssembledItem: Record Item;
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [AssemblyOrder] [Dimension] [Global Dimension]
        // [SCENARIO] Global dimension, set on Location, should be copied to a new Assembly Order Line

        Initialize();
        // [GIVEN] New Item and Location with default dimension
        LibraryInventory.CreateItem(AssembledItem);
        LibraryWarehouse.CreateLocation(Location);

        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Assembly Order
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AssembledItem."No.", Location.Code, 1, '');

        // [WHEN] Create Assembly Order Line
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, AssembledItem."No.", 1, '');

        // [THEN] Verify that default dimension is copied to Assembly Order Line
        AssemblyLine.TestField("Dimension Set ID", AssemblyHeader."Dimension Set ID");
        AssemblyLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
    end;

    local procedure B231812_CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; DocumentNo: Code[10])
    var
        AssembledItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        Resource: Record Resource;
    begin
        LibraryInventory.CreateItem(AssembledItem);
        LibraryResource.CreateResourceNew(Resource);
        Clear(AssemblyHeader);
        AssemblyHeader.Validate("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.Validate("No.", DocumentNo);
        AssemblyHeader.Insert(true);
        AssemblyHeader.Validate("Due Date", WorkDate2);
        AssemblyHeader.Validate("Item No.", AssembledItem."No.");
        AssemblyHeader.Validate(Quantity, 1);
        AssemblyHeader.Modify(true);
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Resource, Resource."No.", 1, Resource."Base Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('VSTF277421_UpdateDimensions')]
    [Scope('OnPrem')]
    procedure VSTF277421()
    var
        CompItem: Record Item;
        Resource: Record Resource;
        AsmItem: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineItem: Record "Assembly Line";
        AssemblyLineResource: Record "Assembly Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempDimSetEntryAsmHeader: Record "Dimension Set Entry" temporary;
        TempDimSetEntryAsmResLine: Record "Dimension Set Entry" temporary;
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        DimMgt: Codeunit DimensionManagement;
    begin
        Initialize();
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);
        LibraryResource.CreateResourceNew(Resource);
        // put in inventory the component items
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", DefaultBatch);
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, DefaultBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem."No.", 200); // put in more than enough qty.
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, DefaultBatch);
        // create asm order
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 1, '');
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLineItem, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLineResource, "BOM Component Type"::Resource, Resource."No.", 1, Resource."Base Unit of Measure");
        // create dimensions
        // - on header
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        TempDimSetEntryAsmHeader."Dimension Code" := Dimension.Code;
        TempDimSetEntryAsmHeader."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntryAsmHeader."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntryAsmHeader.Insert();
        AssemblyHeader.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntryAsmHeader));
        AssemblyHeader.Modify();
        // - on resource line
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        TempDimSetEntryAsmResLine."Dimension Code" := Dimension.Code;
        TempDimSetEntryAsmResLine."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntryAsmResLine."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntryAsmResLine.Insert();
        AssemblyLineResource.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntryAsmResLine));
        AssemblyLineResource.Modify();
        // post assembly
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        // verify dimensions
        // - Posted order
        PostedAsmHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAsmHeader.FindFirst();
        Assert.AreEqual(AssemblyHeader."Dimension Set ID", PostedAsmHeader."Dimension Set ID", '');
        PostedAsmLine.SetRange("Order No.", AssemblyHeader."No.");
        PostedAsmLine.SetRange("Order Line No.", AssemblyLineItem."Line No.");
        PostedAsmLine.FindFirst();
        Assert.AreEqual(AssemblyLineItem."Dimension Set ID", PostedAsmLine."Dimension Set ID", '');
        PostedAsmLine.SetRange("Order Line No.", AssemblyLineResource."Line No.");
        PostedAsmLine.FindFirst();
        Assert.AreEqual(AssemblyLineResource."Dimension Set ID", PostedAsmLine."Dimension Set ID", '');
        // - Item Ledger Entry
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Assembly Output");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Posted Assembly");
        ItemLedgEntry.SetRange("Document No.", PostedAsmHeader."No.");
        ItemLedgEntry.FindFirst();
        Assert.AreEqual(ItemLedgEntry."Dimension Set ID", AssemblyHeader."Dimension Set ID", '');
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Assembly Consumption");
        ItemLedgEntry.FindFirst();
        Assert.AreEqual(ItemLedgEntry."Dimension Set ID", AssemblyLineItem."Dimension Set ID", '');
        // - Value Entry
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Assembly Consumption");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Posted Assembly");
        ValueEntry.SetRange("Document No.", PostedAsmHeader."No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(ValueEntry."Dimension Set ID", AssemblyLineItem."Dimension Set ID", '');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Assembly Output");
        ValueEntry.FindFirst();
        Assert.AreEqual(ValueEntry."Dimension Set ID", AssemblyHeader."Dimension Set ID", '');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.FindFirst();
        Assert.AreEqual(ValueEntry."Dimension Set ID", AssemblyLineResource."Dimension Set ID", '');
        // - Res Ledger Entry
        ResLedgEntry.SetRange("Document No.", PostedAsmHeader."No.");
        ResLedgEntry.SetRange("Resource No.", Resource."No.");
        ResLedgEntry.FindFirst();
        Assert.AreEqual(ResLedgEntry."Dimension Set ID", AssemblyLineResource."Dimension Set ID", '');
        // - Capacity Ledger Entry
        CapLedgEntry.SetRange("Document No.", PostedAsmHeader."No.");
        CapLedgEntry.SetRange("No.", Resource."No.");
        CapLedgEntry.FindFirst();
        Assert.AreEqual(CapLedgEntry."Dimension Set ID", AssemblyLineResource."Dimension Set ID", '');
    end;

    [Test]
    procedure VerifyGlobalDimensionOnItemLedgerEntryOnPostAssemblyOrder()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        ItemLedgEntry: Record "Item Ledger Entry";
        DimensionValue: array[3] of Record "Dimension Value";
    begin
        // [SCENARIO 481659] Verify Global Dimension On Item Ledger Entry On Post Assembly Order
        Initialize();

        // [GIVEN] Create Dimension Values for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[3], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Dimension Value for Global Dimension 2
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Create Location with default dimension
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Create Component and Assembly Items
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] Create Default Dimension for Component Item
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CompItem."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);

        // [GIVEN] Create and Post Item Journal Line for Assembly Item
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem."No.", 100, WorkDate(), Location.Code);

        // [GIVEN] Create Assembly Order
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", Location.Code, 1, '');
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Update Global Dimension 1 on Assembly Order Line
        AssemblyLine.Validate("Shortcut Dimension 1 Code", DimensionValue[3].Code);
        AssemblyLine.Modify(true);

        // [WHEN] Post Assembly Order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Find Posted Assembly Order
        PostedAsmHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAsmHeader.FindFirst();

        // [GIVEN] Find Item Ledger Entry for Assembly Consumption
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Assembly Consumption");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Posted Assembly");
        ItemLedgEntry.SetRange("Document No.", PostedAsmHeader."No.");
        ItemLedgEntry.FindFirst();

        // [THEN] Verify Global Dimension 1 on Item Ledger Entry
        ItemLedgEntry.TestField("Global Dimension 1 Code", DimensionValue[3].Code);
    end;

    local procedure CreateAndPostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VSTF277421_UpdateDimensions(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmUpdateDimensions) > 0, '');
        Reply := false;
    end;

    local procedure CreateResource(var Resource: Record Resource; Prefix: Code[10])
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        ResourceNo: Code[20];
        Suffix: Integer;
    begin
        while Resource.Get(Prefix + Format(Suffix)) do
            Suffix := Suffix + 1;
        ResourceNo := Prefix + Format(Suffix);
        Clear(Resource);
        Resource.Validate("No.", ResourceNo);
        Resource.Insert(true);
        UnitOfMeasure.FindFirst();
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, ResourceNo, UnitOfMeasure.Code, 1);
        Resource.Validate("Base Unit of Measure", ResourceUnitOfMeasure.Code);
        GenProdPostingGroup.FindLast();
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        VATProdPostingGroup.FindFirst();
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        Resource.Modify(true);

        // put other than default UOM
        ResourceUnitOfMeasure.SetRange("Resource No.", Resource."No.");
        ResourceUnitOfMeasure.FindFirst();
        ResourceUnitOfMeasure.Delete();
        UnitOfMeasure.FindLast();
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UnitOfMeasure.Code, 1);
        Resource.Validate("Base Unit of Measure", ResourceUnitOfMeasure.Code);
        Resource.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        if ItemNo <> '' then begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemNo, '', Quantity, '');
            exit;
        end;
        Clear(AssemblyHeader);
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader.Insert(true);
    end;

    local procedure CreateAssemblyOrderLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Type: Enum "BOM Component Type"; No: Code[20]; Quantity: Decimal; UoM: Code[10])
    var
        RecRef: RecordRef;
    begin
        if No <> '' then begin
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Type, No, UoM, Quantity, 1, '');
            exit;
        end;
        Clear(AssemblyLine);
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        RecRef.GetTable(AssemblyLine);
        AssemblyLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, AssemblyLine.FieldNo("Line No.")));
        AssemblyLine.Insert(true);
        AssemblyLine.Validate(Type, Type);
        AssemblyLine.Modify(true);
    end;

    local procedure CreatePostableAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine1: Record "Assembly Line"; var AssemblyLine2: Record "Assembly Line"; var AssemblyLine3: Record "Assembly Line"; var AssemblyLine4: Record "Assembly Line"; var AssemblyCommentLineHeader1: Record "Assembly Comment Line"; var AssemblyCommentLineHeader2: Record "Assembly Comment Line"; var AssemblyCommentLineTextLine1: Record "Assembly Comment Line"; var AssemblyCommentLineTextLine2: Record "Assembly Comment Line"; var AssemblyCommentLineItemLine1: Record "Assembly Comment Line"; var AssemblyCommentLineItemLine2: Record "Assembly Comment Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        AssembledItem: Record Item;
        CompItem: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        Resource: Record Resource;
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        ItemVariant: Record "Item Variant";
        AssemblyLocation: Record Location;
        ComponentLocation: Record Location;
        AssemblyItemUnitOfMeasure: Record "Item Unit of Measure";
        CompItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        // Create an assembly order with 4 lines:
        // one with text description, one with component and one with direct resource and last with fixed resource.
        LibraryInventory.CreateItem(AssembledItem);
        AssembledItem.Validate(Description, 'Assembly item');
        GenProdPostingGroup.Find('-');
        // Find Gen. Prod. Posting group such that it has a value in Inventory Adjustment Account
        while not (GenPostingSetup.Get('', GenProdPostingGroup.Code) and (GenPostingSetup."Inventory Adjmt. Account" <> '')) do
            GenProdPostingGroup.Next();
        AssembledItem.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        InventoryPostingGroup.Find('-');
        AssembledItem.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        CreateLocation(AssemblyLocation);
        AssembledItem.Validate("Costing Method", AssembledItem."Costing Method"::FIFO);
        AssembledItem.Validate("Unit Cost", 10);
        AssembledItem.Validate("Overhead Rate", 5);
        AssembledItem.Validate("Indirect Cost %", 3);
        AssembledItem.Validate("Last Direct Cost", 9); // adding last direct cost to get some value for Direct Cost on asm. output
        AssembledItem.Modify(true);
        UnitOfMeasure.SetFilter(Code, '<>%1', AssembledItem."Base Unit of Measure");
        UnitOfMeasure.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasure(AssemblyItemUnitOfMeasure, AssembledItem."No.", UnitOfMeasure.Code, 2); // add a new UOM

        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate(Description, 'Component item');
        GenProdPostingGroup.Next();
        // Find Gen. Prod. Posting group such that it has a value in Inventory Adjustment Account
        while not (GenPostingSetup.Get('', GenProdPostingGroup.Code) and (GenPostingSetup."Inventory Adjmt. Account" <> '')) do
            GenProdPostingGroup.Next();
        CompItem.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        InventoryPostingGroup.Next();
        CompItem.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        CreateLocation(ComponentLocation);
        CompItem.Validate("Costing Method", CompItem."Costing Method"::FIFO);
        CompItem.Validate("Unit Cost", 20);
        CompItem.Validate("Overhead Rate", 10);
        CompItem.Validate("Indirect Cost %", 6);
        CompItem.Modify(true);
        UnitOfMeasure.SetFilter(Code, '<>%1', CompItem."Base Unit of Measure");
        UnitOfMeasure.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasure(CompItemUnitOfMeasure, CompItem."No.", UnitOfMeasure.Code, 3); // add a new UOM
        LibraryInventory.CreateItemVariant(ItemVariant, CompItem."No.");
        ItemVariant.Validate(Description, 'Variant of Component item');
        ItemVariant.Modify(true);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", DefaultBatch);
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, DefaultBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem."No.", 200); // put in more than enough qty.
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Validate("Location Code", ComponentLocation.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, DefaultBatch);

        CreateResource(Resource, 'RES-');
        Resource.Validate(Name, 'Resource entity');
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        Resource.Validate("Direct Unit Cost", 10);
        Resource.Validate("Indirect Cost %", 9);
        Resource.Modify(true);
        UnitOfMeasure.SetFilter(Code, '<>%1', Resource."Base Unit of Measure");
        UnitOfMeasure.FindFirst();
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UnitOfMeasure.Code, 4); // add a new UOM

        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        AssemblyHeader.Validate("Location Code", AssemblyLocation.Code);
        AssemblyHeader.Validate("Unit of Measure Code", AssemblyItemUnitOfMeasure.Code);
        AssemblyHeader.Modify(true);
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineHeader1, AssemblyHeader."Document Type".AsInteger(),
          AssemblyHeader."No.", 0, WorkDate(), 'Comment in the header 1.');
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineHeader2, AssemblyHeader."Document Type".AsInteger(),
          AssemblyHeader."No.", 0, CalcDate('<-1M>', WorkDate()), 'Comment in the header 2.');

        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine1, "BOM Component Type"::" ", '', 0, '');
        AssemblyLine1.Validate(Description, 'Text description');
        AssemblyLine1.Modify(true);
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineTextLine1, AssemblyLine1."Document Type".AsInteger(),
          AssemblyLine1."Document No.", AssemblyLine1."Line No.", WorkDate(), 'Text comment 1.');
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineTextLine2, AssemblyLine1."Document Type".AsInteger(),
          AssemblyLine1."Document No.", AssemblyLine1."Line No.", CalcDate('<+5D>', WorkDate()), 'Text comment 2.');

        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine2, "BOM Component Type"::Item, CompItem."No.", 20, '');
        AssemblyLine2.Validate("Variant Code", ItemVariant.Code);
        AssemblyLine2.Validate("Location Code", ComponentLocation.Code);
        AssemblyLine2.Validate("Unit of Measure Code", CompItemUnitOfMeasure.Code);
        AssemblyLine2.Modify(true);
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineItemLine1, AssemblyLine2."Document Type".AsInteger(),
          AssemblyLine2."Document No.", AssemblyLine2."Line No.", WorkDate(), 'Comment for item line 1.');
        LibraryAssembly.AddAssemblyLineComment(
          AssemblyCommentLineItemLine2, AssemblyLine2."Document Type".AsInteger(),
          AssemblyLine2."Document No.", AssemblyLine2."Line No.", WorkDate(), 'Comment for item line 2.');

        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLine3, "BOM Component Type"::Resource, Resource."No.", 30, Resource."Base Unit of Measure");
        AssemblyLine3.Validate("Resource Usage Type", AssemblyLine3."Resource Usage Type"::Direct);
        AssemblyLine3.Validate("Unit of Measure Code", ResourceUnitOfMeasure.Code);
        AssemblyLine3.Modify(true);

        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLine4, "BOM Component Type"::Resource, Resource."No.", 40, Resource."Base Unit of Measure");
        AssemblyLine4.Validate("Resource Usage Type", AssemblyLine4."Resource Usage Type"::Fixed);
        AssemblyLine4.Validate(Description, 'Fixed resource usage entity');
        AssemblyLine4.Modify(true);
    end;

    local procedure RefreshAssemblyLines(var AssemblyLine1: Record "Assembly Line"; var AssemblyLine2: Record "Assembly Line"; var AssemblyLine3: Record "Assembly Line"; var AssemblyLine4: Record "Assembly Line")
    begin
        AssemblyLine1.Get(AssemblyLine1."Document Type", AssemblyLine1."Document No.", AssemblyLine1."Line No.");
        AssemblyLine2.Get(AssemblyLine2."Document Type", AssemblyLine2."Document No.", AssemblyLine2."Line No.");
        AssemblyLine3.Get(AssemblyLine3."Document Type", AssemblyLine3."Document No.", AssemblyLine3."Line No.");
        AssemblyLine4.Get(AssemblyLine4."Document Type", AssemblyLine4."Document No.", AssemblyLine4."Line No.");
    end;

    local procedure VerifyPostedAssembly(AssemblyHeader: Record "Assembly Header"; AssemblyLine1: Record "Assembly Line"; AssemblyLine2: Record "Assembly Line"; AssemblyLine3: Record "Assembly Line"; AssemblyLine4: Record "Assembly Line"; AssemblyCommentLineHeader1: Record "Assembly Comment Line"; AssemblyCommentLineHeader2: Record "Assembly Comment Line"; AssemblyCommentLineTextLine1: Record "Assembly Comment Line"; AssemblyCommentLineTextLine2: Record "Assembly Comment Line"; AssemblyCommentLineItemLine1: Record "Assembly Comment Line"; AssemblyCommentLineItemLine2: Record "Assembly Comment Line")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // get last posted document
        PostedAssemblyHeader.FindLast();

        // verify document header
        Assert.AreEqual(AssemblyHeader.Description, PostedAssemblyHeader.Description, '');
        Assert.AreEqual(AssemblyHeader."Search Description", PostedAssemblyHeader."Search Description", '');
        Assert.AreEqual(AssemblyHeader."Description 2", PostedAssemblyHeader."Description 2", '');
        Assert.AreEqual(AssemblyHeader."No.", PostedAssemblyHeader."Order No.", '');
        Assert.AreEqual(AssemblyHeader."Item No.", PostedAssemblyHeader."Item No.", '');
        Assert.AreEqual(AssemblyHeader."Variant Code", PostedAssemblyHeader."Variant Code", '');
        Assert.AreEqual(AssemblyHeader."Inventory Posting Group", PostedAssemblyHeader."Inventory Posting Group", '');
        Assert.AreEqual(AssemblyHeader."Gen. Prod. Posting Group", PostedAssemblyHeader."Gen. Prod. Posting Group", '');
        Assert.AreEqual(AssemblyHeader."Location Code", PostedAssemblyHeader."Location Code", '');
        Assert.AreEqual(AssemblyHeader."Shortcut Dimension 1 Code", PostedAssemblyHeader."Shortcut Dimension 1 Code", '');
        Assert.AreEqual(AssemblyHeader."Shortcut Dimension 2 Code", PostedAssemblyHeader."Shortcut Dimension 2 Code", '');
        Assert.AreEqual(AssemblyHeader."Posting Date", PostedAssemblyHeader."Posting Date", '');
        Assert.AreEqual(AssemblyHeader."Due Date", PostedAssemblyHeader."Due Date", '');
        Assert.AreEqual(AssemblyHeader."Bin Code", PostedAssemblyHeader."Bin Code", '');
        Assert.AreEqual(AssemblyHeader."Quantity to Assemble", PostedAssemblyHeader.Quantity, '');
        Assert.AreEqual(AssemblyHeader."Quantity to Assemble (Base)", PostedAssemblyHeader."Quantity (Base)", '');
        Assert.AreEqual(AssemblyHeader."Unit Cost", PostedAssemblyHeader."Unit Cost", '');
        Assert.AreEqual(Round(AssemblyHeader."Cost Amount" * PostedAssemblyHeader.Quantity / AssemblyHeader.Quantity),
          PostedAssemblyHeader."Cost Amount", '');
        Assert.AreEqual(AssemblyHeader."Unit of Measure Code", PostedAssemblyHeader."Unit of Measure Code", '');
        Assert.AreEqual(AssemblyHeader."Qty. per Unit of Measure", PostedAssemblyHeader."Qty. per Unit of Measure", '');
        Assert.AreEqual(AssemblyHeader."Dimension Set ID", PostedAssemblyHeader."Dimension Set ID", '');
        SourceCodeSetup.Get();
        Assert.AreEqual(SourceCodeSetup.Assembly, PostedAssemblyHeader."Source Code", '');
        // verify header comment
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", 0, 10000, AssemblyCommentLineHeader1);
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", 0, 20000, AssemblyCommentLineHeader2);

        // verify if posted document lines correct
        VerifyPostedAssemblyLine(PostedAssemblyHeader, AssemblyLine1);
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", AssemblyLine1."Line No.", 10000, AssemblyCommentLineTextLine1);
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", AssemblyLine1."Line No.", 20000, AssemblyCommentLineTextLine2);
        VerifyPostedAssemblyLine(PostedAssemblyHeader, AssemblyLine2);
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", AssemblyLine2."Line No.", 10000, AssemblyCommentLineItemLine1);
        VerifyPostedCommentLine(PostedAssemblyHeader."No.", AssemblyLine2."Line No.", 20000, AssemblyCommentLineItemLine2);
        VerifyPostedAssemblyLine(PostedAssemblyHeader, AssemblyLine3);
        VerifyPostedAssemblyLine(PostedAssemblyHeader, AssemblyLine4);

        // verify all entries
        VerifyEntries(PostedAssemblyHeader);

        // verify item registers
        VerifyRegisters(PostedAssemblyHeader);
    end;

    local procedure VerifyPostedAssemblyLine(PostedAssemblyHeader: Record "Posted Assembly Header"; AssemblyLine: Record "Assembly Line")
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // get posted document line
        PostedAssemblyLine.SetCurrentKey("Order No.", "Order Line No.");
        PostedAssemblyLine.SetRange("Order No.", AssemblyLine."Document No.");
        PostedAssemblyLine.SetRange("Order Line No.", AssemblyLine."Line No.");
        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        Assert.AreEqual(1, PostedAssemblyLine.Count, '');
        PostedAssemblyLine.FindLast();

        // verify fields matching the original assembly line
        Assert.AreEqual(AssemblyLine."Document No.", PostedAssemblyLine."Order No.", '');
        Assert.AreEqual(AssemblyLine."Line No.", PostedAssemblyLine."Order Line No.", '');
        Assert.AreEqual(AssemblyLine.Type, PostedAssemblyLine.Type, '');
        Assert.AreEqual(AssemblyLine."No.", PostedAssemblyLine."No.", '');
        Assert.AreEqual(AssemblyLine."Variant Code", PostedAssemblyLine."Variant Code", '');
        Assert.AreEqual(AssemblyLine.Description, PostedAssemblyLine.Description, '');
        Assert.AreEqual(AssemblyLine."Description 2", PostedAssemblyLine."Description 2", '');
        // Assert.AreEqual(AssemblyOrderLine."Production Lead Time",PostedAssemblyLine."Production Lead Time",'');
        Assert.AreEqual(AssemblyLine."Resource Usage Type", PostedAssemblyLine."Resource Usage Type", '');
        Assert.AreEqual(AssemblyLine."Location Code", PostedAssemblyLine."Location Code", '');
        Assert.AreEqual(AssemblyLine."Shortcut Dimension 1 Code", PostedAssemblyLine."Shortcut Dimension 1 Code", '');
        Assert.AreEqual(AssemblyLine."Shortcut Dimension 2 Code", PostedAssemblyLine."Shortcut Dimension 2 Code", '');
        Assert.AreEqual(AssemblyLine."Bin Code", PostedAssemblyLine."Bin Code", '');
        Assert.AreEqual(AssemblyLine."Quantity to Consume", PostedAssemblyLine.Quantity, '');
        Assert.AreEqual(AssemblyLine."Quantity to Consume (Base)", PostedAssemblyLine."Quantity (Base)", '');
        Assert.AreEqual(AssemblyLine."Due Date", PostedAssemblyLine."Due Date", '');
        Assert.AreEqual(AssemblyLine."Inventory Posting Group", PostedAssemblyLine."Inventory Posting Group", '');
        Assert.AreEqual(AssemblyLine."Gen. Prod. Posting Group", PostedAssemblyLine."Gen. Prod. Posting Group", '');
        Assert.AreEqual(AssemblyLine."Unit Cost", PostedAssemblyLine."Unit Cost", '');
        Assert.AreEqual(Round(AssemblyLine."Unit Cost" * AssemblyLine."Quantity to Consume"), PostedAssemblyLine."Cost Amount", '');
        Assert.AreEqual(AssemblyLine."Unit of Measure Code", PostedAssemblyLine."Unit of Measure Code", '');
        Assert.AreEqual(AssemblyLine."Dimension Set ID", PostedAssemblyLine."Dimension Set ID", '');
        Assert.AreEqual(AssemblyLine."Quantity per", PostedAssemblyLine."Quantity per", '');
        Assert.AreEqual(AssemblyLine."Qty. per Unit of Measure", PostedAssemblyLine."Qty. per Unit of Measure", '');
    end;

    local procedure VerifyPostedCommentLine(DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; OriginalAssemblyCommentLine: Record "Assembly Comment Line")
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", AssemblyCommentLine."Document Type"::"Posted Assembly");
        AssemblyCommentLine.SetRange("Document No.", DocNo);
        AssemblyCommentLine.SetRange("Document Line No.", DocLineNo);
        AssemblyCommentLine.SetRange("Line No.", LineNo);
        Assert.AreEqual(1, AssemblyCommentLine.Count, '');
        AssemblyCommentLine.FindLast();

        Assert.AreEqual(OriginalAssemblyCommentLine.Date, AssemblyCommentLine.Date, 'Comment date');
        Assert.AreEqual(OriginalAssemblyCommentLine.Comment, AssemblyCommentLine.Comment, 'Comment text');
    end;

    local procedure VerifyPstdAssemblyOrderDeleted(DocNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        PostedAssemblyCommentLine: Record "Assembly Comment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // verify header is deleted
        PostedAssemblyHeader.SetRange("No.", DocNo);
        Assert.AreEqual(0, PostedAssemblyHeader.Count, 'After deleting posted assembly header, no header should exist');

        // verify lines are deleted
        PostedAssemblyLine.SetRange("Document No.", DocNo);
        Assert.AreEqual(0, PostedAssemblyLine.Count, 'After deleting posted assembly header, no lines should exist');

        // verify comments are deleted
        PostedAssemblyCommentLine.SetCurrentKey("Document Type", "Document No.");
        PostedAssemblyCommentLine.SetRange("Document Type", PostedAssemblyCommentLine."Document Type"::"Posted Assembly");
        PostedAssemblyCommentLine.SetRange("Document No.", DocNo);
        Assert.AreEqual(0, PostedAssemblyCommentLine.Count, 'After deleting posted assembly header, no comment lines should exist');

        // verify entries are modified accordingly
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(0, ItemLedgerEntry."Document Line No.", 'Document Line No. should be emptied after deletion');
        until ItemLedgerEntry.Next() = 0;
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.FindSet();
        repeat
            Assert.AreEqual(0, ValueEntry."Document Line No.", 'Document Line No. should be emptied after deletion');
        until ValueEntry.Next() = 0;
    end;

    local procedure VerifyEntries(PostedAssemblyHeader: Record "Posted Assembly Header")
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Posted Assembly");
        ItemLedgEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        CapLedgEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Assembly);
        CapLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        ResLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ResLedgEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        ResLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Assembly);
        ResLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");

        PostedAssemblyLine.SetCurrentKey("Document No.", "Line No.");
        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        PostedAssemblyLine.FindSet();
        repeat
            ItemLedgEntry.SetRange("Document Line No.", PostedAssemblyLine."Line No.");
            ItemLedgEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
            CapLedgEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
            ResLedgEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
            if PostedAssemblyLine."Quantity (Base)" = 0 then begin
                Assert.AreEqual(0, ItemLedgEntry.Count, '');
                Assert.AreEqual(0, CapLedgEntry.Count, '');
                Assert.AreEqual(0, ResLedgEntry.Count, '');
            end else begin
                if PostedAssemblyLine.Type = PostedAssemblyLine.Type::Item then begin
                    Assert.AreEqual(1, ItemLedgEntry.Count, '');
                    ItemLedgEntry.FindFirst();
                    VerifyILE(ItemLedgEntry, PostedAssemblyLine."Document No.", PostedAssemblyLine."Line No.");
                end;
                if PostedAssemblyLine.Type = PostedAssemblyLine.Type::Resource then begin
                    Assert.AreEqual(1, CapLedgEntry.Count, '');
                    CapLedgEntry.FindFirst();
                    VerifyCapLE(CapLedgEntry, PostedAssemblyLine."Document No.", PostedAssemblyLine."Line No.");
                    Assert.AreEqual(1, ResLedgEntry.Count, '');
                    ResLedgEntry.FindFirst();
                    VerifyResLE(ResLedgEntry, PostedAssemblyLine."Document No.", PostedAssemblyLine."Line No.");
                end;
            end;
        until PostedAssemblyLine.Next() = 0;

        ItemLedgEntry.SetRange("Document Line No.", 0);
        ItemLedgEntry.SetRange("Order Line No.", 0);
        Assert.AreEqual(1, ItemLedgEntry.Count, '');
        ItemLedgEntry.FindFirst();
        VerifyILE(ItemLedgEntry, PostedAssemblyHeader."No.", 0);
        CapLedgEntry.SetRange("Order Line No.", 0);
        Assert.AreEqual(0, CapLedgEntry.Count, '');
        ResLedgEntry.SetRange("Order Line No.", 0);
        Assert.AreEqual(0, ResLedgEntry.Count, '');
    end;

    local procedure VerifyILE(ItemLedgEntry: Record "Item Ledger Entry"; PostedAssemblyDocumentNo: Code[20]; PostedAssemblyLineNo: Integer)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        Item: Record Item;
        AssemblySetup: Record "Assembly Setup";
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
        Identifier: Text[250];
    begin
        GeneralLedgerSetup.Get();
        Identifier := 'Document no: ' + PostedAssemblyDocumentNo + ', Line no.: ' + Format(PostedAssemblyLineNo);
        PostedAssemblyHeader.Get(PostedAssemblyDocumentNo);
        if PostedAssemblyLineNo <> 0 then begin
            PostedAssemblyLine.Get(PostedAssemblyDocumentNo, PostedAssemblyLineNo);
            Assert.AreEqual(PostedAssemblyLine.Type::Item, PostedAssemblyLine.Type, Identifier);
        end;
        with ItemLedgEntry do begin
            CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Posting Date", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Item No.", "Source No.", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."No.", "Document No.", Identifier);
            Assert.AreEqual("Source Type"::Item, "Source Type", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Document Date", Identifier);
            AssemblySetup.Get();
            Assert.AreEqual(AssemblySetup."Posted Assembly Order Nos.", "No. Series", Identifier);
            Assert.AreEqual("Document Type"::"Posted Assembly", "Document Type", Identifier);
            Assert.AreEqual("Order Type"::Assembly, "Order Type", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Order No.", "Order No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Line No.", "Document Line No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Order Line No.", "Order Line No.", Identifier);
            if PostedAssemblyLineNo <> 0 then begin
                Assert.AreEqual("Entry Type"::"Assembly Consumption", "Entry Type", Identifier);
                Assert.AreEqual(PostedAssemblyLine.Description, Description, Identifier);
                Assert.AreEqual(PostedAssemblyLine."Location Code", "Location Code", Identifier);
                Assert.AreEqual(-1 * PostedAssemblyLine."Quantity (Base)", Quantity, Identifier);
                Assert.AreEqual(false, Open, Identifier);
                Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
                Assert.AreEqual(false, Positive, Identifier);
                Assert.AreEqual(PostedAssemblyLine."Dimension Set ID", "Dimension Set ID", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Variant Code", "Variant Code", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Qty. per Unit of Measure", "Qty. per Unit of Measure", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Unit of Measure Code", "Unit of Measure Code", Identifier);
                Assert.AreEqual(-1 * PostedAssemblyLine."Cost Amount", Round("Cost Amount (Actual)"), Identifier);
                Assert.AreEqual(0, "Remaining Quantity", Identifier);
                Item.Get(PostedAssemblyLine."No.");
            end else begin
                Assert.AreEqual("Entry Type"::"Assembly Output", "Entry Type", Identifier);
                // Assert.AreEqual(PostedAssemblyHeader.Description,Description,Identifier);
                Assert.AreEqual('', Description, Identifier); // commented above line and added this line
                Assert.AreEqual(PostedAssemblyHeader."Location Code", "Location Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Quantity (Base)", Quantity, Identifier);
                Assert.AreEqual(true, Open, Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
                Assert.AreEqual(true, Positive, Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Dimension Set ID", "Dimension Set ID", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Variant Code", "Variant Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Qty. per Unit of Measure", "Qty. per Unit of Measure", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Unit of Measure Code", "Unit of Measure Code", Identifier);
                Item.Get(PostedAssemblyHeader."Item No.");
                UnitCost := Item."Overhead Rate" + Item."Last Direct Cost" * (1 + Item."Indirect Cost %" / 100);
                Assert.AreNearlyEqual(
                  Round(PostedAssemblyHeader."Quantity (Base)" * UnitCost, GeneralLedgerSetup."Amount Rounding Precision"),
                  "Cost Amount (Actual)", GeneralLedgerSetup."Amount Rounding Precision", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Quantity (Base)", "Remaining Quantity", Identifier);
            end;
            Assert.AreEqual(Item."Item Category Code", "Item Category Code", Identifier);
            Assert.AreEqual(Item."No.", "Item No.", Identifier);
            Assert.AreEqual(Quantity, "Invoiced Quantity", Identifier);
            Assert.AreEqual(true, "Completely Invoiced", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Last Invoice Date", Identifier);
            Assert.AreEqual(0, "Cost Amount (Expected)", Identifier);
            // "Applies-to Entry"
            // "Drop Shipment"
            // "Transaction Type"
            // "Transport Method"
            // "Country/Region Code"
            // "Entry/Exit Point"
            // "External Document No."
            // Area
            // "Transaction Specification"
            // "Job No."
            // "Job Task No."
            // "Job Purchase"
            // "Applied Entry to Adjust"
            // Correction
            // "Serial No."
            // "Lot No."
            // "Warranty Date"
            // "Expiration Date"
            // "Item Tracking"
            // "Reserved Quantity"
        end;

        ValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ValueEntry.SetRange("Document Type", ItemLedgEntry."Document Type");
        ValueEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        ValueEntry.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Assembly);
        ValueEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        if PostedAssemblyLineNo <> 0 then
            ValueEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.")
        else begin
            ValueEntry.SetRange("Order Line No.", 0);
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
            Assert.AreEqual(1, ValueEntry.Count, Identifier);
            ValueEntry.FindFirst();
            VerifyVE(ValueEntry, PostedAssemblyDocumentNo, PostedAssemblyLineNo);
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        end;
        Assert.AreEqual(1, ValueEntry.Count, Identifier);
        ValueEntry.FindFirst();
        VerifyVE(ValueEntry, PostedAssemblyDocumentNo, PostedAssemblyLineNo);
    end;

    local procedure VerifyVE(ValueEntry: Record "Value Entry"; PostedAssemblyDocumentNo: Code[20]; PostedAssemblyLineNo: Integer)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        Resource: Record Resource;
        Item: Record Item;
        SourceCodeSetup: Record "Source Code Setup";
        Identifier: Text[250];
    begin
        GeneralLedgerSetup.Get();
        Identifier := 'Document no: ' + PostedAssemblyDocumentNo + ', Line no.: ' + Format(PostedAssemblyLineNo);
        PostedAssemblyHeader.Get(PostedAssemblyDocumentNo);
        if PostedAssemblyLineNo <> 0 then begin
            PostedAssemblyLine.Get(PostedAssemblyDocumentNo, PostedAssemblyLineNo);
            Assert.IsTrue(PostedAssemblyLine.Type in [PostedAssemblyLine.Type::Item, PostedAssemblyLine.Type::Resource], Identifier);
        end;

        // get the ILE OR CapLE
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Document Type", ValueEntry."Document Type");
        ItemLedgEntry.SetRange("Document No.", ValueEntry."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", ValueEntry."Document Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        ItemLedgEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
        if ItemLedgEntry.FindFirst() then;
        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        CapLedgEntry.SetRange("Document No.", ValueEntry."Document No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Assembly);
        CapLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        CapLedgEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
        if CapLedgEntry.FindFirst() then begin
            Assert.AreEqual(PostedAssemblyLine.Type::Resource, PostedAssemblyLine.Type, Identifier);
            Assert.AreEqual(CapLedgEntry.Type::Resource, CapLedgEntry.Type, Identifier);
        end;

        with ValueEntry do begin
            if PostedAssemblyLineNo <> 0 then begin
                case PostedAssemblyLine.Type of
                    PostedAssemblyLine.Type::Item:
                        begin
                            Assert.AreEqual(PostedAssemblyLine."No.", "Item No.", Identifier);
                            Assert.AreEqual('', "No.", Identifier);
                            Assert.AreEqual("Item Ledger Entry Type"::"Assembly Consumption", "Item Ledger Entry Type", Identifier);
                            Assert.AreEqual(-1 * PostedAssemblyLine."Quantity (Base)", "Valued Quantity", Identifier);
                            Assert.AreEqual(-1 * PostedAssemblyLine."Quantity (Base)", "Invoiced Quantity", Identifier);
                            if PostedAssemblyLine."Unit Cost" <> "Cost per Unit" then
                                Assert.AreEqual(Round(PostedAssemblyLine."Unit Cost" / PostedAssemblyLine."Qty. per Unit of Measure"),
                                  Round("Cost per Unit"), Identifier);
                            Assert.AreEqual(-1 * PostedAssemblyLine."Cost Amount", Round("Cost Amount (Actual)"), Identifier);
                            Assert.AreEqual("Entry Type"::"Direct Cost", "Entry Type", Identifier);
                            Assert.AreEqual(PostedAssemblyLine."Inventory Posting Group", "Inventory Posting Group", Identifier);
                        end;
                    PostedAssemblyLine.Type::Resource:
                        begin
                            Assert.AreEqual('', "Item No.", Identifier);
                            Assert.AreEqual(PostedAssemblyLine."No.", "No.", Identifier);
                            Assert.AreEqual("Item Ledger Entry Type"::" ", "Item Ledger Entry Type", Identifier);
                            Assert.AreEqual(PostedAssemblyLine."Quantity (Base)", "Valued Quantity", Identifier);
                            Assert.IsTrue("Entry Type" in ["Entry Type"::"Direct Cost", "Entry Type"::"Indirect Cost"], Identifier);
                            Resource.Get("No.");
                            case "Entry Type" of
                                "Entry Type"::"Direct Cost":
                                    begin
                                        if Resource."Direct Unit Cost" <> "Cost per Unit" then
                                            Assert.AreEqual(Round(Resource."Direct Unit Cost"), Round("Cost per Unit"), Identifier);
                                        Assert.AreEqual(Round(Resource."Direct Unit Cost" * PostedAssemblyLine."Quantity (Base)"),
                                          "Cost Amount (Actual)", Identifier);
                                        Assert.AreEqual(PostedAssemblyLine."Quantity (Base)", "Invoiced Quantity", Identifier);
                                    end;
                                "Entry Type"::"Indirect Cost":
                                    begin
                                        if Resource."Unit Cost" - Resource."Direct Unit Cost" <> "Cost per Unit" then
                                            Assert.AreEqual(Round(Resource."Unit Cost" - Resource."Direct Unit Cost"), Round("Cost per Unit"), Identifier);
                                        Assert.AreEqual(Round("Cost per Unit" * PostedAssemblyLine."Quantity (Base)"),
                                          "Cost Amount (Actual)", Identifier);
                                        Assert.AreEqual(0, "Invoiced Quantity", Identifier);
                                    end;
                            end;
                            Assert.AreEqual('', "Inventory Posting Group", Identifier);
                        end;
                end;
                Assert.AreEqual(ItemLedgEntry.Quantity, "Item Ledger Entry Quantity", Identifier);
                Assert.AreEqual(PostedAssemblyLine.Description, Description, Identifier);
                Assert.AreEqual(PostedAssemblyLine."Location Code", "Location Code", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Gen. Prod. Posting Group", "Gen. Prod. Posting Group", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Dimension Set ID", "Dimension Set ID", Identifier);
                Assert.AreEqual(PostedAssemblyLine."Variant Code", "Variant Code", Identifier);
            end else begin
                Assert.AreEqual(PostedAssemblyHeader."Item No.", "Item No.", Identifier);
                Assert.AreEqual('', "No.", Identifier);
                Assert.AreEqual("Item Ledger Entry Type"::"Assembly Output", "Item Ledger Entry Type", Identifier);
                Item.Get("Item No.");
                if Item.Description <> PostedAssemblyHeader.Description then
                    Assert.AreEqual(PostedAssemblyHeader.Description, Description, Identifier)
                else
                    Assert.AreEqual('', Description, Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Location Code", "Location Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Inventory Posting Group", "Inventory Posting Group", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Quantity (Base)", "Valued Quantity", Identifier);
                case "Entry Type" of
                    "Entry Type"::"Indirect Cost":
                        begin
                            Assert.AreEqual(0, "Invoiced Quantity", Identifier);
                            Assert.AreEqual(Round(Item."Overhead Rate" + Item."Last Direct Cost" * Item."Indirect Cost %" / 100),
                              Round("Cost per Unit"), Identifier);
                            Assert.AreEqual(0, "Item Ledger Entry Quantity", Identifier);
                        end;
                    "Entry Type"::"Direct Cost":
                        begin
                            Assert.AreEqual(PostedAssemblyHeader."Quantity (Base)", "Invoiced Quantity", Identifier);
                            Assert.AreEqual(Round(Item."Last Direct Cost"), Round("Cost per Unit"), Identifier);
                            Assert.AreEqual(ItemLedgEntry.Quantity, "Item Ledger Entry Quantity", Identifier);
                        end;
                end;
                Assert.AreNearlyEqual(
                  Round("Cost per Unit" * PostedAssemblyHeader."Quantity (Base)", GeneralLedgerSetup."Amount Rounding Precision"),
                  "Cost Amount (Actual)", GeneralLedgerSetup."Amount Rounding Precision", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Gen. Prod. Posting Group", "Gen. Prod. Posting Group", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Dimension Set ID", "Dimension Set ID", Identifier);
                Assert.AreEqual(PostedAssemblyHeader."Variant Code", "Variant Code", Identifier);
                Assert.IsTrue("Entry Type" in ["Entry Type"::"Direct Cost", "Entry Type"::"Indirect Cost"], Identifier);
            end;
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Posting Date", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Item No.", "Source No.", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."No.", "Document No.", Identifier);
            Assert.AreEqual('', "Source Posting Group", Identifier);
            Assert.AreEqual(ItemLedgEntry."Entry No.", "Item Ledger Entry No.", Identifier);
            // "Sales Amount (Actual)"
            // "Salespers./Purch. Code"
            // "Discount Amount"
            Assert.AreEqual(UpperCase(UserId), "User ID", Identifier);
            SourceCodeSetup.Get();
            Assert.AreEqual(SourceCodeSetup.Assembly, "Source Code", Identifier);
            // "Applies-to Entry"
            Assert.AreEqual("Source Type"::Item, "Source Type", Identifier);
            Assert.AreEqual(0, "Cost Posted to G/L", Identifier);
            // "Reason Code"
            // "Drop Shipment"
            Assert.AreEqual('', "Journal Batch Name", Identifier);
            Assert.AreEqual('', "Gen. Bus. Posting Group", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Document Date", Identifier);
            // "External Document No."
            Assert.AreEqual(0, "Cost Posted to G/L (ACY)", Identifier);
            Assert.AreEqual(0, "Cost Amount (Actual) (ACY)", Identifier);
            Assert.AreEqual(0, "Cost per Unit (ACY)", Identifier);
            Assert.AreEqual("Document Type"::"Posted Assembly", "Document Type", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Line No.", "Document Line No.", Identifier);
            Assert.AreEqual("Order Type"::Assembly, "Order Type", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Order No.", "Order No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Order Line No.", "Order Line No.", Identifier);
            Assert.AreEqual(false, "Expected Cost", Identifier);
            // "Item Charge No."
            // "Valued By Average Cost"
            // "Partial Revaluation"
            // Inventoriable
            if "Item Ledger Entry Type" = "Item Ledger Entry Type"::"Assembly Consumption" then
                Assert.AreEqual(WorkDate(), "Valuation Date", Identifier) // special case- may be a bug!!!
            else
                Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Valuation Date", Identifier);
            Assert.AreEqual("Variance Type"::" ", "Variance Type", Identifier);
            Assert.AreEqual(0, "Cost Amount (Expected)", Identifier);
            Assert.AreEqual(0, "Expected Cost Posted to G/L", Identifier);
            // "Job No."
            // "Job Task No."
            // "Job Ledger Entry No."
            Assert.AreEqual(false, Adjustment, Identifier);
            // "Average Cost Exception"
            Assert.AreEqual(CapLedgEntry."Entry No.", "Capacity Ledger Entry No.", Identifier);
            if CapLedgEntry.IsEmpty() then
                Assert.AreEqual(CapLedgEntry.Type::" ", Type, Identifier)
            else
                Assert.AreEqual(CapLedgEntry.Type, Type, Identifier);
            Assert.AreEqual('', "Return Reason Code", Identifier);
        end;
    end;

    local procedure VerifyCapLE(CapLedgEntry: Record "Capacity Ledger Entry"; PostedAssemblyDocumentNo: Code[20]; PostedAssemblyLineNo: Integer)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        ValueEntry: Record "Value Entry";
        Identifier: Text[250];
    begin
        Identifier := 'Document no: ' + PostedAssemblyDocumentNo + ', Line no.: ' + Format(PostedAssemblyLineNo);
        PostedAssemblyHeader.Get(PostedAssemblyDocumentNo);
        PostedAssemblyLine.Get(PostedAssemblyDocumentNo, PostedAssemblyLineNo);
        Assert.AreEqual(PostedAssemblyLine.Type::Resource, PostedAssemblyLine.Type, Identifier);
        with CapLedgEntry do begin
            CalcFields("Direct Cost", "Overhead Cost");
            Assert.AreEqual(PostedAssemblyLine."No.", "No.", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Posting Date", Identifier);
            Assert.AreEqual(Type::Resource, Type, Identifier);
            Assert.AreEqual(PostedAssemblyHeader."No.", "Document No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine.Description, Description, Identifier);
            Assert.AreEqual('', "Operation No.", Identifier);
            Assert.AreEqual('', "Work Center No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Quantity (Base)", Quantity, Identifier);
            Assert.AreEqual(0, "Setup Time", Identifier);
            Assert.AreEqual(0, "Run Time", Identifier);
            Assert.AreEqual(0, "Stop Time", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Quantity (Base)", "Invoiced Quantity", Identifier);
            Assert.AreEqual(0, "Output Quantity", Identifier);
            Assert.AreEqual(0, "Scrap Quantity", Identifier);
            // "Concurrent Capacity"
            Assert.AreEqual(PostedAssemblyLine."Unit of Measure Code", "Cap. Unit of Measure Code", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Qty. per Unit of Measure", "Qty. per Cap. Unit of Measure", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
            // "Last Output Line"
            Assert.AreEqual(true, "Completely Invoiced", Identifier);
            Assert.AreEqual(0T, "Starting Time", Identifier);
            Assert.AreEqual(0T, "Ending Time", Identifier);
            Assert.AreEqual('', "Routing No.", Identifier);
            Assert.AreEqual(0, "Routing Reference No.", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Item No.", "Item No.", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Variant Code", "Variant Code", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Unit of Measure Code", "Unit of Measure Code", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Qty. per Unit of Measure", "Qty. per Unit of Measure", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Document Date", Identifier);
            // "External Document No."
            Assert.AreEqual('', "Stop Code", Identifier);
            Assert.AreEqual('', "Scrap Code", Identifier);
            Assert.AreEqual('', "Work Center Group Code", Identifier);
            Assert.AreEqual('', "Work Shift Code", Identifier);
            Assert.AreEqual(false, Subcontracting, Identifier);
            Assert.AreEqual("Order Type"::Assembly, "Order Type", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Order No.", "Order No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Order Line No.", "Order Line No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Dimension Set ID", "Dimension Set ID", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Cost Amount", "Direct Cost" + "Overhead Cost", Identifier);
            Assert.AreEqual(0, "Direct Cost (ACY)", Identifier);
            Assert.AreEqual(0, "Overhead Cost (ACY)", Identifier);
        end;

        ValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Assembly);
        ValueEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        ValueEntry.SetRange("Order Line No.", PostedAssemblyLine."Order Line No.");
        ValueEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        Assert.AreEqual(1, ValueEntry.Count, Identifier);
        ValueEntry.FindFirst();
        VerifyVE(ValueEntry, PostedAssemblyDocumentNo, PostedAssemblyLineNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        Assert.AreEqual(1, ValueEntry.Count, Identifier);
        ValueEntry.FindFirst();
        VerifyVE(ValueEntry, PostedAssemblyDocumentNo, PostedAssemblyLineNo);
    end;

    local procedure VerifyResLE(ResLedgEntry: Record "Res. Ledger Entry"; PostedAssemblyDocumentNo: Code[20]; PostedAssemblyLineNo: Integer)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        Resource: Record Resource;
        AssemblySetup: Record "Assembly Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Identifier: Text[250];
    begin
        Identifier := 'Document no: ' + PostedAssemblyDocumentNo + ', Line no.: ' + Format(PostedAssemblyLineNo);
        PostedAssemblyHeader.Get(PostedAssemblyDocumentNo);
        PostedAssemblyLine.Get(PostedAssemblyDocumentNo, PostedAssemblyLineNo);
        Assert.AreEqual(PostedAssemblyLine.Type::Resource, PostedAssemblyLine.Type, Identifier);
        with ResLedgEntry do begin
            Assert.AreEqual("Entry Type"::Usage, "Entry Type", Identifier);
            Assert.AreEqual(PostedAssemblyDocumentNo, "Document No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."No.", "Resource No.", Identifier);
            Resource.Get(PostedAssemblyLine."No.");
            Assert.AreEqual(Resource."Resource Group No.", "Resource Group No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine.Description, Description, Identifier);
            Assert.AreEqual('', "Work Type Code", Identifier);
            Assert.AreEqual('', "Job No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Unit of Measure Code", "Unit of Measure Code", Identifier);
            Assert.AreEqual(PostedAssemblyLine.Quantity, Quantity, Identifier);
            Assert.AreEqual(Resource."Direct Unit Cost", "Direct Unit Cost", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Unit Cost", "Unit Cost", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Cost Amount", "Total Cost", Identifier);
            Assert.AreEqual(0, "Unit Price", Identifier);
            Assert.AreEqual(0, "Total Price", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 1 Code", "Global Dimension 1 Code", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Shortcut Dimension 2 Code", "Global Dimension 2 Code", Identifier);
            Assert.AreEqual(UpperCase(UserId), "User ID", Identifier);
            SourceCodeSetup.Get();
            Assert.AreEqual(SourceCodeSetup.Assembly, "Source Code", Identifier);
            Assert.AreEqual(true, Chargeable, Identifier);
            Assert.AreEqual('', "Journal Batch Name", Identifier);
            Assert.AreEqual('', "Reason Code", Identifier);
            Assert.AreEqual('', "Gen. Bus. Posting Group", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Gen. Prod. Posting Group", "Gen. Prod. Posting Group", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Posting Date", "Document Date", Identifier);
            Assert.AreEqual('', "External Document No.", Identifier);
            AssemblySetup.Get();
            Assert.AreEqual(AssemblySetup."Posted Assembly Order Nos.", "No. Series", Identifier);
            Assert.AreEqual("Source Type"::" ", "Source Type", Identifier);
            Assert.AreEqual('', "Source No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Qty. per Unit of Measure", "Qty. per Unit of Measure", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Quantity (Base)", "Quantity (Base)", Identifier);
            Assert.AreEqual("Order Type"::Assembly, "Order Type", Identifier);
            Assert.AreEqual(PostedAssemblyHeader."Order No.", "Order No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Order Line No.", "Order Line No.", Identifier);
            Assert.AreEqual(PostedAssemblyLine."Dimension Set ID", "Dimension Set ID", Identifier);
        end;
    end;

    local procedure VerifyRegisters(PostedAssemblyHeader: Record "Posted Assembly Header")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemRegister: Record "Item Register";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        ItemLedgEntry.SetCurrentKey("Entry No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Posted Assembly");
        ItemLedgEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", PostedAssemblyHeader."Order No.");
        ItemLedgEntry.FindFirst();
        ItemRegister.SetRange("From Entry No.", ItemLedgEntry."Entry No.");
        ItemLedgEntry.FindLast();
        ItemRegister.SetRange("To Entry No.", ItemLedgEntry."Entry No.");
        SourceCodeSetup.Get();
        ItemRegister.SetRange("Source Code", SourceCodeSetup.Assembly);
        Assert.AreEqual(1, ItemRegister.Count, 'The entire posting should create only one register.');
    end;
}

