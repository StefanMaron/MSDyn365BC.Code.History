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
        Initialize();
        CreateNewNumberSeries('TEST', 1, FALSE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');
        Assert.AreEqual(0D, NoSeriesLine."Last Date Used", 'Last Date used should be 0D');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'No gaps diff');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'No gaps diff');
        NoSeriesLine.Find();
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine.GetLastNoUsed, 'lastUsedNo function');
        Assert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be workdate');

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
        Initialize();
        CreateNewNumberSeries('TEST', 1, TRUE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');
        Assert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');
        Assert.AreEqual(ToBigInt(9), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        Assert.AreEqual(0D, NoSeriesLine."Last Date Used", 'Last Date used should be 0D');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        Assert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        Assert.AreEqual(ToBigInt(11), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        NoSeriesLine.Find();
        Assert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine.GetLastNoUsed, 'lastUsedNo function');
        Assert.AreEqual(Today(), NoSeriesLine."Last Date Used", 'Last Date used should be workdate');

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
        Initialize();
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');
        Assert.AreEqual(ToBigInt(0), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong');

        // test - enable Allow gaps
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        NoSeriesLine.Find();
        NoSeriesLine.VALIDATE("Allow Gaps in Nos.", true);
        NoSeriesLine.Modify();
        Assert.AreEqual(ToBigInt(10), NoSeriesLine."Starting Sequence No.", 'Starting Sequence No. is wrong after conversion');
        Assert.AreEqual('', NoSeriesLine."Last No. Used", 'last no. used field');
        Assert.AreEqual(StartingNumberTxt, NoSeriesLine.GetLastNoUsed, 'lastUsedNo function after conversion');
        Assert.AreEqual(SecondNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'GetNextNo after conversion');
        Assert.AreEqual(SecondNumberTxt, NoSeriesLine.GetLastNoUsed, 'lastUsedNo after taking new no. after conversion');
        // Change back to not allow gaps
        NoSeriesLine.Find();
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
        Initialize();
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeries.Get('TEST');
        NoSeries."Date Order" := true;
        NoSeries.Modify();

        // test - enable Allow gaps should be allowed
        NoSeriesLine.VALIDATE("Allow Gaps in Nos.", true);

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
        Initialize();
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
        Initialize();
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
        Initialize();
        CreateNewNumberSeries('TEST', 1, FALSE, NoSeriesLine);
        // Simulate that NoSeriesLine was inserted programmatically without triggering creation of Sequence
        NoSeriesLine."Allow Gaps in Nos." := true;
        NoSeriesLine."Sequence Name" := Format(CreateGuid());
        NoSeriesLine."Sequence Name" := CopyStr(NoSeriesLine."Sequence Name", 2, StrLen(NoSeriesLine."Sequence Name") - 2);
        NoSeriesLine.Modify();

        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed, 'lastUsedNo function before taking a number');

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'Gaps diff');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'Gaps diff');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestModifyNoGetNextWithoutGaps()
    begin
        ModifyNoGetNext(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestModifyNoGetNextWithGaps()
    begin
        ModifyNoGetNext(true);
    end;

    local procedure ModifyNoGetNext(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, AllowGaps, NoSeriesLine);

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, false), 'Gaps diff - first');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, false), 'Gaps diff - second');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSaveNoSeriesWithOutGaps()
    begin
        SaveNoSeries(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSaveNoSeriesWithGaps()
    begin
        SaveNoSeries(true);
    end;


    local procedure SaveNoSeries(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, AllowGaps, NoSeriesLine);

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, false), 'Gaps diff');
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, false), 'Gaps diff');
        NoSeriesManagement.SaveNoSeries();
        Clear(NoSeriesManagement);
        NoSeriesLine.Find();
        Assert.AreEqual(INCSTR(StartingNumberTxt), NoSeriesLine.GetLastNoUsed(), 'No. series not updated correctly');
        Assert.AreEqual(INCSTR(INCSTR(StartingNumberTxt)), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, true), 'GetNext after Save');
        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCurrentAndNextDifferWithOutGaps()
    begin
        CurrentAndNextDiffer(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCurrentAndNextDifferWithGaps()
    begin
        CurrentAndNextDiffer(true);
    end;

    local procedure CurrentAndNextDiffer(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, AllowGaps, NoSeriesLine);

        // test
        Assert.AreEqual('', NoSeriesLine.GetLastNoUsed(), 'Wrong last no.');
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, false), 'Wrong first no.');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SelectCustomerTemplateHandler')]
    [Scope('OnPrem')]
    procedure TestCreateCustomerWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        SalesSetup.LockTable();
        SalesSetup.Get();
        SalesSetup."Customer Nos." := NoSeriesLine."Series Code";
        SalesSetup.Modify();

        // Verify that customers will be created correctly        
        CreateNewCustomer(Customer);
        Assert.AreEqual(StartingNumberTxt, Customer."No.", 'Wrong first no.');
        CreateNewCustomer(Customer);

        // clean up
        DeleteNumberSeries('TEST');
    end;

    local procedure CreateNewCustomer(var Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue('Test Customer');
        Customer.Get(CustomerCard."No.".Value());
        CustomerCard.Close();
        Customer.Find(); // refresh in case there is any onclosepage logic
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesWithoutNoSeriesLineFailsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        NoSeriesLine.Delete();

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        asserterror NoSeriesPage.TestNoSeries.Invoke();

        // Error is thrown
        Assert.ExpectedError('You cannot assign new numbers from the number series TEST');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesWithNoSeriesLineOnLaterStartingDateFailsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);
        NoSeriesLine.Validate("Starting Date", CalcDate('+1M', WorkDate()));
        NoSeriesLine.Modify(true);

        // Invoke TestNoSeries action
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        asserterror NoSeriesPage.TestNoSeries.Invoke();

        // Error is thrown
        Assert.ExpectedError('You cannot assign new numbers from the number series TEST on ');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesThatCanGenerateNextNoSuceedsValidation()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        NoSeriesPage.TestNoSeries.Invoke();

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesValidationDoesNotChangeTheNextNoGenerated()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        // Create no. series without no. series line
        Initialize();
        CreateNewNumberSeries('TEST', 1, true, NoSeriesLine);

        // Invoke TestNoSeries action succeeds
        NoSeriesPage.OpenEdit();
        NoSeriesPage.GoToKey('TEST');
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.DoGetNextNo('TEST', WorkDate(), true, true), 'DoGetNextNo does not get the first no in the no series');

        // Invoke TestNoSeries action again
        NoSeriesPage.TestNoSeries.Invoke();

        // Ensure invoking TestNoSeries action does not modify the series
        Assert.AreEqual(IncStr(StartingNumberTxt), NoSeriesManagement.DoGetNextNo('TEST', WorkDate(), true, true), 'DoGetNextNo does the get the second no in the no series');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TheLastNoUsedCanBeUpdatedWhenAllowGapsInNosYes()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLines: TestPage "No. Series Lines";
        LastNoUsed: Code[20];
        NewLastNoUsed: Code[20];
    begin
        // [SCENARIO 428940] The "Last No. Used" can be updated when "Allow Gaps in Nos." = Yes
        Initialize();

        // [GIVEN] Created No Series with "Allow Gaps in Nos." = true and "Last No. Used" = '1000023'
        CreateNewNumberSeries('TEST', 10, FALSE, NoSeriesLine);
        NoSeriesLine."Starting No." := '1000001';
        LastNoUsed := '1000023';
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine.Validate("Allow Gaps in Nos.", true);

        // [GIVEN] Open page 457 "No. Series Lines"
        NoSeriesLines.OpenEdit();
        NoSeriesLines.Filter.SetFilter("Series Code", NoSeriesLine."Series Code");
        NoSeriesLines.Filter.SetFilter("Line No.", Format(NoSeriesLine."Line No."));
        NoSeriesLines.First();

        // [GIVEN] "Last No. Used" is changed to '1000025'
        NewLastNoUsed := '1000025';
        NoSeriesLines."Last No. Used".SetValue(NewLastNoUsed);
        // [WHEN] Move focus to new line and return it back
        NoSeriesLines.New();
        NoSeriesLines.First();
        // [THEN] "Last No. Used" = '1000025' in the page
        NoSeriesLines."Last No. Used".AssertEquals(NewLastNoUsed);
        NoSeriesLines.OK().Invoke();

        // [THEN] "Last No. Used" is empty in the table
        NoSeriesLine.Find();
        NoSeriesLine.TestField("Last No. Used", '');
    end;

    local procedure CreateNewNumberSeries(NewName: Code[20]; IncrementBy: Integer; AllowGaps: Boolean; var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := NewName;
        NoSeries.Description := NewName;
        NoSeries."Default Nos." := true;
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsTrueOne()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsFalseOne()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsTrueMultipe()
    begin
        PageNoSeriesChangeAllowGaps(true, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageNoSeriesChangeAllowGapsFalseMultiple()
    begin
        PageNoSeriesChangeAllowGaps(false, 1);
    end;

    local procedure PageNoSeriesChangeAllowGaps(NewAllowGaps: Boolean; NoOfLines: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesList: TestPage "No. Series";
        i: Integer;
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, not NewAllowGaps, NoSeriesLine);
        for i := 2 to NoOfLines do begin
            NoSeriesLine."Line No." += 10000;
            NoSeriesLine."Starting Date" := WorkDate() + i;
            NoSeriesLine.Insert();
        end;
        NoSeries.Get(NoSeriesLine."Series Code");

        // Set Allow Gaps from No. Series list page.
        NoSeriesList.OpenEdit();
        NoSeriesList.GoToRecord(NoSeries);
        NoSeriesList.AllowGapsCtrl.SetValue(NewAllowGaps);

        // validate
        NoSeriesLine.SetRange("Series Code", NoSeriesLine."Series Code");
        if NoSeriesLine.FindSet() then
            repeat
                if NoOfLines = 1 then
                    Assert.AreEqual(NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'First No. Series Line not updated.')
                else
                    if NoSeriesLine."Starting Date" < WorkDate() then
                        Assert.AreEqual(not NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'No. Series Line updated when it should not.')
                    else
                        Assert.AreEqual(NewAllowGaps, NoSeriesLine."Allow Gaps in Nos.", 'No. Series Line not updated.');
            until NoSeriesLine.Next() = 0;

        // clean up
        DeleteNumberSeries('TEST');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeIncrementWithGaps()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesPage: TestPage "No. Series";
    begin
        Initialize();
        CreateNewNumberSeries('TEST', 1, TRUE, NoSeriesLine);

        // test
        Assert.AreEqual(StartingNumberTxt, NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff');
        Assert.AreEqual(ToBigInt(10), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong');
        NoSeriesLine.Find();
        NoSeriesLine.Validate("Increment-by No.", 2);
        NoSeriesLine.Modify();
        Assert.AreEqual(StartingNumberTxt, NoSeriesLine.GetLastNoUsed(), 'Last Used No. changed after changing increment');
        Assert.AreEqual(INCSTR(INCSTR(StartingNumberTxt)), NoSeriesManagement.GetNextNo(NoSeriesLine."Series Code", TODAY, TRUE), 'With gaps diff after change of increment');
        NoSeriesLine.Find();
        Assert.AreEqual(ToBigInt(12), NumberSequence.Current(NoSeriesLine."Sequence Name"), 'Current value wrong after first use after change of increment');

        // clean up
        DeleteNumberSeries('TEST');
    end;

    local procedure DeleteNumberSeries(NameToDelete: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NameToDelete);
        NoSeriesLine.DeleteAll(True);
        IF NoSeries.Get(NameToDelete) THEN
            NoSeries.Delete(True);
    end;

    local procedure ToBigInt(IntValue: Integer): BigInteger
    begin
        EXIT(IntValue);
    end;

    local procedure Initialize()
    begin
        Clear(NoSeriesManagement);
        LibraryLowerPermissions.SetO365BusFull;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplateHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK.Invoke();
    end;
}

