codeunit 134995 "UT Country/Region Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Country/Region Code] [UT]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForCustomer()
    var
        Customer: Record Customer;
    begin
        with Customer do
            CheckFieldsAreBlankAfterValidation(DATABASE::Customer, FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForVendor()
    var
        Vendor: Record Vendor;
    begin
        with Vendor do
            CheckFieldsAreBlankAfterValidation(DATABASE::Vendor, FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForContact()
    var
        Contact: Record Contact;
    begin
        with Contact do
            CheckFieldsAreBlankAfterValidation(DATABASE::Contact, FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCountryRegionForSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        with SalesHeader do
            CheckFieldsAreNotBlankAfterValidation(DATABASE::"Sales Header",
              FieldNo("Sell-to City"), FieldNo("Sell-to Post Code"), FieldNo("Sell-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromCountryRegionForPurchHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do
            CheckFieldsAreNotBlankAfterValidation(DATABASE::"Purchase Header",
              FieldNo("Buy-from City"), FieldNo("Buy-from Post Code"), FieldNo("Buy-from Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForShipToAddress()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        with ShipToAddress do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Ship-to Address",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForLocation()
    var
        Location: Record Location;
    begin
        with Location do
            CheckFieldsAreBlankAfterValidation(DATABASE::Location,
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForResource()
    var
        Resource: Record Resource;
    begin
        with Resource do
            CheckFieldsAreBlankAfterValidation(DATABASE::Resource,
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForJob()
    var
        Job: Record Job;
    begin
        with Job do
            CheckFieldsAreBlankAfterValidation(DATABASE::Job,
              FieldNo("Bill-to City"), FieldNo("Bill-to Post Code"), FieldNo("Bill-to County"), FieldNo("Bill-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Bank Account",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForReminderHeader()
    var
        ReminderHeader: Record "Reminder Header";
    begin
        with ReminderHeader do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Reminder Header",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForFinChargeMemoHeader()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        with FinanceChargeMemoHeader do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Finance Charge Memo Header",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForContactAltAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        with ContactAltAddress do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Contact Alt. Address",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForEmployee()
    var
        Employee: Record Employee;
    begin
        with Employee do
            CheckFieldsAreBlankAfterValidation(DATABASE::Employee,
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForAlternativeAddress()
    var
        AlternativeAddress: Record "Alternative Address";
    begin
        with AlternativeAddress do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Alternative Address", FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForUnion()
    var
        Union: Record Union;
    begin
        with Union do
            CheckFieldsAreBlankAfterValidation(DATABASE::Union,
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForResponsibilityCenter()
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        with ResponsibilityCenter do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Responsibility Center",
              FieldNo(City), FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferFromCountryRegionForTransferHeader()
    var
        TransferHeader: Record "Transfer Header";
    begin
        with TransferHeader do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Transfer Header", FieldNo("Transfer-from City"),
              FieldNo("Transfer-from Post Code"), FieldNo("Transfer-from County"), FieldNo("Trsf.-from Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferToCountryRegionForTransferHeader()
    var
        TransferHeader: Record "Transfer Header";
    begin
        with TransferHeader do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Transfer Header", FieldNo("Transfer-to City"),
              FieldNo("Transfer-to Post Code"), FieldNo("Transfer-to County"), FieldNo("Trsf.-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCountryRegionForServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        with ServiceHeader do
            CheckFieldsAreNotBlankAfterValidation(DATABASE::"Service Header", FieldNo("Bill-to City"),
              FieldNo("Bill-to Post Code"), FieldNo("Bill-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToCountryRegionForServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        with ServiceHeader do
            CheckFieldsAreNotBlankAfterValidation(DATABASE::"Service Header", FieldNo(City), FieldNo("Post Code"),
              FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForWorkCenter()
    var
        WorkCenter: Record "Work Center";
    begin
        with WorkCenter do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Work Center", FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForMachineCenter()
    var
        MachineCenter: Record "Machine Center";
    begin
        with MachineCenter do
            CheckFieldsAreBlankAfterValidation(DATABASE::"Machine Center", FieldNo(City),
              FieldNo("Post Code"), FieldNo(County), FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCountryCodeAfterValidatingPostCodeSameForTwoCitiesUT()
    var
        Customer: Record Customer;
        CityName: Text[30];
        CountryCode: array[2] of Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 235201] If there are two cities in different countries with the same "Post Code", then when set Customer's "Post Code", City must be picked according to Customer's "Country/Region Code"
        CountryCode[1] := LibraryUTUtility.GetNewCode10();
        CountryCode[2] := LibraryUTUtility.GetNewCode10();

        InitTwoCountries(CountryCode);
        PostCode := LibraryUTUtility.GetNewCode10();
        InitPostCode(CountryCode[2], 'A' + LibraryUTUtility.GetNewCode10(), PostCode);
        CityName := 'Z' + LibraryUTUtility.GetNewCode();
        InitPostCode(CountryCode[1], CityName, PostCode);

        Customer.Init();
        Customer.Validate(Name, LibraryUTUtility.GetNewCode());
        Customer.Validate("Country/Region Code", CountryCode[1]);
        Customer.Insert(true);

        Customer.Get(Customer."No.");
        Customer.Validate("Post Code", PostCode);
        Customer.Modify(true);

        Customer.TestField("Country/Region Code", CountryCode[1]);
        Customer.TestField(City, CityName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCountryCodeAfterValidatingCitySameForTwoCountriesUT()
    var
        Customer: Record Customer;
        CityName: Text[30];
        CountryCode: array[2] of Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 235201] If there are two cities in different countries with the same name, then when set Customer's "City", "Post Code" must be picked according to Customer's "Country/Region Code"
        CountryCode[1] := 'B';
        CountryCode[2] := 'A';
        InitTwoCountries(CountryCode);

        CityName := LibraryUTUtility.GetNewCode();
        InitPostCode(CountryCode[2], CityName, LibraryUTUtility.GetNewCode10());
        PostCode := LibraryUTUtility.GetNewCode10();
        InitPostCode(CountryCode[1], CityName, PostCode);

        Customer.Init();
        Customer.Validate(Name, LibraryUTUtility.GetNewCode());
        Customer.Validate("Country/Region Code", CountryCode[1]);
        Customer.Insert(true);

        Customer.Get(Customer."No.");
        Customer.Validate(City, CityName);
        Customer.Modify(true);

        // [THEN] Post Code was filled during validation 
        Customer.TestField("Country/Region Code", CountryCode[1]);
        Customer.TestField("Post Code", PostCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressUsesCustomerCityIfTwoCitiesWithSamePostCode()
    var
        Customer: Record Customer;
        ShipToAddressPage: TestPage "Ship-to Address";
        CityName: Text[30];
        CountryCode: Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 295922] If there are two cities in same country with the same "Post Code", then when Ship-to Address is created it uses Customer's city

        // [GIVEN] One country Code, One Post Code
        CountryCode := LibraryUtility.GenerateGUID();
        PostCode := LibraryUtility.GenerateGUID();
        InitCountry(CountryCode);

        // [GIVEN] Two Post Code setups, with 2 different City Names, "City1" and "City2"
        InitPostCode(CountryCode, 'A-' + LibraryUtility.GenerateGUID(), PostCode);
        CityName := 'Z-' + LibraryUtility.GenerateGUID();
        InitPostCode(CountryCode, CityName, PostCode);

        // [GIVEN] A Customer with Country Code, Post Code and City Name = "City2"
        CreateCustomerWithAddressInfo(Customer, CountryCode, PostCode, CityName);

        // [WHEN] Create a new Ship-to Address for this Customer via Ship-to Address page
        ShipToAddressPage.OpenNew();
        ShipToAddressPage.FILTER.SetFilter("Customer No.", Customer."No.");
        ShipToAddressPage.New();

        // [THEN] Ship-to Address City = Customer.City
        ShipToAddressPage.City.AssertEquals(Customer.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressUsesCustomerPostCodeIfTwoPostCodesForSameCity()
    var
        Customer: Record Customer;
        ShipToAddressPage: TestPage "Ship-to Address";
        CityName: Text[30];
        CountryCode: Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 295922] If there are two post codes for same city in the same country, then when Ship-to Address is created it uses Customer's city

        // [GIVEN] One country Code, One City Name
        CountryCode := LibraryUtility.GenerateGUID();
        CityName := LibraryUtility.GenerateGUID();
        InitCountry(CountryCode);

        // [GIVEN] Two Post Code setups, with same City Name, 2 different postcodes "Code1" and "Code2"
        InitPostCode(CountryCode, CityName, LibraryUtility.GenerateGUID());
        PostCode := LibraryUtility.GenerateGUID();
        InitPostCode(CountryCode, CityName, PostCode);

        // [GIVEN] A Customer with Country Code, City Name and Post Code = "Code2"
        CreateCustomerWithAddressInfo(Customer, CountryCode, PostCode, CityName);

        // [WHEN] Create a new Ship-to Address for this Customer via Ship-to Address page
        ShipToAddressPage.OpenNew();
        ShipToAddressPage.FILTER.SetFilter("Customer No.", Customer."No.");
        ShipToAddressPage.New();

        // [THEN] Ship-to Address Post Code = Customer."Post Code"
        ShipToAddressPage."Post Code".AssertEquals(Customer."Post Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressCountyVisibility()
    var
        CountryWithoutCounty: Record "Country/Region";
        CountryWithCounty: Record "Country/Region";
        ShiptoAddress: TestPage "Ship-to Address";
    begin
        // [FEATURE] [Address] [County] [UI]
        // [SCENARIO 311818] Page "Ship-to Address" has field "County/State" visible for countries with Address Format "City+County+Post Code"
        InitializeCountriesDifferentFormat(CountryWithoutCounty, CountryWithCounty);

        ShiptoAddress.OpenNew();
        ShiptoAddress."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ShiptoAddress.County.Visible(), 'County field should not be visible');
        ShiptoAddress."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ShiptoAddress.County.Visible(), 'County field should be visible');
    end;

    local procedure CheckFieldsAreBlankAfterValidation(TableNo: Integer; City: Integer; PostCode: Integer; County: Integer; CountryRegionCode: Integer)
    var
        RecRef: RecordRef;
        CityFieldRef: FieldRef;
        PostCodeFieldRef: FieldRef;
        CountyFieldRef: FieldRef;
        CountryRegionFieldRef: FieldRef;
        NewCode: Code[20];
    begin
        // Setup: Assign PostCode,City,County and Country/Region Code.
        NewCode := LibraryUTUtility.GetNewCode();
        RecRef.Open(TableNo);
        CityFieldRef := RecRef.Field(City);
        CityFieldRef.Value := NewCode;
        PostCodeFieldRef := RecRef.Field(PostCode);
        PostCodeFieldRef.Value := NewCode;
        CountyFieldRef := RecRef.Field(County);
        CountyFieldRef.Value := NewCode;
        CountryRegionFieldRef := RecRef.Field(CountryRegionCode);
        CountryRegionFieldRef.Value := LibraryUTUtility.GetNewCode10();
        RecRef.Insert();

        // Exercise: Validate Country/Region Code as blank.
        CountryRegionFieldRef.Validate('');

        // Verify: Verify PostCode,City and County are blank.
        CityFieldRef.TestField('');
        PostCodeFieldRef.TestField('');
        CountyFieldRef.TestField('');
    end;

    local procedure CheckFieldsAreNotBlankAfterValidation(TableNo: Integer; City: Integer; PostCode: Integer; CountryRegionCode: Integer)
    var
        RecRef: RecordRef;
        CityFieldRef: FieldRef;
        PostCodeFieldRef: FieldRef;
        CountryRegionFieldRef: FieldRef;
        NewCode: Code[20];
    begin
        // Setup: Assign PostCode,City and Country/Region Code.
        NewCode := LibraryUTUtility.GetNewCode();
        RecRef.Open(TableNo);
        CityFieldRef := RecRef.Field(City);
        CityFieldRef.Value := NewCode;
        PostCodeFieldRef := RecRef.Field(PostCode);
        PostCodeFieldRef.Value := NewCode;
        CountryRegionFieldRef := RecRef.Field(CountryRegionCode);
        CountryRegionFieldRef.Value := LibraryUTUtility.GetNewCode10();
        RecRef.Insert();

        // Exercise: Validate Country/Region Code as blank.
        CountryRegionFieldRef.Validate('');

        // Verify: Verify PostCode andCity are not blank.
        CityFieldRef.TestField(NewCode);
        PostCodeFieldRef.TestField(NewCode);
    end;

    local procedure InitCountry(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        CountryRegion.Insert(true);
    end;

    local procedure InitTwoCountries(CountryCode: array[2] of Code[10])
    begin
        InitCountry(CountryCode[1]);
        InitCountry(CountryCode[2]);
    end;

    local procedure InitializeCountriesDifferentFormat(var CountryWithoutCounty: Record "Country/Region"; var CountryWithCounty: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryWithoutCounty);
        CountryWithoutCounty."Address Format" := CountryWithCounty."Address Format"::"City+Post Code";
        CountryWithoutCounty.Modify();

        LibraryERM.CreateCountryRegion(CountryWithCounty);
        CountryWithCounty."Address Format" := CountryWithCounty."Address Format"::"City+County+Post Code";
        CountryWithCounty.Modify();
    end;

    local procedure InitPostCode(CountryCode: Code[10]; CityName: Text[30]; PostCodeValue: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        PostCode.Reset();
        PostCode.Init();
        PostCode.Validate(Code, PostCodeValue);
        PostCode.Validate(City, CityName);
        PostCode.Validate("Country/Region Code", CountryCode);
        PostCode.Insert(true);
    end;

    local procedure CreateCustomerWithAddressInfo(var Customer: Record Customer; CountryCode: Code[10]; PostCode: Code[20]; CityName: Text[30])
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            "Country/Region Code" := CountryCode;
            "Post Code" := PostCode;
            City := CityName;
            Modify(true);
        end;
    end;
}

