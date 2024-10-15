codeunit 134785 "Test Assembly Order Post Prev."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Assembly Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [Scope('OnPrem')]
    procedure PreviewAssemblyOrderPosting()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssembledItem: Record Item;
        CompItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        AsemblyPostYesNo: Codeunit "Assembly-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Assembly] [Assembly Order] [Preview Posting]
        // [SCENARIO] Preview Assembly Order posting shows the ledger entries that will be generated when the assembly order is posted.
        Initialize();

        // [GIVEN] An Assembly Order with line
        CreateItem(CompItem);
        LibraryInventory.CreateItem(AssembledItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 20, CompItem."Base Unit of Measure");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap;
        asserterror AsemblyPostYesNo.Preview(AssemblyHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the asembly order is posted
        GLPostingPreview.First;
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK.Invoke;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Assembly Order Post Prev.");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Assembly Order Post Prev.");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Assembly Order Post Prev.");
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        if ItemNo <> '' then begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ItemNo, '', Quantity, '');
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

    local procedure CreateItem(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger,
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;
}