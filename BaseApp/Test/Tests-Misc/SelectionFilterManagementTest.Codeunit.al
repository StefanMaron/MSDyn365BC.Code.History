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

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCurrency()
    var
        Currency: Record Currency;
        SelectionString: Text;
    begin
        with Currency do begin
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Name := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
            end;
            Mark(true);
            MarkedOnly(true);
            SelectionString := SelectionFilterManagement.AddQuotes(Code);
        end;

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimensionValue));
    end;

    [Test]
    [Scope('OnPrem')]
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Name := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                Code := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "Lot No." := '1';
                Insert;
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
            if not FindFirst then begin
                Init;
                "Serial No." := '1';
                Insert;
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
        ItemNo := InsertTestValues;
        if AddNonNumerical then
            InsertSerialNoInformation(ItemNo, '2T');

        SerialNoInformation.SetFilter("Item No.", ItemNo);
        SerialNoInformation.SetFilter("Serial No.", SelectionString);
        with SerialNoInformation do begin
            repeat
                Mark(true);
            until Next = 0;
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

    local procedure InsertSerialNoInformation(ItemNo: Code[20]; SerialNo: Code[20])
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
        Item.FindSet;
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemNo := Item."No.";
        for i := 1 to 8 do
            InsertSerialNoInformation(ItemNo, Format(i));

        exit(ItemNo);
    end;
}

