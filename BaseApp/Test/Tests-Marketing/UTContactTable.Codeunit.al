codeunit 134826 "UT Contact Table"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsMobileForClientPhone()
    var
        Contact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [CLIENTTYPE::Phone]
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] Client is "Phone"
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = 'Y'
        Contact.Init;
        Contact."Phone No." := '111111';
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Mobile Phone No.", Contact.GetDefaultPhoneNo, 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'Y'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsMobileIfPhoneBlankForClientWindows()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] Contact, where "Phone No." = <blank>, "Mobile Phone No." = 'Y'
        Contact.Init;
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Mobile Phone No.", Contact.GetDefaultPhoneNo, 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'Y'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsPhoneForClientWindows()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = 'Y'
        Contact.Init;
        Contact."Phone No." := '111111';
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Phone No.", Contact.GetDefaultPhoneNo, 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'X'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsPhoneIfMobileBalnkForClientPhone()
    var
        Contact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [CLIENTTYPE::Phone]
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] Client is "Phone"
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = <blank>
        Contact.Init;
        Contact."Phone No." := '111111';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Phone No.", Contact.GetDefaultPhoneNo, 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'X'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsBlankIfNoneNumbersFilled()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] Contact, where both "Phone No." and "Mobile Phone No." are <blank>
        Contact.Init;
        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual('', Contact.GetDefaultPhoneNo, 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns ''
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewContactPersonTypeWithCompanyNoInRMCONTPermissions()
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
    begin
        // [SCENARIO 379620] User with "RM-CONT, Edit" permissions can set "Company No." field
        LibraryLowerPermissions.SetO365Basic;
        LibraryLowerPermissions.AddRMContEdit;

        CompanyContact.Init;
        CompanyContact.Insert(true);
        CompanyContact.Validate(Type, Contact.Type::Company);
        CompanyContact.Modify(true);

        Contact.Init;
        Contact.Insert(true);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteContactTypePerson()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 197375] Stan can delete Contact with Type = Person under "D365 Customer, EDIT" permission set
        LibraryLowerPermissions.SetO365Basic;
        LibraryLowerPermissions.AddRMContEdit;

        MockContact(Contact, Contact.Type::Person);

        LibraryLowerPermissions.SetCustomerEdit;

        Contact.Delete(true);
        VerifyContactRelatedRecordsDeleted(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteContactTypeCompany()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 197375] Stan can delete Contact with Type = Company under "D365 Customer, EDIT" permission set
        LibraryLowerPermissions.SetO365Basic;
        LibraryLowerPermissions.AddRMContEdit;

        MockContact(Contact, Contact.Type::Company);

        LibraryLowerPermissions.SetCustomerEdit;

        Contact.Delete(true);
        VerifyContactRelatedRecordsDeleted(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteCustNameWhenCreateCustFromContact()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 275793] Customer Name is set for Sales Quote, when Stan creates Customer from Contact.

        // [GIVEN] Sales Quote with Sell-to Contact and Bill-to Contact.
        MockContact(Contact, Contact.Type::Person);
        MockSalesQuoteWithSellBillToContactNo(SalesHeader, Contact."No.");

        // [WHEN] Create Customer from that Contact.
        LibraryMarketing.CreateCustomerFromContact(Customer, Contact);

        // [THEN] Customer Name is set for Sales Quote.
        SalesHeader.Find;
        SalesHeader.TestField("Sell-to Customer Name", Customer.Name);
        SalesHeader.TestField("Bill-to Name", Customer.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerUpdateContactWhenContactNameIsBlank()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 275658] Contact automatically created from Customer gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Customer record created with blank fields
        Customer.Init;
        Customer.Insert(true);

        // [GIVEN] Contact with blank Name created for Customer automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Customer, Customer."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Customer Name to 'AAA'
        Customer.Name := LibraryUtility.GenerateGUID;
        Customer.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find;
        Contact.TestField(Name, Customer.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 275658] Contact automatically created from Customer gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Customer record with name 'AAA' created
        Customer.Init;
        Customer.Name := LibraryUtility.GenerateGUID;
        Customer.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Customer
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Customer, Customer."No."));
        Contact.TestField(Name, Customer.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID;
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Customer Priority is set to 11 and Customer record is modified
        Customer.Validate(Priority, LibraryRandom.RandInt(10));
        Customer.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find;
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorUpdateContactWhenContactNameIsBlank()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 275658] Contact automatically created from Vendor gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Vendor record created with blank fields
        Vendor.Init;
        Vendor.Insert(true);

        // [GIVEN] Contact with blank Name created for Vendor automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Vendor, Vendor."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Vendor Name to 'AAA'
        Vendor.Name := LibraryUtility.GenerateGUID;
        Vendor.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find;
        Contact.TestField(Name, Vendor.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 275658] Contact automatically created from Vendor gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Vendor record with name 'AAA' created
        Vendor.Init;
        Vendor.Name := LibraryUtility.GenerateGUID;
        Vendor.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Vendor
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Vendor, Vendor."No."));
        Contact.TestField(Name, Vendor.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID;
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Vendor Priority is set to 11 and Vendor record is modified
        Vendor.Validate(Priority, LibraryRandom.RandInt(10));
        Vendor.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find;
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccUpdateContactWhenContactNameIsBlank()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 275658] Contact automatically created from Vendor gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Bank Account record created with blank fields
        BankAccount.Init;
        BankAccount.IBAN := LibraryUtility.GenerateGUID;
        BankAccount.Insert(true);

        // [GIVEN] Contact with blank Name created for Bank Account automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::"Bank Account", BankAccount."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Bank Account Name to 'AAA'
        BankAccount.Name := LibraryUtility.GenerateGUID;
        BankAccount.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find;
        Contact.TestField(Name, BankAccount.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 275658] Contact automatically created from Bank Account gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Bank Account record with name 'AAA' created
        BankAccount.Init;
        BankAccount.IBAN := LibraryUtility.GenerateGUID;
        BankAccount.Name := LibraryUtility.GenerateGUID;
        BankAccount.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Bank Account
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::"Bank Account", BankAccount."No."));
        Contact.TestField(Name, BankAccount.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID;
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Bank Account "Bank Branch No." is changed and Bank Account record is modified
        BankAccount.Validate("Bank Branch No.", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find;
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeHelper_GetHMS_ZeroTime()
    var
        TypeHelper : Codeunit "Type Helper";
        TimeSource : Time;
        Hour : Integer;
        Minute : Integer;
        Second : Integer;
    begin
        // [FEATURE] [Time Zone]
        TimeSource := 000000T;
        TypeHelper.GetHMSFromTime(Hour,Minute,Second,TimeSource);
  
        Assert.AreEqual(0,Hour,'Hour');
        Assert.AreEqual(0,Minute,'Minute');
        Assert.AreEqual(0,Second,'Second');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeHelper_GetHMS_NonZeroTime()
    var
        TypeHelper : Codeunit "Type Helper";
        TimeSource : Time;
        Hour : Integer;
        Minute : Integer;
        Second : Integer;
    begin
        // [FEATURE] [Time Zone]
        TimeSource := 235521T;
        TypeHelper.GetHMSFromTime(Hour,Minute,Second,TimeSource);
  
        Assert.AreEqual(23,Hour,'Hour');
        Assert.AreEqual(55,Minute,'Minute');
        Assert.AreEqual(21,Second,'Second');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_01()
    var
        Contact : Record "Contact";
        ExpectedDateTime : DateTime;
    begin
        // [FEATURE] [Time Zone]
        Assert.AreEqual(0DT,Contact.GetLastDateTimeModified,'');
  
        ExpectedDateTime := CurrentDateTime;
        Contact.SetLastDateTimeModified;
  
        Assert.AreEqual(ExpectedDateTime,Contact.GetLastDateTimeModified,'');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_02()
    var
        Contact : Record "Contact";
        DotNet_DateTimeOffset : Codeunit "DotNet_DateTimeOffset";
        ExpectedDateTime : DateTime;
        LocalTimeZoneOffset : Duration;
    begin
        // [FEATURE] [Time Zone]
        Contact."Last Date Modified" := DT2Date(CurrentDateTime);
        Contact."Last Time Modified" := 000000T;
  
        LocalTimeZoneOffset := DotNet_DateTimeOffset.GetOffset;
  
        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified",Contact."Last Time Modified") + LocalTimeZoneOffset;
        Assert.AreEqual(ExpectedDateTime,Contact.GetLastDateTimeModified,'');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCard_LastDateTimeModified()
    var
        Contact : Record "Contact";
        DotNet_DateTimeOffset : Codeunit "DotNet_DateTimeOffset";
        ContactCard : TestPage "Contact Card";
        ExpectedDateTime : DateTime;
        LocalTimeZoneOffset : Duration;
    begin
        // [FEATURE] [Time Zone] [UI]
        Contact.Init;
        Contact."No." := LibraryUtility.GenerateGUID;
        Contact."Last Date Modified" := DT2Date(CurrentDateTime);
        Contact."Last Time Modified" := 000000T;
        Contact.Insert;
  
        LocalTimeZoneOffset := DotNet_DateTimeOffset.GetOffset;
        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified",Contact."Last Time Modified") + LocalTimeZoneOffset;
  
        ContactCard.OpenView;
        ContactCard.Filter.SetFilter("No.",Contact."No.");
        ContactCard.LastDateTimeModified.AssertEquals(ExpectedDateTime);
    end;

    local procedure GetContactNoFromContBusRelations(LinkOption: Option; CodeNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkOption);
        ContactBusinessRelation.SetRange("No.", CodeNo);
        ContactBusinessRelation.FindFirst;
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure MockContact(var Contact: Record Contact; ContactType: Option)
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Contact.Init;
        Contact.Insert(true);
        Contact.Validate(Type, ContactType);
        Contact.Validate(
          Name, CopyStr(LibraryUtility.GenerateRandomText(20), 1, MaxStrLen(Contact.Name)));
        Contact.Modify(true);

        ContactMailingGroup.Init;
        ContactMailingGroup."Contact No." := Contact."No.";
        ContactMailingGroup.Insert(true);

        RlshpMgtCommentLine.Init;
        RlshpMgtCommentLine."Table Name" := RlshpMgtCommentLine."Table Name"::Contact;
        RlshpMgtCommentLine."No." := Contact."No.";
        RlshpMgtCommentLine.Insert(true);

        ContactAltAddress.Init;
        ContactAltAddress."Contact No." := Contact."No.";
        ContactAltAddress.Insert(true);

        ContactAltAddrDateRange.Init;
        ContactAltAddrDateRange."Contact No." := Contact."No.";
        ContactAltAddrDateRange.Insert(true);

        ContactBusinessRelation.Init;
        ContactBusinessRelation."Contact No." := Contact."No.";
        ContactBusinessRelation.Insert(true);
    end;

    local procedure MockSalesQuoteWithSellBillToContactNo(var SalesHeader: Record "Sales Header"; ContactNo: Code[20])
    begin
        SalesHeader.Init;
        SalesHeader."No." := LibraryUtility.GenerateGUID;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader."Sell-to Contact No." := ContactNo;
        SalesHeader."Bill-to Contact No." := ContactNo;
        SalesHeader.Insert;
    end;

    local procedure VerifyContactRelatedRecordsDeleted(ContactNo: Code[20])
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactMailingGroup.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactMailingGroup);

        RlshpMgtCommentLine.SetRange("No.", ContactNo);
        Assert.RecordIsEmpty(RlshpMgtCommentLine);

        ContactAltAddress.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactAltAddress);

        ContactAltAddrDateRange.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactAltAddrDateRange);

        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;
}

