codeunit 134370 "ERM No. Series Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [No. Series]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        StartingNumberTxt: Label 'ABC00010D';
        SecondNumberTxt: Label 'ABC00020D';
        EndingNumberTxt: Label 'ABC00090D';
        StartingNumber2Txt: Label 'X00000000000000001A';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestStartingNoNoGaps()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 1, FALSE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'No gaps diff');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'No gaps diff');
        NoSeriesLine.FIND;
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine.GetLastNoUsed, 'lastUsedNo function');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestStartingNoWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 1, TRUE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');
        Assert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');
        Assert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        Assert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        Assert.AreEqual(ToBigInt(11), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        NoSeriesLine.FIND;
        Assert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine.GetLastNoUsed, 'lastUsedNo function');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestChangingToAllowGaps()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');
        Assert.AreEqual(ToBigInt(0), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');

        // test - enable Allow gaps
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        NoSeriesLine.FIND;
        NoSeriesLine.VALIDATE("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();
        Assert.AreEqual(ToBigInt(0), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong after conversion');
        Assert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(StartingNumberTxt, NoSeriesLine.GetLastNoUsed, 'lastUsedNo function after conversion');
        Assert.AreEqual(SecondNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'GetNextNo after conversion');
        Assert.AreEqual(SecondNumberTxt, NoSeriesLine.GetLastNoUsed, 'lastUsedNo after taking new no. after conversion');
        // Change back to not allow gaps
        NoSeriesLine.FIND;
        NoSeriesLine.VALIDATE("Allow Gaps in Nos.", false);
        NoSeriesLine.Modify();
        Assert.AreEqual(SecondNumberTxt, NoSeriesLine."Last No. Used", 'last no. used field after reset');
        Assert.AreEqual(SecondNumberTxt, NoSeriesLine.GetLastNoUsed, 'lastUsedNo  after reset');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestChangingToAllowGapsDateOrder()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeries.Get('TEST');
        NoSeries."Date Order" := true;
        NoSeries.Modify();

        // test - enable Allow gaps should not be allowed
        AssertError NoSeriesLine.VALIDATE("Allow Gaps in Nos.", true);

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestChangingStartNoAfterUsingNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
        FormattedNo: Code[20];
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeriesLine."Starting No." := 'A000001';
        NoSeriesLine."Last No. Used" := 'A900001';
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeriesLine.GetLastNoUsed();
        Assert.AreEqual('A900001', FormattedNo, 'Init didnt work...');
        NoSeriesLine."Starting No." := 'A';
        NoSeriesLine.Modify();
        FormattedNo := NoSeriesLine.GetLastNoUsed();
        Assert.AreEqual('A900001', FormattedNo, 'Default didnt work');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestChangingStartNoAfterUsingNoSeriesTooLong()
    var
        NoSeriesLine: Record "No. Series Line";
        FormattedNo: Code[20];
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeriesLine."Starting No." := 'ABC00000000000000001';
        NoSeriesLine."Last No. Used" := 'ABC10000000000000001';
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // test - getting formatted number still works
        FormattedNo := NoSeriesLine.GetLastNoUsed();
        Assert.AreEqual('ABC10000000000000001', FormattedNo, 'Init didnt work...');
        NoSeriesLine."Starting No." := 'ABCD';
        NoSeriesLine.Modify();
        FormattedNo := NoSeriesLine.GetLastNoUsed(); // will become too long, so we truncate the prefix
        Assert.AreEqual('A10000000000000001', FormattedNo, 'Default didnt work');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TheLastNoUsedDidNotChangeAfterEnabledAllowGapsInNos()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        FormattedNo: Code[20];
        LastNoUsed: Code[20];
    begin
        // [SCENARIO 365394] The "Last No. Used" should not changed after enabled and disabled "Allow Gaps in Nos." for No Series, which included only digits
        Initialize();

        // [GIVEN] Created No Series with "Allow Gaps in Nos." = true and "Last No. Used"
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);

        // [GIVEN] Change "Allow Gaps in Nos." to false
        NoSeriesLine.Validate("Allow Gaps in Nos.", false);

        // [GIVEN] Change "Allow Gaps in Nos." to true
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();

        // [WHEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [THEN] "Last No. Used" did not change
        NoSeriesLines."Last No. Used".AssertEquals(LastNoUsed);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestInsertFromExternalWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize;
        CreateNewNumberSeries('TEST', 1, FALSE, NoSeriesLine);
        // Simulate that NoSeriesLine was inserted programmatically without triggering creation of Sequence
        NoSeriesLine."Allow Gaps in Nos." := true;
        NoSeriesLine."Sequence Name" := Format(CreateGuid);
        NoSeriesLine."Sequence Name" := CopyStr(NoSeriesLine."Sequence Name", 2, StrLen(NoSeriesLine."Sequence Name") - 2);
        NoSeriesLine.Modify();

        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'Gaps diff');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'Gaps diff');

        // clean up
        DeleteNumberSeries('TEST');
    end;


    local procedure CreateNewNumberSeries(NewName: Code[20]; IncrementBy: Integer; AllowGaps: Boolean; var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := NewName;
        NoSeries.Description := NewName;
        NoSeries.Insert();

        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.VALIDATE("Starting No.", StartingNumberTxt);
        NoSeriesLine.VALIDATE("Ending No.", EndingNumberTxt);
        NoSeriesLine."Increment-by No." := IncrementBy;
        NoSeriesLine.INSERT(TRUE);
        NoSeriesLine.VALIDATE("Allow Gaps in Nos.", AllowGaps);
        NoSeriesLine.Modify(TRUE);
    end;

    local procedure DeleteNumberSeries(NameToDelete: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        IF NoSeriesLine.GET(NameToDelete, 10000) THEN
            NoSeriesLine.DELETE(TRUE);
        IF NoSeries.GET(NameToDelete) THEN
            NoSeries.DELETE(TRUE);
    end;

    local procedure ToBigInt(IntValue: Integer): BigInteger
    begin
        EXIT(IntValue);
    end;

    local procedure Initialize()
    begin
        LibraryLowerPermissions.SetO365BusFull;
    end;
}

