codeunit 134233 "ERM Base Calendar"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Base Calendar]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustomer()
    var
        Customer: Record Customer;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 271255] The customized calendar data related with the customer is deleted when the source customer is deleted
        // [GIVEN] The customer "C", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateCustomerWithCustomizedCalendar(Customer);

        // [WHEN] The customer "C" is deleted
        Customer.Delete(true);

        // [THEN] The customized calendar data related with the customer "C" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendor()
    var
        Vendor: Record Vendor;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 271255] The customized calendar data related with the vendor is deleted when the source vendor is deleted
        // [GIVEN] The vendor "V", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateVendorWithCustomizedCalendar(Vendor);

        // [WHEN] The vendor "V" is deleted
        Vendor.Delete(true);

        // [THEN] The customized calendar data related with the vendor "V" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLocation()
    var
        Location: Record Location;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Location]
        // [SCENARIO 271255] The customized calendar data related with the location is deleted when the source location is deleted
        // [GIVEN] The location "L", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateLocationWithCustomizedCalendar(Location);

        // [WHEN] The location "L" is deleted
        Location.Delete(true);

        // [THEN] The customized calendar data related with the location "L" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Location, Location.Code, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteShippingAgent()
    var
        ShippingAgent: Record "Shipping Agent";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO 271255] The customized calendar data related with the shipping agent is deleted when the source shipping agent is deleted
        // [GIVEN] The shipping agent "SA", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateShippingAgentWithCustomizedCalendar(ShippingAgent);

        // [WHEN] The shipping agent "SA" is deleted
        ShippingAgent.Delete(true);

        // [THEN] The customized calendar data related with the shipping agent "SA" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameCustomer()
    var
        Customer: Record Customer;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 271255] The customized calendar data related with the customer is accordingly renamed when the source customer is renamed
        // [GIVEN] The customer "C", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateCustomerWithCustomizedCalendar(Customer);

        // [WHEN] The customer "C" is renamed
        Customer.Rename(LibraryUtility.GenerateRandomCode20(Customer.FieldNo("No."), DATABASE::Customer));

        // [THEN] The customized calendar data related with the customer "C" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameVendor()
    var
        Vendor: Record Vendor;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 271255] The customized calendar data related with the vendor is accordingly renamed when the source vendor is renamed
        // [GIVEN] The vendor "V", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateVendorWithCustomizedCalendar(Vendor);

        // [WHEN] The vendor "V" is renamed
        Vendor.Rename(LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), DATABASE::Vendor));

        // [THEN] The customized calendar data related with the vendor "V" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameLocation()
    var
        Location: Record Location;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Location]
        // [SCENARIO 271255] The customized calendar data related with the location is accordingly renamed when the source location is renamed
        // [GIVEN] The location "L", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateLocationWithCustomizedCalendar(Location);

        // [WHEN] The location "L" is renamed
        Location.Rename(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location));

        // [THEN] The customized calendar data related with the location "L" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Location, Location.Code, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameShippingAgent()
    var
        ShippingAgent: Record "Shipping Agent";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO 271255] The customized calendar data related with the shipping agent is accordingly renamed when the source shipping agent is renamed
        // [GIVEN] The shipping agent "SA", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateShippingAgentWithCustomizedCalendar(ShippingAgent);

        // [WHEN] The shipping agent "SA" is renamed
        ShippingAgent.Rename(LibraryUtility.GenerateRandomCode(ShippingAgent.FieldNo(Code), DATABASE::"Shipping Agent"));

        // [THEN] The customized calendar data related with the shipment agent "SA" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseCalendarCardUpdatesCodeOnSubformOnValidate()
    var
        BaseCalendarChange: Record "Base Calendar Change";
        BaseCalendarCard: TestPage "Base Calendar Card";
        NewDescription: text[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 292658] Base Calendar Card updates CalendarCode on subform when it's changed on the page

        // [GIVEN] Base Calendar Card is open
        BaseCalendarCard.OpenNew;

        // [GIVEN] Enter Calendar Code
        BaseCalendarCard.Code.SetValue(LibraryUtility.GenerateGUID);

        // [WHEN] Set any entry as non-working
        BaseCalendarCard.BaseCalendarEntries.Nonworking.SetValue(true);

        // [THEN] A record in Base Calendar Change with correct Calendar Code is inserted
        BaseCalendarChange.SetRange("Base Calendar Code", BaseCalendarCard.Code.Value);
        BaseCalendarChange.SetRange(Date, BaseCalendarCard.BaseCalendarEntries."Period Start".AsDate());
        Assert.RecordIsNotEmpty(BaseCalendarChange);

        // [GIVEN] Add Description as 'X' to the same row
        NewDescription := LibraryUtility.GenerateGUID;
        BaseCalendarCard.BaseCalendarEntries.Description.SetValue(NewDescription);

        // [WHEN] Move the cursor to the previous row and back   
        BaseCalendarCard.BaseCalendarEntries.Previous();
        BaseCalendarCard.BaseCalendarEntries.Next();
        // [THEN] Nonworking is 'Yes', Dewscription is 'X' in the row.
        BaseCalendarCard.BaseCalendarEntries.Nonworking.AssertEquals(Format(true));
        BaseCalendarCard.BaseCalendarEntries.Description.AssertEquals(NewDescription);
        // [THEN] the record in Base Calendar Change, where Nonworking is 'Yes', Dewscription is 'X'
        BaseCalendarChange.SetRange("Base Calendar Code", BaseCalendarCard.Code.Value);
        BaseCalendarChange.SetRange(Date, BaseCalendarCard.BaseCalendarEntries."Period Start".AsDate());
        BaseCalendarChange.FindFirst();
        BaseCalendarChange.TestField(Description, NewDescription);
        BaseCalendarChange.TestField(Nonworking, true);
    end;

    local procedure CreateCustomerWithCustomizedCalendar(var Customer: Record Customer): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Base Calendar Code", BaseCalendar.Code);
        Customer.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", '',
          WorkDate, false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Customer, Customer."No.",
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateVendorWithCustomizedCalendar(var Vendor: Record Vendor): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Base Calendar Code", BaseCalendar.Code);
        Vendor.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", '',
          WorkDate, false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Vendor, Vendor."No.",
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateLocationWithCustomizedCalendar(var Location: Record Location): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryWarehouse.CreateLocation(Location);
        LibraryService.CreateBaseCalendar(BaseCalendar);
        Location.Validate("Base Calendar Code", BaseCalendar.Code);
        Location.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Location, Location.Code, '',
          WorkDate, false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Location, Location.Code,
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateShippingAgentWithCustomizedCalendar(var ShippingAgent: Record "Shipping Agent"): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        ShippingAgentServices: Record "Shipping Agent Services";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
        DateFormula: DateFormula;
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(DateFormula, '<1D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, '',
          WorkDate, false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::"Shipping Agent", ShippingAgent.Code,
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        ShippingAgentServices.Validate("Base Calendar Code", BaseCalendar.Code);
        ShippingAgentServices.Modify(true);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateCustomizedCalendarChange(var CustomizedCalendarChange: Record "Customized Calendar Change"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[10]; NewDate: Date; IsNonworking: Boolean)
    begin
        Clear(CustomizedCalendarChange);
        with CustomizedCalendarChange do begin
            Validate("Source Type", SourceType);
            Validate("Source Code", SourceCode);
            Validate("Additional Source Code", AdditionalSourceCode);
            Validate("Base Calendar Code", BaseCalendarCode);
            Validate(Date, NewDate);
            Validate(Nonworking, IsNonworking);
            Insert(true);
        end;
    end;

    local procedure CreateCustomizedCalendarEntry(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; NewDescription: Text[30]; IsNonworking: Boolean)
    begin
        Clear(CustomizedCalendarEntry);
        with CustomizedCalendarEntry do begin
            Validate("Source Type", SourceType);
            Validate("Source Code", SourceCode);
            Validate("Additional Source Code", '');
            Validate("Base Calendar Code", BaseCalendarCode);
            Validate(Date, WorkDate);
            Validate(Description, NewDescription);
            Validate(Nonworking, IsNonworking);
            Insert(true);
        end;
    end;

    local procedure FilterCustomizedCalendarChange(var CustomizedCalendarChange: Record "Customized Calendar Change"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[20]; DatePar: Date)
    begin
        with CustomizedCalendarChange do begin
            SetRange("Source Type", SourceType);
            SetRange("Source Code", SourceCode);
            SetRange("Additional Source Code", AdditionalSourceCode);
            SetRange("Base Calendar Code", BaseCalendarCode);
            SetRange(Date, DatePar);
        end;
    end;

    local procedure FilterCustomizedCalendarEntry(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[20]; DatePar: Date)
    begin
        with CustomizedCalendarEntry do begin
            SetRange("Source Type", SourceType);
            SetRange("Source Code", SourceCode);
            SetRange("Additional Source Code", AdditionalSourceCode);
            SetRange("Base Calendar Code", BaseCalendarCode);
            SetRange(Date, DatePar);
        end;
    end;

    local procedure FilterWhereUsedBaseCalendar(var WhereUsedBaseCalendar: Record "Where Used Base Calendar"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20])
    begin
        with WhereUsedBaseCalendar do begin
            SetRange("Source Type", SourceType);
            SetRange("Source Code", SourceCode);
            SetRange("Base Calendar Code", BaseCalendarCode);
        end;
    end;

    local procedure VerifyEmptyCalendarData(BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceNo: Code[20]; Date: Date)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        FilterCustomizedCalendarChange(CustomizedCalendarChange, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsEmpty(CustomizedCalendarChange);
        FilterCustomizedCalendarEntry(CustomizedCalendarEntry, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsEmpty(CustomizedCalendarEntry);
        FilterWhereUsedBaseCalendar(WhereUsedBaseCalendar, BaseCalendarCode, SourceType, SourceNo);
        Assert.RecordIsEmpty(WhereUsedBaseCalendar);
    end;

    local procedure VerifyUnemptyCalendarData(BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceNo: Code[20]; Date: Date)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        FilterCustomizedCalendarChange(CustomizedCalendarChange, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsNotEmpty(CustomizedCalendarChange);
        FilterCustomizedCalendarEntry(CustomizedCalendarEntry, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsNotEmpty(CustomizedCalendarEntry);
        FilterWhereUsedBaseCalendar(WhereUsedBaseCalendar, BaseCalendarCode, SourceType, SourceNo);
        Assert.RecordIsNotEmpty(WhereUsedBaseCalendar);
    end;
}

