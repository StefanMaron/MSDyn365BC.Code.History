codeunit 133781 "Booking Customer Sync Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bookings] [Sync] [Customers]
        LibraryO365Sync.SetupNavUser;
    end;

    var
        BookingSync: Record "Booking Sync";
        Contact: Record Contact;
        ExchangeContact: Record "Exchange Contact";
        ExchangeSync: Record "Exchange Sync";
        Assert: Codeunit Assert;
        LibraryO365Sync: Codeunit "Library - O365 Sync";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        navCustomerEmailTxt: Label 'navcustomer@email.com';
        navCompanyEmailTxt: Label 'navcompany@email.com';
        bookingsContactEmailTxt: Label 'bookingscontact@email.com';
        updateNavFromBookingsEmailTxt: Label 'updatenavcustomerfrombookings@email.com';
        updateBookingsFromNavEmailTxt: Label 'updatebookingsfromnav@email.com';
        bookingsUpdateFromNavEmailTxt: Label 'bookingsupdatefromnav@email.com';
        navUpdateFromBookingsEmailTxt: Label 'navupdatefrombookings@email.com';

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestCreateBookingsCustomerFromNav()
    begin
        // [SCENARIO] New customers in NAV are created in Bookings when the sync process runs.
        Initialize;

        DeleteExchangeContact(navCustomerEmailTxt);
        DeleteExchangeContact(navCompanyEmailTxt);

        Clear(ExchangeContact);

        // [GIVEN] A NAV Customer exists
        Contact."No." := '';
        Contact.Validate(Name, 'Nav Customer');
        Contact.Validate("E-Mail", navCustomerEmailTxt);
        Contact.Validate("Phone No.", '7011234567');
        Contact.Validate(Address, '2782 Customer Address');
        Contact.Validate(City, 'Customer City');
        SaveContactAndCreateCustomer(Contact);

        // [GIVEN] A NAV Company Contact Exists with a Customer
        Clear(Contact);
        Contact."No." := '';
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Validate(Name, 'Nav Company');
        Contact.Validate("E-Mail", navCompanyEmailTxt);
        Contact.Validate("Phone No.", '7013547864');
        Contact.Validate(Address, '7894 Company Address');
        Contact.Validate(City, 'Company City');
        Contact.Insert(true);
        Commit;

        // [WHEN] Bookings Customers are sync'd
        O365SyncManagement.SyncBookingCustomers(BookingSync);

        // [THEN] The NAV Customer is created as a Bookings Contact
        ExchangeContact.SetFilter(EMailAddress1, navCustomerEmailTxt);
        if not ExchangeContact.FindFirst then
            Assert.Fail(StrSubstNo('%1 not found', navCustomerEmailTxt));

        // [THEN] The NAV Company Contact is not created as a Bookings Contact
        ExchangeContact.SetFilter(EMailAddress1, navCompanyEmailTxt);
        if ExchangeContact.FindFirst then
            Assert.Fail(StrSubstNo('%1 should not have been created', navCompanyEmailTxt));
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestCreateNavCustomerFromBookings()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [SCENARIO] New customers in Bookings are created in NAV when the sync process runs.
        Initialize;

        DeleteExchangeContact(bookingsContactEmailTxt);

        // [GIVEN] A Bookings Contact exists
        ExchangeContact.Validate(EMailAddress1, bookingsContactEmailTxt);
        ExchangeContact.Validate(GivenName, 'Bookings');
        ExchangeContact.Validate(Surname, 'Contact');
        ExchangeContact.Insert;

        // [WHEN] Bookings Customers are sync'd
        O365SyncManagement.SyncBookingCustomers(BookingSync);

        // [THEN] A NAV Contact is created as Type Company
        Contact.SetFilter("E-Mail", bookingsContactEmailTxt);
        if Contact.FindFirst then
            Assert.AreEqual(Contact.Type::Company, Contact.Type, 'Contact was not created as a Company');

        // [THEN] A NAV Customer is created from the Company Contact
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetFilter("Contact No.", Contact."No.");
        if ContactBusinessRelation.FindFirst then begin
            Customer.SetFilter("No.", ContactBusinessRelation."No.");
            if not Customer.FindFirst then
                Assert.Fail('Bookings Customer was not created');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateNavCustomerFromBookings()
    begin
        // [SCENARIO] Modified customers in Bookings get updated in NAV when the sync process runs.
        Initialize;

        DeleteExchangeContact(updateNavFromBookingsEmailTxt);

        Clear(ExchangeContact);

        // [GIVEN] A Bookings Contact exists
        ExchangeContact.Validate(EMailAddress1, updateNavFromBookingsEmailTxt);
        ExchangeContact.Validate(GivenName, 'Update Nav From Bookings');
        ExchangeContact.Validate(BusinessPhone1, '5648789601');
        ExchangeContact.Validate(CompanyName, 'Update Nav From Bookings');
        ExchangeContact.Validate(Street, '1234 Company Address');
        ExchangeContact.Validate(City, 'Company City');
        ExchangeContact.Insert;

        // [GIVEN] A NAV Customer exists with the same information as the Bookings Contact
        Contact."No." := '';
        Contact.Validate(Name, 'Update Nav From Bookings');
        Contact.Validate("E-Mail", updateNavFromBookingsEmailTxt);
        Contact.Validate("Phone No.", '5648789601');
        Contact.Validate(Address, '1234 Company Address');
        Contact.Validate(City, 'Company City');
        SaveContactAndCreateCustomer(Contact);
        Clear(Contact);

        // [GIVEN] The Last Bookings Customer Sync was TODAY @NOW
        BookingSync.Validate("Last Customer Sync", CreateDateTime(Today, Time));
        BookingSync.Modify;

        // [GIVEN] The Bookings Contact phone number is update after the Last Bookings Customer Sync
        ExchangeContact.SetFilter(EMailAddress1, updateNavFromBookingsEmailTxt);
        if ExchangeContact.FindFirst then begin
            ExchangeContact.Validate(BusinessPhone1, '1234567890');
            ExchangeContact.Modify;
        end;

        // [WHEN] Bookings Customers are sync'd
        O365SyncManagement.SyncBookingCustomers(BookingSync);

        // [THEN] The NAV Customer Phone number is updated
        Contact.SetFilter("E-Mail", updateNavFromBookingsEmailTxt);
        Contact.FindFirst;
        Assert.AreEqual('1234567890', Contact."Phone No.", 'Nav Customer Phone Number not updated');
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateBookingsFromNavCustomer()
    begin
        // [SCENARIO] Modified customers in NAV get updated in Bookings when the sync process runs.
        Initialize;

        DeleteExchangeContact(updateBookingsFromNavEmailTxt);

        Clear(ExchangeContact);

        // [GIVEN] A NAV Customer exists
        Contact."No." := '';
        Contact.Validate(Name, 'Update Bookings From Nav');
        Contact.Validate("E-Mail", updateBookingsFromNavEmailTxt);
        Contact.Validate("Phone No.", '5648789601');
        Contact.Validate(Address, '1234 Company Address');
        Contact.Validate(City, 'Company City');
        SaveContactAndCreateCustomer(Contact);

        // [GIVEN] A Bookings Contact exists with the same information as the NAV Customer
        ExchangeContact.Validate(EMailAddress1, updateBookingsFromNavEmailTxt);
        ExchangeContact.Validate(GivenName, 'Update Bookings From Nav');
        ExchangeContact.Validate(BusinessPhone1, '5648789601');
        ExchangeContact.Validate(CompanyName, 'Update Bookings From Nav');
        ExchangeContact.Validate(Street, '1234 Company Address');
        ExchangeContact.Validate(City, 'Company City');
        ExchangeContact.Insert;

        // [GIVEN] The Last Bookings Customer Sync was Yesterday @NOW
        BookingSync.Validate("Last Customer Sync", CreateDateTime(Today - 1, Time));
        BookingSync.Modify;

        // [GIVEN] The NAV Customer phone number is update after the Last Bookings Customer Sync
        Contact.SetFilter("E-Mail", updateBookingsFromNavEmailTxt);
        if Contact.FindFirst then begin
            Contact.Validate("Phone No.", '1234567890');
            Contact.Modify(true);
        end;

        // [WHEN] Bookings Customers are sync'd
        O365SyncManagement.SyncBookingCustomers(BookingSync);

        // [THEN] The Bookings Contact Phone number is updated
        ExchangeContact.SetFilter(EMailAddress1, updateBookingsFromNavEmailTxt);
        ExchangeContact.FindFirst;
        Assert.AreEqual('1234567890', ExchangeContact.BusinessPhone1, 'Bookings Contact Phone Number not updated');
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateBothCustomers()
    begin
        // [SCENARIO] Changes made in both NAV and Bookings get reflected in both places.
        Initialize;

        DeleteExchangeContact(bookingsUpdateFromNavEmailTxt);
        DeleteExchangeContact(navUpdateFromBookingsEmailTxt);

        // [GIVEN] A Bookings Contact exists
        Clear(ExchangeContact);
        ExchangeContact.Validate(EMailAddress1, bookingsUpdateFromNavEmailTxt);
        ExchangeContact.Validate(GivenName, 'Bookings Update from Nav');
        ExchangeContact.Validate(BusinessPhone1, '1234567890');
        ExchangeContact.Validate(CompanyName, 'Bookings Update from Nav');
        ExchangeContact.Validate(Street, '7895 Avenue Address');
        ExchangeContact.Validate(City, 'Booking City');
        ExchangeContact.Insert;

        // [GIVEN] A NAV Customer Exists with the same information as the Bookings Contact
        Contact."No." := '';
        Contact.Validate(Name, 'Bookings Update from Nav');
        Contact.Validate("E-Mail", bookingsUpdateFromNavEmailTxt);
        Contact.Validate("Phone No.", '1234567890');
        Contact.Validate(Address, '7895 Avenue Address');
        Contact.Validate(City, 'Booking City');
        SaveContactAndCreateCustomer(Contact);

        // [GIVEN] NAV Customer Exists
        Clear(Contact);
        Contact."No." := '';
        Contact.Validate(Name, 'Nav Update from Bookings');
        Contact.Validate("E-Mail", navUpdateFromBookingsEmailTxt);
        Contact.Validate("Phone No.", '0987654321');
        Contact.Validate(Address, '1596 Street Address');
        Contact.Validate(City, 'Nav City');
        SaveContactAndCreateCustomer(Contact);

        // [GIVEN] A Bookings Contact exists with the same information as the NAV Customer
        Clear(ExchangeContact);
        ExchangeContact.Validate(EMailAddress1, navUpdateFromBookingsEmailTxt);
        ExchangeContact.Validate(GivenName, 'Nav Update from Bookings');
        ExchangeContact.Validate(BusinessPhone1, '0987654321');
        ExchangeContact.Validate(CompanyName, 'Nav Update from Bookings');
        ExchangeContact.Validate(Street, '1596 Street Address');
        ExchangeContact.Validate(City, 'Nav City');
        ExchangeContact.Insert;

        // [GIVEN] The Last Bookings Customer Sync was TODAY @NOW
        BookingSync.Validate("Last Customer Sync", CreateDateTime(Today, Time));
        BookingSync.Modify;

        // [GIVEN] A Bookings Contact phone number is updated
        ExchangeContact.SetFilter(EMailAddress1, navUpdateFromBookingsEmailTxt);
        if ExchangeContact.FindFirst then begin
            ExchangeContact.Validate(BusinessPhone1, '8418493120');
            ExchangeContact.Modify;
        end;

        // [GIVEN] A NAV Customer phone number is updated
        Contact.SetFilter("E-Mail", bookingsUpdateFromNavEmailTxt);
        if Contact.FindFirst then begin
            Contact.Validate("Phone No.", '5648789601');
            Contact.Modify(true);
        end;

        // [WHEN] Bookings Customers are sync'd
        O365SyncManagement.SyncBookingCustomers(BookingSync);

        // [THEN] The Bookings Contact phone number is updated from the NAV Customer
        ExchangeContact.SetFilter(EMailAddress1, bookingsUpdateFromNavEmailTxt);
        ExchangeContact.FindFirst;
        Assert.AreEqual('5648789601', ExchangeContact.BusinessPhone1, 'Bookings Contact Phone Number not updated');

        // [THEN] The NAV Customer phone number is updated from the Bookings Contact
        Contact.SetFilter("E-Mail", navUpdateFromBookingsEmailTxt);
        Contact.FindFirst;
        Assert.AreEqual('8418493120', Contact."Phone No.", 'Nav Customer Phone Number not updated');
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        LibraryO365Sync: Codeunit "Library - O365 Sync";
    begin
        LibraryO365Sync.SetupBookingsSync(BookingSync);
        LibraryO365Sync.SetupExchangeSync(ExchangeSync);

        Contact.DeleteAll;
        Customer.DeleteAll;

        O365SyncManagement.RegisterBookingsConnection(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure DeleteExchangeContact(EmailAddress: Text)
    var
        ExchangeContact: Record "Exchange Contact";
    begin
        ExchangeContact.SetFilter(EMailAddress1, EmailAddress);
        if ExchangeContact.FindFirst then
            ExchangeContact.Delete;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Scope('OnPrem')]
    procedure SaveContactAndCreateCustomer(var Contact: Record Contact)
    begin
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Insert(true);
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomer(BookingSync."Customer Template Code");
        Commit;
    end;
}

