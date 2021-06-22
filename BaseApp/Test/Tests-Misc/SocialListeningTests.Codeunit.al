codeunit 135010 "Social Listening Tests"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Social Listening Setup" = md;
    Subtype = Test;
    TestPermissions = NonRestrictive;
    ObsoleteState = Pending;
    ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        // [FEATURE] [Social Listening]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        SetupIsRequiredTxt: Label 'Setup is required';
        LibraryJobQueue: Codeunit "Library - Job Queue";

    [Scope('OnPrem')]
    procedure TestSocialListeningSingleton()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        BindSubscription(LibraryJobQueue);
        with SocialListeningSetup do begin
            // Setup
            DeleteAll();

            // Exercise
            CODEUNIT.Run(CODEUNIT::"Company-Initialize");

            // Verify
            Assert.IsTrue(Get, '');
            Assert.IsTrue("Terms of Use URL" <> '', '');
            Assert.IsTrue("Signup URL" <> '', '');
            Assert.IsFalse("Accept License Agreement", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningSetupSolutionID()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", '');
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);

            Validate("Show on Items", true);
            Validate("Show on Customers", true);
            Validate("Show on Vendors", true);

            // Exercise
            Validate("Social Listening URL", '');

            // Verify
            Assert.IsFalse("Show on Items", '');
            Assert.IsFalse("Show on Customers", '');
            Assert.IsFalse("Show on Vendors", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningSetupURLSolutionID()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", '');
            Validate("Accept License Agreement", true);

            // Exercise
            Validate("Social Listening URL", GetSocialListeningURL);

            // Verify
            // Assert.AreEqual(FORMAT(GoodSolutionID),"social listening url",'');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningSetupBadURLSolutionID()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningMgt: Codeunit "Social Listening Management";
        GoodSolutionID: Integer;
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", '');
            Validate("Accept License Agreement", true);

            // Exercise & Verify
            GoodSolutionID := 12345;
            asserterror Validate("Social Listening URL", StrSubstNo('%1/%2', SocialListeningMgt.GetMSL_URL, GoodSolutionID));
            asserterror Validate("Social Listening URL", StrSubstNo('%1/app/bad%2', SocialListeningMgt.GetMSL_URL, GoodSolutionID));
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningAcceptLicenseAgreement()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", '');
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);

            Validate("Show on Items", true);
            Validate("Show on Customers", true);
            Validate("Show on Vendors", true);

            // Exercise
            Validate("Accept License Agreement", false);

            // Verify
            Assert.IsFalse("Show on Items", '');
            Assert.IsFalse("Show on Customers", '');
            Assert.IsFalse("Show on Vendors", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningShowWithoutLicenseAgreement()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Accept License Agreement", false);

            // Exercise and Verify
            asserterror Validate("Show on Items", true);
            asserterror Validate("Show on Customers", true);
            asserterror Validate("Show on Vendors", true);
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningShowWithoutSocialListeningURL()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            // Setup
            Get;
            Validate("Social Listening URL", '');
            Validate("Accept License Agreement", true);

            // Exercise and Verify
            asserterror Validate("Show on Items", true);
            asserterror Validate("Show on Customers", true);
            asserterror Validate("Show on Vendors", true);
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningTopicURLSolutionID()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        Cust: Record Customer;
        SocialListeningMgt: Codeunit "Social Listening Management";
        GoodSolutionID: Integer;
    begin
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Customers", true);
            Modify(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        with SocialListeningSearchTopic do begin
            Validate("Source Type", "Source Type"::Customer);
            Validate("Source No.", Cust."No.");
            GoodSolutionID := LibraryRandom.RandInt(10000);
            Validate("Search Topic", StrSubstNo('%1?&nodeid=%2', SocialListeningMgt.GetMSL_URL, GoodSolutionID));

            Assert.AreEqual(Format(GoodSolutionID), "Search Topic", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestSocialListeningTopicBadURLSolutionID()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        Cust: Record Customer;
        SocialListeningMgt: Codeunit "Social Listening Management";
        GoodSolutionID: Integer;
    begin
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Customers", true);
            Modify(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        with SocialListeningSearchTopic do begin
            Validate("Source Type", "Source Type"::Customer);
            Validate("Source No.", Cust."No.");

            // Exercise & Verify
            GoodSolutionID := LibraryRandom.RandInt(10000);
            asserterror Validate("Search Topic", StrSubstNo('%1/%2', SocialListeningMgt.GetMSL_URL, GoodSolutionID));
            asserterror Validate("Search Topic", StrSubstNo('%1?&nodeid=bad%2', SocialListeningMgt.GetMSL_URL, GoodSolutionID));
        end;
    end;

    [HandlerFunctions('AddSocialListeningTopicHandler')]
    [Scope('OnPrem')]
    procedure TestSocialListeningTopicFactboxAccessCustAdd()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        Cust: Record Customer;
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        CustList: TestPage "Customer List";
    begin
        // Setup
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Customers", true);
            Modify(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        CustList.OpenView;
        CustList.GotoRecord(Cust);

        // Exercise
        CustList.Control33.InfoText.DrillDown;

        // Verify
        with SocialListeningSearchTopic do begin
            FindSearchTopic("Source Type"::Customer, Cust."No.");
            Assert.IsFalse(IsEmpty, '');
            CustList.Control33.InfoText.AssertEquals("Search Topic");

            Cust.Delete(true);
            Assert.IsTrue(IsEmpty, '');
        end;
    end;

    [HandlerFunctions('AddSocialListeningTopicHandler')]
    [Scope('OnPrem')]
    procedure TestSocialListeningTopicFactboxAccessVendAdd()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        Vend: Record Vendor;
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        VendList: TestPage "Vendor List";
    begin
        // Setup
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Customers", true);
            Modify(true);
        end;

        LibraryPurch.CreateVendor(Vend);
        VendList.OpenView;
        VendList.GotoRecord(Vend);

        // Exercise
        VendList.Control15.InfoText.DrillDown;

        // Verify
        with SocialListeningSearchTopic do begin
            FindSearchTopic("Source Type"::Vendor, Vend."No.");
            Assert.IsFalse(IsEmpty, '');
            VendList.Control15.InfoText.AssertEquals("Search Topic");

            Vend.Delete(true);
            Assert.IsTrue(IsEmpty, '');
        end;
    end;

    [HandlerFunctions('AddSocialListeningTopicHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestSocialListeningTopicFactboxAccessItemAdd()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        Item: Record Item;
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        ItemList: TestPage "Item List";
    begin
        // Setup
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Items", true);
            Modify(true);
        end;

        LibraryInventory.CreateItem(Item);
        ItemList.OpenView;
        ItemList.GotoRecord(Item);

        // Exercise
        ItemList.Control26.InfoText.DrillDown;

        // Verify
        with SocialListeningSearchTopic do begin
            FindSearchTopic("Source Type"::Item, Item."No.");
            Assert.IsFalse(IsEmpty, '');
            ItemList.Control26.InfoText.AssertEquals("Search Topic");

            Item.Delete(true);
            Assert.IsTrue(IsEmpty, '');
        end;
    end;

    [HandlerFunctions('RemoveSocialListeningTopicHandler')]
    [Scope('OnPrem')]
    procedure TestSocialListeningTopicFactboxAccessRemove()
    var
        SocialListeningSetup: Record "Social Listening Setup";
        Cust: Record Customer;
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        CustList: TestPage "Customer List";
    begin
        // Setup
        with SocialListeningSetup do begin
            Get;
            Validate("Accept License Agreement", false);
            Validate("Accept License Agreement", true);
            Validate("Social Listening URL", GetSocialListeningURL);
            Validate("Show on Customers", true);
            Modify(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        with SocialListeningSearchTopic do begin
            Validate("Source Type", "Source Type"::Customer);
            Validate("Source No.", Cust."No.");
            Validate("Search Topic", Format(LibraryRandom.RandInt(10000)));
            Insert(true);
        end;

        CustList.OpenView;
        CustList.GotoRecord(Cust);

        // Exercise
        CustList.Control33.InfoText.DrillDown;

        // Verify
        CustList.Control33.InfoText.AssertEquals(SetupIsRequiredTxt);

        Assert.IsFalse(SocialListeningSearchTopic.Find, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddSocialListeningTopicHandler(var SocialListeningSearchTopic: TestPage "Social Listening Search Topic")
    begin
        SocialListeningSearchTopic."Search Topic".SetValue(LibraryRandom.RandInt(10000));
        SocialListeningSearchTopic.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RemoveSocialListeningTopicHandler(var SocialListeningSearchTopic: TestPage "Social Listening Search Topic")
    begin
        SocialListeningSearchTopic."Search Topic".SetValue('');
        SocialListeningSearchTopic.OK.Invoke;
    end;

    local procedure GetSocialListeningURL(): Text[250]
    begin
        exit(StrSubstNo('%1/app/%2', 'https://wwww.dummysociallisteningsite.com', LibraryRandom.RandInt(10000)));
    end;
}

