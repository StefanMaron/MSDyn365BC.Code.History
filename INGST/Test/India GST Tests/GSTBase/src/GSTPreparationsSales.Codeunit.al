codeunit 18078 "GST Preparations Sales"
{
    Subtype = Test;

    [Test]
    procedure GSTPrepartionUnRegisteredCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358466]	[GST Preparation - Unregistered Customers]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::Unregistered);
        Customer.Modify(true);
    end;

    [Test]
    procedure GSTPrepartionRegisteredCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358462][GST Preparations - Registered Customers]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Customer."P.A.N. No."));
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::Registered);
        Customer.Modify(true);
    end;

    [Test]
    procedure GSTPrepartionExportCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        Country: Record "Country/Region";
        Currency: Record Currency;
        CustomerNo: Code[20];
    begin
        //[Scenario 358511]	[GST Preparations - Export Customers]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        LibraryERM.CreateCountryRegion(Country);
        LibraryERM.CreateCurrency(Currency);
        Customer.Validate("Country/Region Code", Country.Code);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::Export);
        Customer.Modify(true);
    end;


    [Test]
    procedure GSTPrepartionSEZCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358771]	[GST Preparations - SEZ Unit Customer]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Customer."P.A.N. No."));
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::"SEZ Unit");
        Customer.Modify(true);
    end;

    [Test]
    procedure GSTPrepartionSEZDevelopmentCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358772]	[GST Preparations - SEZ Development Customer]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Customer."P.A.N. No."));
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::"SEZ Development");
        Customer.Modify(true);
    end;

    [Test]
    procedure GSTPrepartionDeemedExportCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358775]	[GST Preparations - Deemed Export Customers]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Customer."P.A.N. No."));
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::"Deemed Export");
        Customer.Modify(true);
    end;

    [Test]
    procedure GSTPrepartionExemptedCustomer()
    var
        Customer: Record Customer;
        State: Record State;
        CustomerNo: Code[20];
    begin
        //[Scenario 358776]	[GST Preparations - Exempted Customer]
        CustomerNo := LibraryGST.CreateCustomerSetup();
        Customer.Get(CustomerNo);
        Customer.Validate("State Code", LibraryGST.CreateGSTStateCode());
        State.Get(Customer."State Code");
        Customer.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Customer."P.A.N. No."));
        Customer.Validate("GST Customer Type", Customer."GST Customer Type"::Exempted);
        Customer.Modify(true);
    end;

    var
        LibraryGST: Codeunit "Library GST";
        LibraryERM: Codeunit "Library - ERM";
}
