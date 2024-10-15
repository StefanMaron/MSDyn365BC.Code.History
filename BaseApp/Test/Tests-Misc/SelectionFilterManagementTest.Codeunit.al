codeunit 132537 SelectionFilterManagementTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Selection Filter Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCurrency()
    var
        Currency: Record Currency;
        SelectionString: Text;
    begin
        with Currency do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCurrency(Currency));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SelectionString: Text;
    begin
        with CustomerPriceGroup do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomerPriceGroup(CustomerPriceGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForLocation()
    var
        Location: Record Location;
        SelectionString: Text;
    begin
        with Location do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForLocation(Location));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForGLAccount()
    var
        GLAccount: Record "G/L Account";
        SelectionString: Text;
    begin
        with GLAccount do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForGLAccount(GLAccount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomer()
    var
        Customer: Record Customer;
        SelectionString: Text;
    begin
        with Customer do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomer(Customer));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForContact()
    var
        Contact: Record Contact;
        SelectionString: Text;
    begin
        with Contact do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForContact(Contact));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForVendor()
    var
        Vendor: Record Vendor;
        SelectionString: Text;
    begin
        with Vendor do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForVendor(Vendor));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItem()
    var
        Item: Record Item;
        SelectionString: Text;
    begin
        with Item do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItem(Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForResource()
    var
        Resource: Record Resource;
        SelectionString: Text;
    begin
        with Resource do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForResource(Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForInventoryPostingGroup()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        SelectionString: Text;
    begin
        with InventoryPostingGroup do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForInventoryPostingGroup(InventoryPostingGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForGLBudgetName()
    var
        GLBudgetName: Record "G/L Budget Name";
        SelectionString: Text;
    begin
        with GLBudgetName do begin
            if not FindFirst() then begin
                Init();
                Name := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Name);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForGLBudgetName(GLBudgetName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForBusinessUnit()
    var
        BusinessUnit: Record "Business Unit";
        SelectionString: Text;
    begin
        with BusinessUnit do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForBusinessUnit(BusinessUnit));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerDiscountGroup()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        SelectionString: Text;
    begin
        with CustomerDiscountGroup do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomerDiscountGroup(CustomerDiscountGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItemDiscountGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        SelectionString: Text;
    begin
        with ItemDiscountGroup do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItemDiscountGroup(ItemDiscountGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItemCategory()
    var
        ItemCategory: Record "Item Category";
        SelectionString: Text;
    begin
        with ItemCategory do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItemCategory(ItemCategory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForDimensionValue()
    var
        DimensionValue: Record "Dimension Value";
        SelectionString: Text;
    begin
        with DimensionValue do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimensionValue));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddQuotesTest()
    var
        TestString: Text;
        ActualString: Text;
        ExpectedString: Text;
    begin
        TestString := 'NormalString';
        ExpectedString := TestString;
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'Single''NoSpecialChar';
        ExpectedString := 'Single''''NoSpecialChar';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'String with single '' quotes';
        ExpectedString := '''String with single '''' quotes''';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'String with special char: %&';
        ExpectedString := '''String with special char: %&''';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetSelectionFilterForDimensionValueWithSpecialSymbols()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension] [Dimension Value] [UT]
        // [SCENARIO 312912] Function GetSelectionFilterForDimensionValue of SelectionFilterManagement puts Dimension Value Code between single quotes in case Code contains chars &.@<>=

        // [GIVEN] Dimension Values A, A1, B, B1, C, C1, D, D1, E with Code, that contains chars &.@<>=
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<>N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK=N7S', LibraryERM.GetGlobalDimensionCode(1));

        // [WHEN] Filter Dimension Value to "A|B|C|D|E". Run GetSelectionFilterForDimensionValue of SelectionFilterManagement codeunit on the filtered record.
        // [THEN] Function returns "'A'|'B'|'C'|'D'|'E'", i.e. each Dimension Value Code is put between single quotes.
        DimensionValue.SetFilter(Code, '*N7S');
        Assert.AreEqual(
          '''XK&N7S''|''XK.N7S''|''XK@N7S''|''XK<>N7S''|''XK=N7S''',
          SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimensionValue), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForICPartner()
    var
        ICPartner: Record "IC Partner";
        SelectionString: Text;
    begin
        with ICPartner do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForICPartner(ICPartner));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCashFlow()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SelectionString: Text;
    begin
        with CashFlowForecast do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCashFlow(CashFlowForecast));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCashFlowAccount()
    var
        CashFlowAccount: Record "Cash Flow Account";
        SelectionString: Text;
    begin
        with CashFlowAccount do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCashFlowAccount(CashFlowAccount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostBudgetName()
    var
        CostBudgetName: Record "Cost Budget Name";
        SelectionString: Text;
    begin
        with CostBudgetName do begin
            if not FindFirst() then begin
                Init();
                Name := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Name);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostBudgetName(CostBudgetName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostCenter()
    var
        CostCenter: Record "Cost Center";
        SelectionString: Text;
    begin
        with CostCenter do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostCenter(CostCenter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostObject()
    var
        CostObject: Record "Cost Object";
        SelectionString: Text;
    begin
        with CostObject do begin
            if not FindFirst() then begin
                Init();
                Code := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostObject(CostObject));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostType()
    var
        CostType: Record "Cost Type";
        SelectionString: Text;
    begin
        with CostType do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostType(CostType));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCampaign()
    var
        Campaign: Record Campaign;
        SelectionString: Text;
    begin
        with Campaign do begin
            if not FindFirst() then begin
                Init();
                "No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCampaign(Campaign));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForLotNoInformation()
    var
        LotNoInformation: Record "Lot No. Information";
        SelectionString: Text;
    begin
        with LotNoInformation do begin
            if not FindFirst() then begin
                Init();
                "Lot No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("Lot No.");
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForLotNoInformation(LotNoInformation));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForSerialNoInformation()
    var
        SerialNoInformation: Record "Serial No. Information";
        SelectionString: Text;
    begin
        with SerialNoInformation do begin
            if not FindFirst() then begin
                Init();
                "Serial No." := '1';
                Insert();
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes("Serial No.");
        end;

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForSerialNoInformation(SerialNoInformation));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempCustomerTableNotAllRecords()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Customers: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table does not contain all Customer records.

        // [GIVEN] Customers C1, C2,..., C10. Customers C1, C2, C3, C5, C7, C8, C9, C10 are added to temporary Customer table.
        for i := 1 to 10 do begin
            LibrarySales.CreateCustomer(Customer);
            Customers.Add(Customer."No.");
            TempCustomer := Customer;
            TempCustomer.Insert();
        end;
        TempCustomer.SetFilter("No.", '%1|%2', Customers.Get(4), Customers.Get(6));
        TempCustomer.DeleteAll();
        TempCustomer.Reset();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'C1..C3|C5|C7..C10'.
        Assert.AreEqual(
            StrSubstNo('%1..%2|%3|%4..%5', Customers.Get(1), Customers.Get(3), Customers.Get(5), Customers.Get(7), Customers.Get(10)), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempVendorTableAllRecords()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Vendors: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Vendor temporary table in case temporary table contains consecutive Vendor records.

        // [GIVEN] Vendors V1, V2,..., V5. All these Vendors are added to temporary Vendor table.
        for i := 1 to 5 do begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendors.Add(Vendor."No.");
            TempVendor := Vendor;
            TempVendor.Insert();
        end;

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Vendor table.
        TempRecRef.GetTable(TempVendor);
        RecRef.GetTable(Vendor);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Vendor.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'V1..V5'.
        Assert.AreEqual(
            StrSubstNo('%1..%2', Vendors.Get(1), Vendors.Get(Vendors.Count())), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempItemTableNoConsecutiveRecords()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Items: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Item temporary table in case temporary table does not contain consecutive Item records.

        // [GIVEN] Items I1, I2,..., I7. Items I1, I3, I5, I7 are added to temporary Item table.
        for i := 1 to 7 do begin
            LibraryInventory.CreateItem(Item);
            Items.Add(Item."No.");
            TempItem := Item;
            TempItem.Insert();
        end;
        TempItem.SetFilter("No.", '%1|%2|%3', Items.Get(2), Items.Get(4), Items.Get(6));
        TempItem.DeleteAll();
        TempItem.Reset();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Item table.
        TempRecRef.GetTable(TempItem);
        RecRef.GetTable(Item);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Item.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'I1|I3|I5|I7'.
        Assert.AreEqual(
            StrSubstNo('%1|%2|%3|%4', Items.Get(1), Items.Get(3), Items.Get(5), Items.Get(7)), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromEmptyTempCustomerTable()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        FilterString: Text;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table does not contain any records.

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on empty temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns empty string ''.
        Assert.AreEqual('', FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempCustomerTableRecordNotExist()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table contains non-existing record.

        // [GIVEN] Temporary Customer table contains one existing record and one non-existing record.
        LibrarySales.CreateCustomer(Customer);
        TempCustomer := Customer;
        TempCustomer.Insert();

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.SetRecFilter();
        Assert.RecordIsEmpty(Customer);
        TempCustomer := Customer;
        TempCustomer.Insert();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        asserterror SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] An error "The Customer does not exist" is thrown.
        Assert.ExpectedError('The Customer does not exist');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEither()
    begin
        ComplexTestForGetSelectionFilter('2|5', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInterval()
    begin
        ComplexTestForGetSelectionFilter('2..5', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEitherPlsInterval()
    begin
        ComplexTestForGetSelectionFilter('2|4..6', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIntervalPlsEither()
    begin
        ComplexTestForGetSelectionFilter('2..4|8', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEitherPlsIntervalPlsEither()
    begin
        ComplexTestForGetSelectionFilter('2|4..6|8', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingOfNonNumericCodes()
    begin
        // should pin bug 275352
        ComplexTestForGetSelectionFilter('2T..5', true);
    end;

    local procedure ComplexTestForGetSelectionFilter(SelectionString: Text; AddNonNumerical: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
        ItemNo: Code[20];
    begin
        ItemNo := InsertTestValues();
        if AddNonNumerical then
            InsertSerialNoInformation(ItemNo, '2T');

        SerialNoInformation.SetFilter("Item No.", ItemNo);
        SerialNoInformation.SetFilter("Serial No.", SelectionString);
        with SerialNoInformation do begin
            repeat
                Mark(true);
            until Next() = 0;
            SetRange("Serial No.");
            SetRange("Item No.");
            MarkedOnly(true);
        end;

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForSerialNoInformation(SerialNoInformation));
    end;

    local procedure CheckGetSelectionResults(SelectionString: Text; SelectionString2: Text)
    begin
        Assert.AreEqual(
          SelectionString,
          SelectionString2,
          StrSubstNo(
            'Problem with SelectionFilterManagement: \Original selection: <%1>. \Returned selection: <%2>',
            SelectionString, SelectionString2));
    end;

    local procedure InsertSerialNoInformation(ItemNo: Code[20]; SerialNo: Code[50])
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := ItemNo;
        SerialNoInformation."Serial No." := SerialNo;
        SerialNoInformation.Insert();
    end;

    local procedure InsertTestValues(): Code[20]
    var
        SerialNoInformation: Record "Serial No. Information";
        Item: Record Item;
        ItemNo: Code[20];
        i: Integer;
    begin
        SerialNoInformation.DeleteAll();
        Item.FindSet();
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemNo := Item."No.";
        for i := 1 to 8 do
            InsertSerialNoInformation(ItemNo, Format(i));

        exit(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerComputingRangesOnLists()
    var
        Customer: Record Customer;
        CurrencyRecordRef: RecordRef;
        SelectionString: Text;
    begin
        // [SCENARIO] GetSelectionFilter procedure can be used to get the filter on the primary key from the selected (marked) records.

        // [GIVEN] A table (Currency) with at least 1 record
        if not Customer.FindFirst() then begin
            Customer.Init();
            Customer."No." := 'ABC';
            Customer.Insert();
        end;

        // [WHEN] A record in the table is selected (marked).
        Customer.Mark(true);
        Customer.MarkedOnly(true);
        CurrencyRecordRef.GetTable(Customer);

        // [THEN] The filter consists of just one value - the primary key field value of the selected record (Currency.Code).
        SelectionString := SelectionFilterManagement.AddQuotes(Customer."No.");
        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilter(CurrencyRecordRef, Customer.FieldNo("No."), false));
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetSelectionFilterForDimensionValueWithSpecialSymbolsComputingRangesOnLists()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValueRecordRef: RecordRef;
    begin
        // [FEATURE] [Dimension] [Dimension Value] [UT]
        // [SCENARIO 312912] Function GetSelectionFilterForDimensionValue of SelectionFilterManagement puts Dimension Value Code between single quotes in case Code contains chars &.@<>=

        // [GIVEN] Dimension Values A, A1, B, B1, C, C1, D, D1, E with Code, that contains chars &.@<>=
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<>N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK=N7S', LibraryERM.GetGlobalDimensionCode(1));

        // [WHEN] Filter Dimension Value to "A|B|C|D|E". Run GetSelectionFilterForDimensionValue of SelectionFilterManagement codeunit on the filtered record.
        // [THEN] Function returns "'A'|'B'|'C'|'D'|'E'", i.e. each Dimension Value Code is put between single quotes.
        DimensionValue.SetFilter(Code, '*N7S');
        DimensionValueRecordRef.GetTable(DimensionValue);
        Assert.AreEqual(
          '''XK&N7S''|''XK.N7S''|''XK@N7S''|''XK<>N7S''|''XK=N7S''',
          SelectionFilterManagement.GetSelectionFilter(DimensionValueRecordRef, DimensionValue.FieldNo(Code), false), '');
    end;
}

