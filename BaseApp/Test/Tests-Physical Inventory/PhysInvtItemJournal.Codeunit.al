codeunit 137463 "Phys. Invt. Item Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        NewDocNo: Code[20];
        EntryType: Enum "Item Ledger Entry Type";
        OldDocNo: Code[20];
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257226] Generate one line in the Item Journal and renumber the document number.
        Initialize();

        // [GIVEN] Create random item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create one Item Journal lines with the created item
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandDec(20, 0), '');

        OldDocNo := ItemJournalLine."Document No.";
        SetNewDocNo(ItemJournalLine);

        // [WHEN] Enable the functionality renumber document no. on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo;

        // [THEN] The lines must have the first value from the No. Series
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          ItemJournalLine."Line No.", OldDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLines()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257227] Generate multiple lines in the Item Journal and renumber the "Document No.".
        Initialize();

        // [GIVEN] Create two random items
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create multiple Item Journal lines with the created items and a random "Document No.""
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.",
            LibraryRandom.RandDec(20, 0), '',
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), Database::"Item Journal Line"));
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item2."No.",
            LibraryRandom.RandDec(20, 0), '',
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), Database::"Item Journal Line"));
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item2."No.",
            LibraryRandom.RandDec(20, 0), '',
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), Database::"Item Journal Line"));

        // [WHEN] Enable the functionality renumber "Document No." on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo;

        // [THEN] All the lines must have the same "Document No."
        if ItemJnlBatch.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name") then
            NoSeriesCode := ItemJnlBatch."No. Series";

        NewDocNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate(), false);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          20000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          30000, NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesAndDifferentWorkDate()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257228] Generate multiple lines in the Item Journal with different dates and renumber the document number.
        Initialize();

        // [GIVEN] Create two random items
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create multiple Item Journal lines with the created items
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate() + 1, Item."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate() + 1, Item2."No.", LibraryRandom.RandDec(20, 0), '');

        // [WHEN] Enable the functionality renumber document no. on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo;

        // [THEN] Line 10000 must have a different value then line 20000 and 30000
        if ItemJnlBatch.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name") then
            NoSeriesCode := ItemJnlBatch."No. Series";

        NewDocNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate(), false);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          30000, IncStr(NewDocNo));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure SetNewDocNo(var ItemJournalLine: Record "Item Journal Line"): Code[20]
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 10) do
            ItemJournalLine."Document No." := IncStr(ItemJournalLine."Document No.");
        ItemJournalLine.Modify();
        exit(ItemJournalLine."Document No.")
    end;

    local procedure VerifyItemJnlLineDocNo(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; DocNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Get(TemplateName, BatchName, LineNo);
        ItemJournalLine.TestField("Document No.", DocNo)
    end;
}