codeunit 139142 UpdateParentTest
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Update Parent]
    end;

    var
        UpdateParentRegisterLine: Record "Update Parent Register Line";
        UpdateParentRegisterMgt: Codeunit "Update Parent Register Mgt";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        HeaderId: Integer;
        LineId: Integer;
        LineUpdateParentId: Integer;
        FactLineId: Integer;
        FirstLineNextAmount: Text;
        FirstLineNextQuantity: Text;

    local procedure Initialize()
    var
        UpdateParentHeader: Record "Update Parent Header";
        UpdateParentLine: Record "Update Parent Line";
        UpdateParentFactLine: Record "Update Parent Fact Line";
    begin
        LibraryVariableStorage.Clear();

        UpdateParentRegisterMgt.Clear();
        UpdateParentRegisterMgt.Init('UpdateP');
        UpdateParentHeader.DeleteAll();
        UpdateParentLine.DeleteAll();
        UpdateParentFactLine.DeleteAll();

        HeaderId := 139141;
        LineId := 139142; // The LIne not updating parent
        LineUpdateParentId := 9139142; // The line updating the father
        FactLineId := 139143; // The fact box
    end;

    local procedure CreateData()
    var
        UpdateParentHeader: Record "Update Parent Header";
        UpdateParentLine: Record "Update Parent Line";
        UpdateParentFactLine: Record "Update Parent Fact Line";
    begin
        with UpdateParentHeader do begin
            Init();
            Id := 'UpdateP';
            Description := 'Test';
            Insert();
        end;

        with UpdateParentLine do begin
            Init();
            "Header Id" := UpdateParentHeader.Id;
            "Line Id" := 1;
            Amount := 0.5;
            Quantity := 2;
            Insert();

            Init();
            "Header Id" := UpdateParentHeader.Id;
            "Line Id" := 2;
            Amount := 1.5;
            Quantity := 4;
            Insert();
        end;

        with UpdateParentFactLine do begin
            Init();
            "Header Id" := UpdateParentHeader.Id;
            "Line Id" := 1;
            Name := 'The facts';
            Insert();
        end
    end;

    [Test]
    [HandlerFunctions('HeaderUIHandler')]
    [Scope('OnPrem')]
    procedure UpdateLinesOnlyWithSaveTest()
    var
        UpdateParentHeaderPage: Page "Update Parent Header Page";
        LinesAmountVar: Variant;
        LinesQuantityVar: Variant;
        Amount: Decimal;
        Quantity: Integer;
    begin
        Initialize();
        CreateData;

        UpdateParentHeaderPage.SetSubPagesToSave;
        UpdateParentHeaderPage.SetSubPageIds(LineId, LineUpdateParentId, FactLineId);

        FirstLineNextAmount := '7';
        FirstLineNextQuantity := '7';

        UpdateParentHeaderPage.Run();

        LibraryVariableStorage.Dequeue(LinesAmountVar);
        LibraryVariableStorage.Dequeue(LinesQuantityVar);
        Amount := LinesAmountVar;
        Quantity := LinesQuantityVar;

        // Lines are saved but Parent not updated so expect no recalculation -
        // Qty = 2+4 and Amount = 2*0.5+4*1.5 = 7
        // otherwise Qty = 7+1.5, Amount = 7*7+4*1.5 = 55
        Assert.AreEqual(6, Quantity, 'Quantity is not correct');
        Assert.AreEqual(7, Amount, 'Amount is not correct');

        UpdateParentHeaderPage.Close();

        UpdateParentRegisterMgt.EnumeratorReset;
        Assert.AreEqual(10, UpdateParentRegisterMgt.EnumeratorCount, 'The wrong list of registrated lines');

        // On validate trigger (for Amount) CurrPage.Update(TRUE) is called in between PreUpdate/PostUpdate, and this trigger the Modify
        with UpdateParentRegisterMgt do begin
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Modify, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client updates the curr record as requested by CurrPage.Update
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The client updates the sibling sub page since they are pointing to the same record
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);

            // On validate trigger (for Quantity) CurrPage.Update(TRUE) is called in between PreUpdate/PostUpdate, and this trigger the Modify
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Modify, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client updates the curr record as requested by CurrPage.Update
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The client updates the sibling sub page since they are pointing to the same record that the client notes that it is changed
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
        end;

        Assert.IsTrue(UpdateParentRegisterMgt.EnumeratorDone, 'Too many rows');
    end;

    [Test]
    [HandlerFunctions('HeaderUIHandler')]
    [Scope('OnPrem')]
    procedure UpdateLinesOnlyNoSaveTest()
    var
        UpdateParentHeaderPage: Page "Update Parent Header Page";
        LinesAmountVar: Variant;
        LinesQuantityVar: Variant;
        Amount: Decimal;
        Quantity: Integer;
    begin
        Initialize();
        CreateData;

        UpdateParentHeaderPage.SetSubPagesToNotSave;
        UpdateParentHeaderPage.SetSubPageIds(LineId, LineUpdateParentId, FactLineId);

        FirstLineNextAmount := '7';
        FirstLineNextQuantity := '7';

        UpdateParentHeaderPage.Run();

        LibraryVariableStorage.Dequeue(LinesAmountVar);
        LibraryVariableStorage.Dequeue(LinesQuantityVar);
        Amount := LinesAmountVar;
        Quantity := LinesQuantityVar;

        // Parent not updated and no save so expect no recalculation - otherwise Qty = 7+1.5, Amount = 7*7+1.5*4 = 55
        // Qty = 2+4 and Amount = 2*0.5+4*1.5 = 7
        // otherwise Qty = 7+1.5, Amount = 7*7+1.5*4 = 55

        Assert.AreEqual(6, Quantity, 'Quantity is not correct');
        Assert.AreEqual(7, Amount, 'Amount is not correct');

        UpdateParentHeaderPage.Close();
        UpdateParentRegisterMgt.EnumeratorReset;
        Assert.AreEqual(6, UpdateParentRegisterMgt.EnumeratorCount, 'The wrong list of registrated lines');
        with UpdateParentRegisterMgt do begin
            // On validate trigger (for Amount) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers NOT the Modify
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client updates the curr record as requested by CurrPage.Update -> since not changed the sibling is not updated
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);

            // On validate trigger (for Qty) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers NOT the Modify
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client updates the curr record as requested by CurrPage.Update -> since not changed the sibling is not updated
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
        end;

        Assert.IsTrue(UpdateParentRegisterMgt.EnumeratorDone, 'Too many rows');
    end;

    [Test]
    [HandlerFunctions('HeaderUIHandlerWithUpdateParent')]
    [Scope('OnPrem')]
    procedure UpdateHeaderThenLinesWithSaveTest()
    var
        UpdateParentHeaderPage: Page "Update Parent Header Page";
        LinesAmountVar: Variant;
        LinesQuantityVar: Variant;
        Amount: Decimal;
        Quantity: Integer;
    begin
        Initialize();
        CreateData;

        UpdateParentHeaderPage.SetSubPagesToSave;
        UpdateParentHeaderPage.SetSubPageIds(LineId, LineUpdateParentId, FactLineId);
        FirstLineNextAmount := '4';
        FirstLineNextQuantity := '5';

        UpdateParentHeaderPage.Run();

        // First validate the results
        LibraryVariableStorage.Dequeue(LinesAmountVar);
        LibraryVariableStorage.Dequeue(LinesQuantityVar);
        Amount := LinesAmountVar;
        Quantity := LinesQuantityVar;

        // Lines are saved and Parent and updated so expect
        // Qty = 5+4, Amount = 5*4+4*1.5 = 26
        Assert.AreEqual(9, Quantity, 'Quantity is not correct');
        Assert.AreEqual(26, Amount, 'Amount is not correct');

        UpdateParentHeaderPage.Close();

        // Validate the sequence of updates and visits.
        UpdateParentRegisterMgt.EnumeratorReset;
        Assert.AreEqual(16, UpdateParentRegisterMgt.EnumeratorCount, 'The wrong list of registrated lines');

        with UpdateParentRegisterMgt do begin
            // On validate trigger (for Amount) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers the Modify
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Modify, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client propagates the update from LineUpdateParentId to its parent HeaderId
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The header now updates the three subpages
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);

            // On validate trigger (for QTY) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers the Modify
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Modify, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client propagates the update from LineUpdateParentId to its parent HeaderId
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The header now updates the three subpages
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
        end;

        Assert.IsTrue(UpdateParentRegisterMgt.EnumeratorDone, 'Too many rows');
    end;

    [Test]
    [HandlerFunctions('HeaderUIHandlerWithUpdateParent')]
    [Scope('OnPrem')]
    procedure UpdateHeaderThenLinesNoSaveTest()
    var
        UpdateParentHeaderPage: Page "Update Parent Header Page";
        LinesAmountVar: Variant;
        LinesQuantityVar: Variant;
        Amount: Decimal;
        Quantity: Integer;
    begin
        Initialize();
        CreateData;

        UpdateParentHeaderPage.SetSubPagesToNotSave;
        UpdateParentHeaderPage.SetSubPageIds(LineId, LineUpdateParentId, FactLineId);

        FirstLineNextAmount := '4';
        FirstLineNextQuantity := '5';

        UpdateParentHeaderPage.Run();

        // First validate the results
        LibraryVariableStorage.Dequeue(LinesAmountVar);
        LibraryVariableStorage.Dequeue(LinesQuantityVar);
        Amount := LinesAmountVar;
        Quantity := LinesQuantityVar;

        // Lines are not saved but Parent is updated so expect
        // Qty = 4+2, Amount = 2*0.5+4*1.5 = 77
        // If lines saved by mistake Qty = 5+4, Amount = 5*4+4*1.5 = 26
        Assert.AreEqual(6, Quantity, 'Quantity is not correct');
        Assert.AreEqual(7, Amount, 'Amount is not correct');

        UpdateParentHeaderPage.Close();

        // Validate the sequence of updates and visits.
        UpdateParentRegisterMgt.EnumeratorReset;
        Assert.AreEqual(14, UpdateParentRegisterMgt.EnumeratorCount, 'The wrong list of registrated lines');

        with UpdateParentRegisterMgt do begin
            // On validate trigger (for Amount) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers NOT the Modify
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client propagates the update from LineUpdateParentId to its parent HeaderId - data disgarded
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The header now updates the three subpages
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);

            // On validate trigger (for Qty) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers the NOT Modify
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);
            // The client propagates the update from LineUpdateParentId to its parent HeaderId
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            // The header now updates the three subpages
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
        end;

        Assert.IsTrue(UpdateParentRegisterMgt.EnumeratorDone, 'Too many rows');
    end;

    [Test]
    [HandlerFunctions('HeaderUIHandlerForFactBox')]
    [Scope('OnPrem')]
    procedure UpdateHeaderThenFromFactBox()
    var
        UpdateParentHeaderPage: Page "Update Parent Header Page";
    begin
        Initialize();
        CreateData;

        UpdateParentHeaderPage.SetSubPagesToNotSave;
        UpdateParentHeaderPage.SetSubPageIds(LineId, LineUpdateParentId, FactLineId);

        UpdateParentHeaderPage.Run();
        UpdateParentHeaderPage.Close();

        // Validate the sequence of updates and visits.
        UpdateParentRegisterMgt.EnumeratorReset;
        Assert.AreEqual(7, UpdateParentRegisterMgt.EnumeratorCount, 'The wrong list of registrated lines');

        with UpdateParentRegisterMgt do begin
            // On validate trigger (for Amount) CurrPage.Update(FALSE) is called in between PreUpdate/PostUpdate, and this triggers NOT the Modify
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PreUpdate);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::Validate, UpdateParentRegisterLine.Operation::PostUpdate);

            // Parent reads its data
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(HeaderId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);

            // The subpages and fact boxes are updated.
            ExpectedLine(LineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(LineUpdateParentId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
            ExpectedLine(FactLineId, UpdateParentRegisterLine.Method::AfterGetCurrRecord, UpdateParentRegisterLine.Operation::Visit);
        end;

        Assert.IsTrue(UpdateParentRegisterMgt.EnumeratorDone, 'Too many rows');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HeaderUIHandler(var HeaderPage: TestPage "Update Parent Header Page")
    begin
        UpdateParentRegisterMgt.Start;
        // Changing data on the page that do not update its parent
        HeaderPage.Lines.Amount.Value := FirstLineNextAmount;
        HeaderPage.Lines.Quantity.Value := FirstLineNextQuantity;
        UpdateParentRegisterMgt.Stop();

        LibraryVariableStorage.Enqueue(HeaderPage.LinesAmount.Value);
        LibraryVariableStorage.Enqueue(HeaderPage.LinesQuantity.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HeaderUIHandlerWithUpdateParent(var HeaderPage: TestPage "Update Parent Header Page")
    begin
        UpdateParentRegisterMgt.Start;
        // Changing data on the page that do update its parent
        HeaderPage.LinesUpdateParent.Amount.Value := FirstLineNextAmount;
        HeaderPage.LinesUpdateParent.Quantity.Value := FirstLineNextQuantity;
        UpdateParentRegisterMgt.Stop();

        LibraryVariableStorage.Enqueue(HeaderPage.LinesAmount.Value);
        LibraryVariableStorage.Enqueue(HeaderPage.LinesQuantity.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HeaderUIHandlerForFactBox(var HeaderPage: TestPage "Update Parent Header Page")
    begin
        UpdateParentRegisterMgt.Start;
        // Changing data on the page that do update its parent
        HeaderPage.FactLines.Name.Value := 'Some text';
        UpdateParentRegisterMgt.Stop();
    end;
}

