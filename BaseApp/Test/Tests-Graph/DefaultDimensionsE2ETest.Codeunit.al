codeunit 135544 "Default Dimensions E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Default Dimension]
    end;

    var
        CustomerServiceNameTxt: Label 'customers';
        VendorServiceNameTxt: Label 'vendors';
        EmployeeServiceNameTxt: Label 'employees';
        ItemServiceNameTxt: Label 'items';
        DefaultDimensionsServiceNameTxt: Label 'defaultDimensions';
        Assert: Codeunit Assert;
        TypeHelper: Codeunit "Type Helper";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        EmptyResponseErr: Label 'Response should not be empty.';
        BadRequestErr: Label 'BadRequest', Locked = true;
        DimensionIdMismatchErr: Label 'The "dimensionId" and "dimensionValueId" match to different Dimension records.', Locked = true;
        BlockedDimensionErr: Label '%1 %2 is blocked.', Comment = '%1 - Dimension table caption, %2 - Dimension code';
        DimValueBlockedErr: Label '%1 %2 - %3 is blocked.', Comment = '%1 = Dimension Value table caption, %2 = Dim Code, %3 = Dim Value';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryHumanResource: Codeunit "Library - Human Resource";

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionWithDimensionCodeOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the customer
        // [THEN] The default dimension has been added to the customer
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimensionWithDimensionCode(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionWithDimensionCodeOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a vendor, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the vendor
        // [THEN] The default dimension has been added to the vendor
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimensionWithDimensionCode(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionWithDimensionCodeOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Item
        // [THEN] The default dimension has been added to the Item
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimensionWithDimensionCode(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionWithDimensionCodeOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Employee
        // [THEN] The default dimension has been added to the Employee
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimensionWithDimensionCode(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the customer
        // [THEN] The default dimension has been added to the customer
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimension(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Vendor
        // [THEN] The default dimension has been added to the Vendor
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimension(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Item
        // [THEN] The default dimension has been added to the Item
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimension(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Employee
        // [THEN] The default dimension has been added to the Employee
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimension(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithoutDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] a user issues a http request to create a default dimension without dimension id
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimensionFailsWithoutDimension(DATABASE::Customer, Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithoutDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor, a dimension and a dimension value
        // [WHEN] a user issues a http request to create a default dimension without dimension id
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimensionFailsWithoutDimension(DATABASE::Vendor, Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithoutDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] a user issues a http request to create a default dimension without dimension id
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimensionFailsWithoutDimension(DATABASE::Item, Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithoutDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] a user issues a http request to create a default dimension without dimension id
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimensionFailsWithoutDimension(DATABASE::Employee, Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithMismatchingDimensionsOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the customer, with mismatching dimesnion and dimension value
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimensionFailsWithMismatchingDimensions(DATABASE::Customer, Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithMismatchingDimensionsOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Vendor, with mismatching dimesnion and dimension value
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimensionFailsWithMismatchingDimensions(DATABASE::Vendor, Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithMismatchingDimensionsOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Item, with mismatching dimesnion and dimension value
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimensionFailsWithMismatchingDimensions(DATABASE::Item, Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithMismatchingDimensionsOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension on the Employee, with mismatching dimesnion and dimension value
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimensionFailsWithMismatchingDimensions(DATABASE::Employee, Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension on the customer
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimensionFailsWithBlockedDimension(DATABASE::Customer, Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension on the Vendor
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimensionFailsWithBlockedDimension(DATABASE::Vendor, Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension on the Item
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimensionFailsWithBlockedDimension(DATABASE::Item, Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension on the Employee
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimensionFailsWithBlockedDimension(DATABASE::Employee, Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionValueOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension value on the customer
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestCreateDefaultDimensionFailsWithBlockedDimensionValue(DATABASE::Customer, Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionValueOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension value on the Vendor
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestCreateDefaultDimensionFailsWithBlockedDimensionValue(DATABASE::Vendor, Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionValueOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension value on the Item
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestCreateDefaultDimensionFailsWithBlockedDimensionValue(DATABASE::Item, Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDimensionFailsWithBlockedDimensionValueOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee, a dimension and a dimension value
        // [WHEN] The user posts a http request to create a default dimension with a blocked dimension value on the Employee
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestCreateDefaultDimensionFailsWithBlockedDimensionValue(DATABASE::Employee, Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDefaultDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer with a default dimension
        // [WHEN] The user posts a http request to delete the default dimension on the customer
        // [THEN] The default dimension has been deleted from the customer's default dimensions
        LibrarySales.CreateCustomer(Customer);
        TestDeleteDefaultDimension(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDefaultDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor with a default dimension
        // [WHEN] The user posts a http request to delete a default dimension on the Vendor
        // [THEN] The default dimension has been deleted from the vendor's default dimensions
        LibraryPurchase.CreateVendor(Vendor);
        TestDeleteDefaultDimension(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDefaultDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item with a default dimension
        // [WHEN] The user posts a http request to delete a default dimension on the Item
        // [THEN] The default dimension has been deleted from the item's default dimensions
        LibraryInventory.CreateItem(Item);
        TestDeleteDefaultDimension(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDefaultDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee with a default dimension
        // [WHEN] The user posts a http request to delete a default dimension on the Employee
        // [THEN] The default dimension has been deleted from the employee's default dimensions
        LibraryHumanResource.CreateEmployee(Employee);
        TestDeleteDefaultDimension(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDefaultDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer with a default dimension
        // [WHEN] The user posts a http request to get the default dimension on the customer
        // [THEN] The response contains the default dimension that has been added to the customer
        LibrarySales.CreateCustomer(Customer);
        TestGetDefaultDimension(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDefaultDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor with a default dimension
        // [WHEN] The user posts a http request to get a default dimension on the Vendor
        // [THEN] The response contains the default dimension that has been added to the Vendor
        LibraryPurchase.CreateVendor(Vendor);
        TestGetDefaultDimension(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDefaultDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item with a default dimension
        // [WHEN] The user posts a http request to get a default dimension on the Item
        // [THEN] The response contains the default dimension that has been added to the Item
        LibraryInventory.CreateItem(Item);
        TestGetDefaultDimension(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDefaultDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee with a default dimension
        // [WHEN] The user posts a http request to get a default dimension on the Employee
        // [THEN] The response contains the default dimension that has been added to the Employee
        LibraryHumanResource.CreateEmployee(Employee);
        TestGetDefaultDimension(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension on the customer
        // [THEN] The default dimension has been updated for the customer
        LibrarySales.CreateCustomer(Customer);
        TestPatchDefaultDimension(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension on the Vendor
        // [THEN] The default dimension has been updated for the vendor
        LibraryPurchase.CreateVendor(Vendor);
        TestPatchDefaultDimension(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension on the Item
        // [THEN] The default dimension has been updated for the item
        LibraryInventory.CreateItem(Item);
        TestPatchDefaultDimension(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension on the Employee
        // [THEN] The default dimension has been updated for the employee
        LibraryHumanResource.CreateEmployee(Employee);
        TestPatchDefaultDimension(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWithBlockedValueOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension with a blocked dimension value on the customer
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestPatchDefaultDimensionFailsWithBlockedValue(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWithBlockedValueOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a Vendor with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension with a blocked dimension value on the Vendor
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestPatchDefaultDimensionFailsWithBlockedValue(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWithBlockedValueOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a Item with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension with a blocked dimension value on the Item
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestPatchDefaultDimensionFailsWithBlockedValue(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWithBlockedValueOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a Employee with a default dimension
        // [WHEN] The user posts a http request to patch a default dimension with a blocked dimension value on the Employee
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestPatchDefaultDimensionFailsWithBlockedValue(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWhenChangingDimensionCodeOnCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] a customer with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension with a blocked dimension value on the customer
        // [THEN] You get an error
        LibrarySales.CreateCustomer(Customer);
        TestPatchDefaultDimensionFailsWhenChangingDimensionCode(DATABASE::Customer, Customer."No.", Customer.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWhenChangingDimensionCodeOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] a vendor with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension with a blocked dimension value on the vendor
        // [THEN] You get an error
        LibraryPurchase.CreateVendor(Vendor);
        TestPatchDefaultDimensionFailsWhenChangingDimensionCode(DATABASE::Vendor, Vendor."No.", Vendor.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWhenChangingDimensionCodeOnItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] a item with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension with a blocked dimension value on the item
        // [THEN] You get an error
        LibraryInventory.CreateItem(Item);
        TestPatchDefaultDimensionFailsWhenChangingDimensionCode(DATABASE::Item, Item."No.", Item.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchDefaultDimensionFailsWhenChangingDimensionCodeOnEmployee()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Employee]
        // [GIVEN] a employee with a default dimension
        // [WHEN] The user posts a http request to patch the default dimension with a blocked dimension value on the employee
        // [THEN] You get an error
        LibraryHumanResource.CreateEmployee(Employee);
        TestPatchDefaultDimensionFailsWhenChangingDimensionCode(DATABASE::Employee, Employee."No.", Employee.Id);
    end;

    local procedure TestCreateDefaultDimensionWithDimensionCode(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        DimensionValueId: Text;
        ParentIdAsText: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, '', Dimension.Code, DimensionValueId, '', '');
        LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);

        Assert.IsTrue(
          DefaultDimension.Get(TableNo, ParentNo, Dimension.Code), 'Default Dimension not created for the test entity.');
        Assert.AreEqual(
          DefaultDimension."Dimension Value Code", DimensionValue.Code, 'Unexpected default dimension value for the test entity.');
        Assert.AreEqual(DefaultDimension.DimensionId, Dimension.Id, 'Unexpected dimension Id value for the test entity.');
    end;

    local procedure TestCreateDefaultDimension(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValueId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, DimensionId, '', DimensionValueId, '', '');
        LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);

        Assert.IsTrue(
          DefaultDimension.Get(TableNo, ParentNo, Dimension.Code), 'Default Dimension not created for the test entity.');
        Assert.AreEqual(
          DefaultDimension."Dimension Value Code", DimensionValue.Code, 'Unexpected default dimension value for the test entity.');
    end;

    local procedure TestCreateDefaultDimensionFailsWithoutDimension(TableNo: Integer; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        ParentIdAsText: Text;
        DimensionValueId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, '', '', DimensionValueId, '', '');

        asserterror LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);
        Assert.ExpectedError(BadRequestErr);
    end;

    local procedure TestCreateDefaultDimensionFailsWithMismatchingDimensions(TableNo: Integer; ParentId: Guid)
    var
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValue2Id: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValue2Id := LowerCase(TypeHelper.GetGuidAsString(DimensionValue2.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, DimensionId, '', DimensionValue2Id, '', '');

        asserterror LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);
        Assert.ExpectedError(DimensionIdMismatchErr);
    end;

    local procedure TestCreateDefaultDimensionFailsWithBlockedDimension(TableNo: Integer; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValueId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        Dimension.Validate(Blocked, true);
        Dimension.Modify(true);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, DimensionId, '', DimensionValueId, '', '');

        asserterror LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);
        Assert.ExpectedError(StrSubstNo(BlockedDimensionErr, Dimension.TableCaption, Dimension.Code));
    end;

    local procedure TestCreateDefaultDimensionFailsWithBlockedDimensionValue(TableNo: Integer; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValueId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue.Validate(Blocked, true);
        DimensionValue.Modify(true);
        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody(ParentIdAsText, DimensionId, '', DimensionValueId, '', '');

        asserterror LibraryGraphMgt.PostToWebService(TargetURL, DefaultDimensionJSON, Response);
        Assert.ExpectedError(StrSubstNo(DimValueBlockedErr, DimensionValue.TableCaption, Dimension.Code, DimensionValue.Code));
    end;

    local procedure TestDeleteDefaultDimension(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        Response: Text;
        SubpageWithIdTxt: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DefaultDimension.Validate("Table ID", TableNo);
        DefaultDimension.Validate("No.", ParentNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Insert(true);

        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        SubpageWithIdTxt := DefaultDimensionsServiceNameTxt + StrSubstNo('(%1,%2)', ParentIdAsText, DimensionId);
        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, DefaultDimensionsServiceNameTxt, SubpageWithIdTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Response);

        Assert.IsFalse(DefaultDimension.Get(TableNo, ParentNo, Dimension.Code), 'Default dimension was not deleted.');
    end;

    local procedure TestGetDefaultDimension(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        Response: Text;
        SubpageWithIdTxt: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValueId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DefaultDimension.Validate("Table ID", TableNo);
        DefaultDimension.Validate("No.", ParentNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Insert(true);

        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValueId := LowerCase(TypeHelper.GetGuidAsString(DimensionValue.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        SubpageWithIdTxt := DefaultDimensionsServiceNameTxt + StrSubstNo('(%1,%2)', ParentIdAsText, DimensionId);
        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, DefaultDimensionsServiceNameTxt, SubpageWithIdTxt);
        LibraryGraphMgt.GetFromWebService(Response, TargetURL);

        VerifyDefaultDimensionResponseBody(Response, ParentIdAsText, DimensionId, '', DimensionValueId, '', '');
    end;

    local procedure TestPatchDefaultDimension(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        SubpageWithIdTxt: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValue2Id: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        DefaultDimension.Validate("Table ID", TableNo);
        DefaultDimension.Validate("No.", ParentNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Insert(true);

        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValue2Id := LowerCase(TypeHelper.GetGuidAsString(DimensionValue2.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        SubpageWithIdTxt := DefaultDimensionsServiceNameTxt + StrSubstNo('(%1,%2)', ParentIdAsText, DimensionId);
        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, DefaultDimensionsServiceNameTxt, SubpageWithIdTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody('', '', '', DimensionValue2Id, '', 'Same Code');
        LibraryGraphMgt.PatchToWebService(TargetURL, DefaultDimensionJSON, Response);

        DefaultDimension.Get(TableNo, ParentNo, Dimension.Code);
        Assert.AreEqual(DefaultDimension."Dimension Value Code", DimensionValue2.Code, '');
        Assert.AreEqual(DefaultDimension."Value Posting", DefaultDimension."Value Posting"::"Same Code", '');
    end;

    local procedure TestPatchDefaultDimensionFailsWithBlockedValue(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        SubpageWithIdTxt: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
        DimensionValue2Id: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        DimensionValue2.Validate(Blocked, true);
        DimensionValue2.Modify(true);
        DefaultDimension.Validate("Table ID", TableNo);
        DefaultDimension.Validate("No.", ParentNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Insert(true);

        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        DimensionValue2Id := LowerCase(TypeHelper.GetGuidAsString(DimensionValue2.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        SubpageWithIdTxt := DefaultDimensionsServiceNameTxt + StrSubstNo('(%1,%2)', ParentIdAsText, DimensionId);
        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, DefaultDimensionsServiceNameTxt, SubpageWithIdTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody('', '', '', DimensionValue2Id, '', 'Same Code');

        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, DefaultDimensionJSON, Response);
        Assert.ExpectedError(StrSubstNo(DimValueBlockedErr, DimensionValue.TableCaption, Dimension.Code, DimensionValue2.Code));
    end;

    local procedure TestPatchDefaultDimensionFailsWhenChangingDimensionCode(TableNo: Integer; ParentNo: Code[20]; ParentId: Guid)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Dimension2: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        TargetURL: Text;
        DefaultDimensionJSON: Text;
        Response: Text;
        SubpageWithIdTxt: Text;
        ParentIdAsText: Text;
        DimensionId: Text;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DefaultDimension.Validate("Table ID", TableNo);
        DefaultDimension.Validate("No.", ParentNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Insert(true);

        ParentIdAsText := LowerCase(TypeHelper.GetGuidAsString(ParentId));
        DimensionId := LowerCase(TypeHelper.GetGuidAsString(Dimension.Id));
        Commit();

        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            ParentId, GetEntityPageNo(TableNo), GetServiceName(TableNo), DefaultDimensionsServiceNameTxt);
        SubpageWithIdTxt := DefaultDimensionsServiceNameTxt + StrSubstNo('(%1,%2)', ParentIdAsText, DimensionId);
        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, DefaultDimensionsServiceNameTxt, SubpageWithIdTxt);
        DefaultDimensionJSON := CreateDefaultDimensionRequestBody('', '', Dimension2.Code, '', '', '');

        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, DefaultDimensionJSON, Response);
    end;

    local procedure CreateDefaultDimensionRequestBody(ParentId: Text; DimensionId: Text; DimensionCode: Text; DimensionValueId: Text; DimensionValueCode: Text; ValuePosting: Text): Text
    var
        JsonMgt: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JsonMgt.InitializeEmptyObject;
        JsonMgt.GetJSONObject(JsonObject);
        if ParentId <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'parentId', ParentId);
        if DimensionId <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'dimensionId', DimensionId);
        if DimensionCode <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'dimensionCode', DimensionCode);
        if DimensionValueId <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'dimensionValueId', DimensionValueId);
        if DimensionValueCode <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'dimensionValueCode', DimensionValueCode);
        if ValuePosting <> '' then
            JsonMgt.AddJPropertyToJObject(JsonObject, 'postingValidation', ValuePosting);
        exit(JsonMgt.WriteObjectToString)
    end;

    local procedure VerifyDefaultDimensionResponseBody(Response: Text; ParentId: Text; DimensionId: Text; DimensionCode: Text; DimensionValueId: Text; DimensionValueCode: Text; ValuePosting: Text)
    var
        JsonMgt: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        Assert.AreNotEqual('', Response, EmptyResponseErr);
        JsonMgt.InitializeObject(Response);
        JsonMgt.GetJSONObject(JsonObject);
        if ParentId <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'parentId', ParentId);
        if DimensionId <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'dimensionId', DimensionId);
        if DimensionCode <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'dimensionCode', DimensionCode);
        if DimensionValueId <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'dimensionValueId', DimensionValueId);
        if DimensionValueCode <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'dimensionValueCode', DimensionValueCode);
        if ValuePosting <> '' then
            LibraryGraphMgt.AssertPropertyInJsonObject(JsonObject, 'postingValidation', ValuePosting);
    end;

    local procedure GetEntityPageNo(TableNo: Integer): Integer
    begin
        case TableNo of
            DATABASE::Customer:
                exit(PAGE::"Customer Entity");
            DATABASE::Vendor:
                exit(PAGE::"Vendor Entity");
            DATABASE::Item:
                exit(PAGE::"Item Entity");
            DATABASE::Employee:
                exit(PAGE::"Employee Entity");
        end;
        exit(-1);
    end;

    local procedure GetServiceName(TableNo: Integer): Text
    begin
        case TableNo of
            DATABASE::Customer:
                exit(CustomerServiceNameTxt);
            DATABASE::Vendor:
                exit(VendorServiceNameTxt);
            DATABASE::Item:
                exit(ItemServiceNameTxt);
            DATABASE::Employee:
                exit(EmployeeServiceNameTxt);
        end;
        exit('');
    end;
}

