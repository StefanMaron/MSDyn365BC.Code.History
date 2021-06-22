codeunit 138918 "O365 VAT Rates"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [VAT Posting Setup] [UI]
    end;

    var
        O365TemplateManagement: Codeunit "O365 Template Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        DefaultVATRateTxt: Label 'This is the default VAT Rate';
        SetDefaultVATRateTxt: Label 'Set as default VAT Rate';
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,VATPostingSetupCardHandler')]
    [Scope('OnPrem')]
    procedure OpenDefaultVATRate()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365VATPostingSetupList: TestPage "O365 VAT Posting Setup List";
    begin
        // [GIVEN] O365 VAT Posting Setups provided by demo tool
        LibraryLowerPermissions.SetInvoiceApp;
        VATProductPostingGroup.Get(O365TemplateManagement.GetDefaultVATProdPostingGroup);
        EnqueueVATRateFields(VATProductPostingGroup);
        LibraryVariableStorage.Enqueue(true); // Default VAT Rate

        // [WHEN] The user opens selected VAT Rate from Vat Rates list
        O365VATPostingSetupList.OpenEdit;
        O365VATPostingSetupList.GotoRecord(VATProductPostingGroup);
        O365VATPostingSetupList.Open.Invoke;

        // [THEN] VAT Rate page is open and VAT Rate, Description, VAT Reg. Reference and Default action is shown
        // Page handler verification
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,VATPostingSetupCardHandler')]
    [Scope('OnPrem')]
    procedure OpenNotDefaultVATRate()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365VATPostingSetupList: TestPage "O365 VAT Posting Setup List";
    begin
        // [GIVEN] O365 VAT Posting Setups provided by demo tool
        LibraryLowerPermissions.SetInvoiceApp;
        GetNotDefaultVATRate(VATProductPostingGroup);
        EnqueueVATRateFields(VATProductPostingGroup);
        LibraryVariableStorage.Enqueue(false); // Not Default VAT Rate

        // [WHEN] The user open selected VAT Rate from Vat Rates list
        O365VATPostingSetupList.OpenEdit;
        O365VATPostingSetupList.GotoRecord(VATProductPostingGroup);
        O365VATPostingSetupList.Open.Invoke;

        // [THEN] VAT Rate page is opened and VAT Rate, Description, VAT Reg. Reference and link to default is shown
        // Page handler verification
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ModifyVATRateAndVATRegReference()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATClause: Record "VAT Clause";
        O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card";
        VatPerc: Decimal;
        VATRegReference: Text[250];
    begin
        // [GIVEN] VAT Rate
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] When user modifes VAT Percentage and VAT Reg. Reference
        VatPerc := LibraryRandom.RandInt(10);
        VATRegReference := LibraryUtility.GenerateGUID;
        VATProductPostingGroup.FindFirst;

        O365VATPostingSetupCard.OpenEdit;
        O365VATPostingSetupCard.GotoRecord(VATProductPostingGroup);
        O365VATPostingSetupCard."VAT Percentage".SetValue(VatPerc);
        O365VATPostingSetupCard."VAT Regulation Reference".SetValue(VATRegReference);
        O365VATPostingSetupCard.Close;

        // [THEN] The VAT Posting Setup and linked VAT CLause are updated
        VATPostingSetup.Get('DOMESTIC', VATProductPostingGroup.Code);
        Assert.AreEqual(VATPostingSetup."VAT %", VatPerc, '');
        VATClause.Get(VATPostingSetup."VAT Clause Code");
        Assert.AreEqual(VATClause.Description, VATRegReference, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NewVATRateCannotBeCreated()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365VATPostingSetupList: TestPage "O365 VAT Posting Setup List";
    begin
        // [GIVEN] VAT Rates page populated
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User access the page
        VATProductPostingGroup.FindFirst;
        O365VATPostingSetupList.OpenEdit;

        // [THEN] the page is not editable, new VAT Rate cannot be created
        Assert.IsFalse(O365VATPostingSetupList.Editable, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SetVATRateAsDefault()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card";
    begin
        // [GIVEN] VAT Rates page populated
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User set VAT Rate as default
        GetNotDefaultVATRate(VATProductPostingGroup);
        O365VATPostingSetupCard.OpenEdit;
        O365VATPostingSetupCard.DefaultVATGroupTxt.AssertEquals(Format(SetDefaultVATRateTxt));
        O365VATPostingSetupCard.GotoRecord(VATProductPostingGroup);
        O365VATPostingSetupCard.DefaultVATGroupTxt.DrillDown;
        O365VATPostingSetupCard.Close;

        // [THEN] the page shows that the VAT Rate is default
        O365VATPostingSetupCard.OpenEdit;
        O365VATPostingSetupCard.GotoRecord(VATProductPostingGroup);
        O365VATPostingSetupCard.DefaultVATGroupTxt.AssertEquals(Format(DefaultVATRateTxt));
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VATRateCannotBeLessThanZero()
    var
        O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card";
    begin
        // [GIVEN] VAT Rate
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User set VAT Percentage less than 0
        O365VATPostingSetupCard.OpenEdit;
        asserterror O365VATPostingSetupCard."VAT Percentage".SetValue(-LibraryRandom.RandInt(10));

        // [THEN] The error is thrown
        Assert.ExpectedError('The value must be greater than or equal to 0');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NewItemUsesDefaultVATRate()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365ItemCard: TestPage "O365 Item Card";
    begin
        // [FEATURE] [Item]
        // [GIVEN] Default VAT Rate is available
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Anew user is created
        O365ItemCard.OpenEdit;
        O365ItemCard.New;

        // [THEN] Default VAT Rate is set
        VATProductPostingGroup.Get(O365TemplateManagement.GetDefaultVATProdPostingGroup);
        O365ItemCard.VATProductPostingGroupDescription.AssertEquals(VATProductPostingGroup.Description);
    end;

    local procedure EnqueueVATRateFields(VATProductPostingGroup: Record "VAT Product Posting Group")
    begin
        LibraryVariableStorage.Enqueue(VATProductPostingGroup.Code);
        LibraryVariableStorage.Enqueue(VATProductPostingGroup.Description);
    end;

    local procedure GetNotDefaultVATRate(var VATProductPostingGroup: Record "VAT Product Posting Group")
    var
        DefaultVATProductPostingGroupCode: Code[20];
    begin
        DefaultVATProductPostingGroupCode := O365TemplateManagement.GetDefaultVATProdPostingGroup;
        VATProductPostingGroup.SetFilter(Code, '<>%1', DefaultVATProductPostingGroupCode);
        VATProductPostingGroup.FindFirst;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATPostingSetupCardHandler(var O365VATPostingSetupCard: TestPage "O365 VAT Posting Setup Card")
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateVariant: Variant;
        DefaultVATRateVariant: Variant;
        VATRateDescriptionVariant: Variant;
        DefaultVATRate: Boolean;
        VATRate: Code[10];
    begin
        // VAT Prod Post. Code
        LibraryVariableStorage.Dequeue(VATRateVariant);
        VATRate := VATRateVariant;

        // description
        LibraryVariableStorage.Dequeue(VATRateDescriptionVariant);
        O365VATPostingSetupCard.Description.AssertEquals(VATRateDescriptionVariant);

        // VAT Rate
        VATPostingSetup.Get('DOMESTIC', VATRate);
        O365VATPostingSetupCard."VAT Percentage".AssertEquals(VATPostingSetup."VAT %");

        // Default VAT
        LibraryVariableStorage.Dequeue(DefaultVATRateVariant);
        DefaultVATRate := DefaultVATRateVariant;
        if DefaultVATRate then
            O365VATPostingSetupCard.DefaultVATGroupTxt.AssertEquals(Format(DefaultVATRateTxt))
        else
            O365VATPostingSetupCard.DefaultVATGroupTxt.AssertEquals(Format(SetDefaultVATRateTxt));

        // VAT Reg. Reference
        VATClause.Get(VATPostingSetup."VAT Clause Code");
        O365VATPostingSetupCard."VAT Regulation Reference".AssertEquals(VATClause.Description);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

