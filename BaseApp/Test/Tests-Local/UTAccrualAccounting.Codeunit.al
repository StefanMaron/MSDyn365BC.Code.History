codeunit 144025 "UT Accrual Accounting"
{
    // 1. Purpose of this test to validate On New Record Trigger of Page 11207 - "Automatic Acc. Line".
    // 2. Purpose of this test to validate On Lookup trigger of Shortcut Dimension 1 Code of Page 11207 - "Automatic Acc. Line".
    // 3. Purpose of this test to validate On Lookup trigger of Shortcut Dimension 1 Code of Page 11207 - "Automatic Acc. Line".
    // 
    // Covers Test Cases for WI - 351138
    // ---------------------------------------------------
    // Test Function Name
    // ---------------------------------------------------
    // OnNewRecordAutomaticAccLine
    // OnLookupShortcutDimOneCodeAutomaticAccLine
    // OnLookupShortcutDimTwoCodeAutomaticAccLine
    // 
    // Covers Tests for FI - TFS 60769 AACAA - Enable/Disable New Document Nos. Field
    // ---------------------------------------------------
    // Test Function Name
    // ---------------------------------------------------
    // AutomaticAccLinesDeletedWithHeader

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnNewRecordAutomaticAccLine()
    var
        AutomaticAccLine: TestPage "Automatic Acc. Line";
        AllocationPct: Decimal;
        GLAccountNo: Code[20];
    begin
        // Purpose of this test to validate On New Record Trigger of Page 11207 - "Automatic Acc. Line".

        // Setup.
        Initialize();
        AllocationPct := LibraryRandom.RandDec(10, 2);
        GLAccountNo := CreateGLAccount;

        // Exercise.
        OpenAutomaticAccLinePage(AllocationPct, GLAccountNo);

        // Verify: Verify Allocation Pct on Automatic Acc. Line page.
        AutomaticAccLine.OpenEdit;
        AutomaticAccLine.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        AutomaticAccLine."Allocation %".AssertEquals(AllocationPct);
        AutomaticAccLine.Close;
    end;

    [Test]
    [HandlerFunctions('DimensionValueListModalPageHandler,EditDimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupShortcutDimOneCodeAutomaticAccLine()
    var
        AutomaticAccHeader: TestPage "Automatic Acc. Groups";
    begin
        // Purpose of this test to validate On Lookup trigger of Shortcut Dimension 1 Code of Page 11207 - "Automatic Acc. Line".

        // Setup.
        Initialize();
        AutomaticAccHeader.OpenEdit;
        AutomaticAccHeader.FILTER.SetFilter("No.", CreateAutomaticAccHeaderWithLine);

        // Exercise: Lookup and update Shortcut Dimension 1 Code on Automatic Acc. Lines.
        AutomaticAccHeader.AccLines."Shortcut Dimension 1 Code".Lookup;

        // Verify: Verify Dimension Value Code in Page Handler - EditDimensionSetEntriesModalPageHandler.
        LibraryVariableStorage.Enqueue(AutomaticAccHeader.AccLines."Shortcut Dimension 1 Code".Value);
        AutomaticAccHeader.AccLines.Dimensions.Invoke;
        AutomaticAccHeader.Close;
    end;

    [Test]
    [HandlerFunctions('DimensionValueListModalPageHandler,EditDimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupShortcutDimTwoCodeAutomaticAccLine()
    var
        AutomaticAccHeader: TestPage "Automatic Acc. Groups";
    begin
        // Purpose of this test to validate On Lookup trigger of Shortcut Dimension 1 Code of Page 11207 - "Automatic Acc. Line".

        // Setup.
        Initialize();
        AutomaticAccHeader.OpenEdit;
        AutomaticAccHeader.FILTER.SetFilter("No.", CreateAutomaticAccHeaderWithLine);

        // Exercise: Lookup and update Shortcut Dimension 2 code on Automatic Acc. Lines.
        AutomaticAccHeader.AccLines."Shortcut Dimension 2 Code".Lookup;

        // Verify: Verify Dimension Value Code in Page Handler - EditDimensionSetEntriesModalPageHandler.
        LibraryVariableStorage.Enqueue(AutomaticAccHeader.AccLines."Shortcut Dimension 2 Code".Value);
        AutomaticAccHeader.AccLines.Dimensions.Invoke;
        AutomaticAccHeader.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutomaticAccLineDeletedWithHeader()
    var
        AutomaticAccHeader: Record "Automatic Acc. Header";
        AutomaticAccLine: Record "Automatic Acc. Line";
        AccCode: Code[10];
    begin
        // Setup
        AccCode := CreateAutomaticAccHeaderWithLine;
        AutomaticAccLine.SetRange("Automatic Acc. No.", AccCode);
        Assert.AreEqual(1, AutomaticAccLine.Count, 'Expected Automatic Acc Line count wrong');

        // Exercise
        AutomaticAccHeader.SetRange("No.", AccCode);
        AutomaticAccHeader.DeleteAll(true); // Run delete trigger

        // Verify
        AutomaticAccLine.SetRange("Automatic Acc. No.", AccCode);
        Assert.AreEqual(0, AutomaticAccLine.Count, 'Delete of Automatic Acc Header failed to delete Automatic Acc line(s)');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAutomaticAccHeaderWithLine(): Code[10]
    var
        AutomaticAccHeader: Record "Automatic Acc. Header";
        AutomaticAccLine: Record "Automatic Acc. Line";
    begin
        AutomaticAccHeader.Init();
        AutomaticAccHeader."No." := LibraryUTUtility.GetNewCode10;
        AutomaticAccHeader.Insert();
        AutomaticAccLine.Init();
        AutomaticAccLine."Automatic Acc. No." := AutomaticAccHeader."No.";
        AutomaticAccLine.Description := LibraryUTUtility.GetNewCode;
        AutomaticAccLine.Insert();
        exit(AutomaticAccLine."Automatic Acc. No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := LibraryUTUtility.GetNewCode10;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure OpenAutomaticAccLinePage(AllocationPct: Decimal; GLAccountNo: Code[20])
    var
        AutomaticAccLine: TestPage "Automatic Acc. Line";
    begin
        AutomaticAccLine.OpenNew();
        AutomaticAccLine."Allocation %".SetValue(AllocationPct);
        AutomaticAccLine."G/L Account No.".SetValue(GLAccountNo);
        AutomaticAccLine.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionValueListModalPageHandler(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesModalPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionValueCode);
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(DimensionValueCode);
        EditDimensionSetEntries.OK.Invoke;
    end;
}

