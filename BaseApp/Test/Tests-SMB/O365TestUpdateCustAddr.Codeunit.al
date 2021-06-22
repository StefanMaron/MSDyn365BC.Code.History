codeunit 138054 "O365 Test Update Cust. Addr."
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Customer] [Address] [Sales] [Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('O365AddressHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateEmtyCustomerFromInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        Addr1: Text[50];
        PostCode: Code[10];
        City: Text[30];
    begin
        // [GIVEN] A customer with no address
        LibrarySales.CreateCustomer(Customer);
        Assert.AreEqual('', Customer.Address, '');
        Assert.AreEqual('', Customer.City, '');
        Assert.AreEqual('', Customer."Post Code", '');
        Addr1 := Format(CreateGuid);
        City := CopyStr(Format(CreateGuid), 1, MaxStrLen(City));
        PostCode := '90210';
        CreatePostCode(PostCode, City);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates an invoice and enters an address
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        LibraryVariableStorage.Enqueue(Addr1);
        LibraryVariableStorage.Enqueue(PostCode);
        LibraryVariableStorage.Enqueue(City);
        O365SalesInvoice.FullAddress.AssistEdit;
        SalesHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesHeader.FindLast;
        O365SalesInvoice.SaveForLater.Invoke;

        // [THEN] The customer address is updated
        SalesHeader.Find;
        Assert.AreEqual(Addr1, SalesHeader."Bill-to Address", 'Wrong Bill-to Address');
        Assert.AreEqual(City, SalesHeader."Bill-to City", 'Wrong Bill-to City');
        Assert.AreEqual(PostCode, SalesHeader."Bill-to Post Code", 'Wrong Bill-to Post Code');

        Customer.Find;
        Assert.AreEqual(Addr1, Customer.Address, 'Wrong Address');
        Assert.AreEqual(City, Customer.City, 'Wrong City');
        Assert.AreEqual(PostCode, Customer."Post Code", 'Wrong Post Code');
    end;

    [Test]
    [HandlerFunctions('O365AddressHandler')]
    [Scope('OnPrem')]
    procedure TestChangeAddressForCustomerWithAddress()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        Addr1: Text[50];
        PostCode: Code[10];
        City: Text[30];
    begin
        // [GIVEN] A customer with an existing address
        LibrarySales.CreateCustomer(Customer);
        PostCode := '2800';
        CreatePostCode(PostCode, 'Lyngby');
        Customer.Address := Format(CreateGuid);
        Customer.City := CopyStr(Format(CreateGuid), 1, MaxStrLen(Customer.City));
        Customer."Post Code" := PostCode;
        Customer.Modify;

        Addr1 := Format(CreateGuid);
        City := CopyStr(Format(CreateGuid), 1, MaxStrLen(City));
        PostCode := '90210';
        CreatePostCode(PostCode, City);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates an invoice and enters an address
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        LibraryVariableStorage.Enqueue(Addr1);
        LibraryVariableStorage.Enqueue(PostCode);
        LibraryVariableStorage.Enqueue(City);
        O365SalesInvoice.FullAddress.AssistEdit;
        SalesHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesHeader.FindLast;
        O365SalesInvoice.SaveForLater.Invoke;

        // [THEN] The customer address is not updated
        Customer.Find;
        Assert.AreNotEqual(Addr1, Customer.Address, 'Wrong Address');
        Assert.AreNotEqual(City, Customer.City, 'Wrong City');
        Assert.AreNotEqual(PostCode, Customer."Post Code", 'Wrong Post Code');

        SalesHeader.Find;
        Assert.AreEqual(Addr1, SalesHeader."Bill-to Address", 'Wrong Bill-to Address');
        Assert.AreEqual(City, SalesHeader."Bill-to City", 'Wrong Bill-to City');
        Assert.AreEqual(PostCode, SalesHeader."Bill-to Post Code", 'Wrong Bill-to Post Code');
    end;

    local procedure CreatePostCode(NewPostCode: Code[10]; NewCity: Text[30])
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, NewPostCode);
        if PostCode.FindFirst then
            PostCode.DeleteAll;
        PostCode.Init;
        PostCode.Validate(Code, NewPostCode);
        PostCode.Validate(City, NewCity);
        if PostCode.Insert then;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365AddressHandler(var O365Address: TestPage "O365 Address")
    begin
        O365Address.Address.Value(LibraryVariableStorage.DequeueText);
        O365Address."Post Code".Value(LibraryVariableStorage.DequeueText);
        O365Address.City.Value(LibraryVariableStorage.DequeueText);
        O365Address.OK.Invoke;
    end;
}

