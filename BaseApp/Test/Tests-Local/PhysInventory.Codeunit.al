codeunit 145013 "Phys. Inventory"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('RequestPageCalculateInventoryHandler')]
    [Scope('OnPrem')]
    procedure LoadingNotStoredItems()
    var
        Item: Record Item;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        WhseNetChangeTemplate1: Record "Whse. Net Change Template";
        WhseNetChangeTemplate2: Record "Whse. Net Change Template";
    begin
        // 1. Setup
        Initialize;

        LibraryInventory.CreateItem(Item);

        CreateWhseNetChangeTemplate(
          WhseNetChangeTemplate1, WhseNetChangeTemplate1."Entry Type"::"Positive Adjmt.");
        CreateWhseNetChangeTemplate(
          WhseNetChangeTemplate2, WhseNetChangeTemplate2."Entry Type"::"Negative Adjmt.");

        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::"Phys. Inventory");
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type::"Phys. Inventory", ItemJnlTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);
        MakeItemJournalLine(ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // 2. Exercise
        CalculateInventory(ItemJnlLine, Item."No.", WorkDate, true, true);

        // 3. Verify
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJnlLine.SetRange("Item No.", Item."No.");
        ItemJnlLine.FindFirst;

        ItemJnlLine.Validate("Qty. (Phys. Inventory)", ItemJnlLine."Qty. (Calculated)" + 1);
        ItemJnlLine.TestField("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.TestField("Whse. Net Change Template", WhseNetChangeTemplate1.Name);

        ItemJnlLine.Validate("Qty. (Phys. Inventory)", ItemJnlLine."Qty. (Calculated)" - 1);
        ItemJnlLine.TestField("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.TestField("Whse. Net Change Template", WhseNetChangeTemplate2.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadingStoredItems()
    var
        Item: Record Item;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        WhseNetChangeTemplate1: Record "Whse. Net Change Template";
        WhseNetChangeTemplate2: Record "Whse. Net Change Template";
    begin
        // 1. Setup
        Initialize;

        CreateWhseNetChangeTemplate(
          WhseNetChangeTemplate1, WhseNetChangeTemplate1."Entry Type"::"Positive Adjmt.");
        CreateWhseNetChangeTemplate(
          WhseNetChangeTemplate2, WhseNetChangeTemplate2."Entry Type"::"Negative Adjmt.");

        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type::Item, ItemJnlTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Purchase,
          Item."No.", LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::"Phys. Inventory");
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type::"Phys. Inventory", ItemJnlTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);
        MakeItemJournalLine(ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        // 2. Exercise
        LibraryInventory.CalculateInventoryForSingleItem(ItemJnlLine, Item."No.", WorkDate, false, false);

        // 3. Verify
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJnlLine.SetRange("Item No.", Item."No.");
        ItemJnlLine.FindFirst;

        ItemJnlLine.Validate("Qty. (Phys. Inventory)", ItemJnlLine."Qty. (Calculated)" + 1);
        ItemJnlLine.TestField("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.TestField("Whse. Net Change Template", WhseNetChangeTemplate1.Name);

        ItemJnlLine.Validate("Qty. (Phys. Inventory)", ItemJnlLine."Qty. (Calculated)" - 1);
        ItemJnlLine.TestField("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.TestField("Whse. Net Change Template", WhseNetChangeTemplate2.Name);
    end;

    local procedure CalculateInventory(ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; PostingDate: Date; ItemsNotOnInvt: Boolean; ItemsWithoutChange: Boolean)
    var
        Item: Record Item;
        CalculateInventory: Report "Calculate Inventory";
    begin
        Clear(CalculateInventory);
        Item.SetRange("No.", ItemNo);
        CalculateInventory.UseRequestPage(true);
        CalculateInventory.SetTableView(Item);
        CalculateInventory.SetItemJnlLine(ItemJournalLine);
        CalculateInventory.InitializeRequest(PostingDate, ItemJournalLine."Document No.", ItemsNotOnInvt, false);
        LibraryVariableStorage.Enqueue(ItemsWithoutChange);
        Commit();
        CalculateInventory.Run;
    end;

    local procedure CreateGenBusPostingGroup(var GenBusinessPostingGroup: Record "Gen. Business Posting Group")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        GenBusinessPostingGroup.Modify();
    end;

    local procedure CreateWhseNetChangeTemplate(var WhseNetChangeTemplate: Record "Whse. Net Change Template"; EntryType: Option)
    var
        GenBusPostGroup: Record "Gen. Business Posting Group";
    begin
        CreateGenBusPostingGroup(GenBusPostGroup);
        WhseNetChangeTemplate.Init();
        WhseNetChangeTemplate.Validate(
          Name,
          CopyStr(LibraryUtility.GenerateRandomCode(WhseNetChangeTemplate.FieldNo(Name), DATABASE::"Whse. Net Change Template"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Whse. Net Change Template", WhseNetChangeTemplate.FieldNo(Name))));
        WhseNetChangeTemplate.Validate("Entry Type", EntryType);
        WhseNetChangeTemplate.Validate("Gen. Bus. Posting Group", GenBusPostGroup.Code);
        WhseNetChangeTemplate.Insert();

        case EntryType of
            WhseNetChangeTemplate."Entry Type"::"Positive Adjmt.":
                SetDefTemplateForPhysPosAdj(WhseNetChangeTemplate.Name);
            WhseNetChangeTemplate."Entry Type"::"Negative Adjmt.":
                SetDefTemplateForPhysNegAdj(WhseNetChangeTemplate.Name);
        end;
    end;

    local procedure MakeItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := JournalTemplateName;
        ItemJnlLine."Journal Batch Name" := JournalBatchName;
        ItemJnlLine."Document No." :=
          LibraryUtility.GenerateRandomCode(ItemJnlLine.FieldNo("Document No."), DATABASE::"Item Journal Line");
    end;

    local procedure SetDefTemplateForPhysPosAdj(WhseNetChangeTemplate: Code[10])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Def.Template for Phys.Pos.Adj", WhseNetChangeTemplate);
        InventorySetup.Modify();
    end;

    local procedure SetDefTemplateForPhysNegAdj(WhseNetChangeTemplate: Code[10])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Def.Template for Phys.Neg.Adj", WhseNetChangeTemplate);
        InventorySetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCalculateInventoryHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        ItemsWithoutChange: Boolean;
    begin
        ItemsWithoutChange := LibraryVariableStorage.DequeueBoolean;
        CalculateInventory.ItemsWithoutChange.SetValue(ItemsWithoutChange);
        CalculateInventory.OK.Invoke;
    end;
}

