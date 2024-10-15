codeunit 139062 "Add-in Automatic Line Gen."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Office Add-in] [EMail] [Automatic Document Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OfficeHostType: DotNet OfficeHostType;
        CommandType: DotNet OutlookCommand;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NoEmailBodyDoesNotGenerateLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 183290] If there is no email body, we do not try to generate lines for the user.
        Initialize();

        // [GIVEN] User has an email from a customer that contains no body text
        Setup(OfficeAddinContext, '', CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The customer card opens
        // [THEN] A new, empty sales quote is created
        SalesQuote.SalesLines."Total Amount Incl. VAT".AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailBodyWithNoKeywordsDoesNotGenerateLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 183290] If there is an email body that contains no relevant items, we do not try to generate lines for the user.
        Initialize();

        // [GIVEN] User has an email from a customer that contains some irrelevant body text
        Setup(OfficeAddinContext, IrrelevantBodyText(), CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] A new, empty sales quote is created
        SalesQuote.SalesLines."Total Amount Incl. VAT".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithDecimalQuantityGeneratesLine()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains a decimal quantity for an item, generate a line item for it.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for an item.
        CreateRandomItems(Item, Quantity, 1);
        EmailBody := StrSubstNo(SingleQuantityBodyText(), Item[1].Description, Quantity[1]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The customer card opens
        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the line from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithMultipleQuantitiesGeneratesLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains decimal quantities for multiple items, generate line items for each.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithMultipleQuantitiesGeneratesLinesForPurchaseDoc()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorCard: TestPage "Vendor Card";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] Line generation is enabled for purchase documents.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewPurchaseInvoice);
        OfficeAddinContext.SetRange(Email, RandomVendorEmail());

        // [WHEN] The user opens the add-in in the context of the customer email
        PurchaseInvoice.Trap();
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The purchase invoice page opens and contains the lines from the email body
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item[1]."No.");
        PurchaseInvoice.PurchLines.Quantity.AssertEquals(Quantity[1]);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item[2]."No.");
        PurchaseInvoice.PurchLines.Quantity.AssertEquals(Quantity[2]);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithEdgeCaseQuantitiesGeneratesLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SimilarItem: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains decimal quantities for multiple items, generate line items for each.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 4);
        CreateSimilarItems(SimilarItem, Quantity, 4, 'dongle');
        EmailBody := StrSubstNo(EdgeCaseBodyText(),
            Item[1].Description, Quantity[1],
            Item[2].Description, Quantity[2],
            Item[3].Description, Quantity[3],
            SimilarItem[4].Description, Quantity[4], 'Dongles');
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithSpelledOutQuantityGeneratesLine()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains a textual quantity for an item, generate a line item for it.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for an item with a textual quantity.
        CreateRandomItems(Item, Quantity, 1);
        Quantity[1] := 8;
        EmailBody := StrSubstNo(SingleQuantityBodyText(), Item[1].Description, 'eight');
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the line from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithMixedQuantitiesGeneratesLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains both text and decimal quantities of items, generate line items for both.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for items using both textual and numeric quantities
        CreateRandomItems(Item, Quantity, 2);
        Quantity[1] := 4;
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, 'four', Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure EmailBodyWithNoQuantitiesGeneratesLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains only references to items (no quantities), we still find the items.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items but does not reference a quantity
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, 'notanumber', Item[2].Description, 'notanumber');
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler) with 0 as the quantity
        // [THEN] The sales quote page opens and contains the lines from the email body
        Quantity[1] := 0;
        Quantity[2] := 0;
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOK')]
    [Scope('OnPrem')]
    procedure ExtraLongBodyGeneratesLines()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is a very long email body that contains several item keywords, generate the correct line items.
        Initialize();

        // [GIVEN] User has a long email from a customer that contains a request for an item.
        CreateRandomItems(Item, Quantity, 3);
        EmailBody := StrSubstNo(ExtraLongBodyText(),
            Item[1].Description, Quantity[1],
            Item[2].Description, Quantity[2],
            Item[3].Description, Quantity[3]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 3);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageUncheckItems')]
    [Scope('OnPrem')]
    procedure UncheckDiscoverLinesDoesNotPopulatesDocument()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If the user unchecks the items, do not add them to the document lines.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [WHEN] User unchecks all items in list and clicks OK (page handler)
        // [THEN] A new, empty sales quote is created
        SalesQuote.SalesLines."Total Amount Incl. VAT".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickCancel')]
    [Scope('OnPrem')]
    procedure ClickCancelOnSuggestedLinesDoesNotPopulateDocument()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If the user clicks cancel when the suggested items page comes up, do not generate line items.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [WHEN] User clicks cancel on the page (page handler)
        // [THEN] A new, empty sales quote is created
        SalesQuote.SalesLines."Total Amount Incl. VAT".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickDoNotShowAgain')]
    [Scope('OnPrem')]
    procedure DontShowAgainDisablesMessageInInstructionMgt()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If the user clicks "do not show again" when the suggested items page comes up, disable the page in instruction mgt.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] The user clicks "Do Not Show Again"
        // Page handler does this

        // [THEN] The message is disabled in instruction management
        Assert.IsFalse(InstructionMgt.IsEnabled(InstructionMgt.AutomaticLineItemsDialogCode()), 'Message should be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoGenerationIfDisabledInInstructionMgt()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If the user unchecks the items, do not add them to the document lines.
        Initialize();

        // [GIVEN] The message is disabled in instruction mgt
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.AutomaticLineItemsDialogCode());

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens (page handler)
        // [WHEN] User unchecks all items in list and clicks OK (page handler)
        // [THEN] A new, empty sales quote is created
        SalesQuote.SalesLines."Total Amount Incl. VAT".AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageWithItemResolution,ResolveItemChooseFirst')]
    [Scope('OnPrem')]
    procedure UserCanResolveItemIfMultipleMatches()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] An email containing an item reference that yields multiple hits in the item table enables user to resolve the item.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for an ambiguous item
        CreateSimilarItems(Item, Quantity, 2, 'jabberwocky');
        CreateDistinctItem(Item[2]);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), 'jabberwockys', Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The suggested line items page opens and indicates that an item needs to be resolved
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageChangeItem,ResolveItemChooseFirst')]
    [Scope('OnPrem')]
    procedure UserCanChangeSuggestedItem()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an incorrect item in the suggested lines, the user can change it to another item.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] The user chooses to change an item and picks the first in the list
        Item[1].FindFirst();

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body, including the one the user changed to
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageAddItems,ResolveItemChooseLast')]
    [Scope('OnPrem')]
    procedure UserCanAddNewLineToSuggestedItems()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        SalesQuote: TestPage "Sales Quote";
        EmailBody: Text;
        Quantity: array[5] of Integer;
    begin
        // [SCENARIO 183290] If there is an email body that contains decimal quantities for multiple items, generate line items for each.
        Initialize();

        // [GIVEN] User has an email from a customer that contains a request for several items
        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(MultipleQuantityBodyText(), Item[1].Description, Quantity[1], Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        // [WHEN] The user opens the add-in in the context of the customer email
        SalesQuote.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] The user adds a few items to the list using the drilldown functionality
        // These values are set in the modal page handler
        Item[3].FindLast();
        Quantity[3] := 13;

        Item[4].FindLast();
        Quantity[4] := 26;

        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The sales quote page opens and contains the lines from the email body
        VerifyQuoteLines(SalesQuote, Item, Quantity, 4);
    end;

    [Test]
    [HandlerFunctions('HandleSuggestedLinesPageClickOKDefaultAdd')]
    [Scope('OnPrem')]
    procedure SuggestedLinesAreNotAddedByDefault()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: array[5] of Record Item;
        EmailBody: Text;
        Quantity: array[5] of Integer;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 183290] Do not add the line items by default.
        Initialize();

        CreateRandomItems(Item, Quantity, 2);
        EmailBody := StrSubstNo(SingleQuantityBodyText(), Item[2].Description, Quantity[2]);
        Setup(OfficeAddinContext, EmailBody, CommandType.NewSalesQuote);

        SalesQuote.Trap();
        // [WHEN] The user opens the add-in in the context of the customer email
        RunMailEngine(OfficeAddinContext);

        // [THEN] The customer card opens
        // [THEN] The suggested line items page opens (page handler)
        // [THEN] The suggested line items are not added by default.
        VerifyQuoteLines(SalesQuote, Item, Quantity, 2);
    end;

    local procedure Initialize()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        OfficeAddin: Record "Office Add-in";
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeAddinSetup: Record "Office Add-in Setup";
        OfficeInvoice: Record "Office Invoice";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        InstructionMgt: Codeunit "Instruction Mgt.";
        OfficeMgt: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Add-in Automatic Line Gen.");

        Clear(LibraryVariableStorage);
        Clear(LibraryOfficeHostProvider);
        Clear(OfficeHost);

        OfficeAddinContext.DeleteAll();
        OfficeInvoice.DeleteAll();
        if NameValueBuffer.Get(SessionId()) then
            NameValueBuffer.Delete();

        OfficeAddinSetup.ModifyAll("Office Host Codeunit ID", CODEUNIT::"Library - Office Host Provider");
        BindSubscription(LibraryOfficeHostProvider);
        OfficeMgt.InitializeHost(OfficeHost, OfficeHostType.OutlookTaskPane);

        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.AutomaticLineItemsDialogCode());

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Add-in Automatic Line Gen.");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Add-in Automatic Line Gen.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageClickCancel(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageClickOK(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageClickOKDefaultAdd(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.First();
        Assert.IsFalse(OfficeSuggestedLineItems.Add.AsBoolean(), 'The Add value must be false for first item');
        OfficeSuggestedLineItems.Next();
        Assert.IsFalse(OfficeSuggestedLineItems.Add.AsBoolean(), 'The Add value must be false for second item');
        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageClickDoNotShowAgain(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.First();
        OfficeSuggestedLineItems.DoNotShowAgain.SetValue(true);
        OfficeSuggestedLineItems.Next();
        Assert.IsTrue(OfficeSuggestedLineItems.DoNotShowAgain.AsBoolean(), 'The DoNotShowAgain box should be checked.');
        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageUncheckItems(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.First();
        repeat
            OfficeSuggestedLineItems.Add.SetValue(false);
        until not OfficeSuggestedLineItems.Next();

        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageWithItemResolution(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.First();
        AssertError OfficeSuggestedLineItems.Add.SetValue(true);

        OfficeSuggestedLineItems.Next();
        Assert.IsTrue(OfficeSuggestedLineItems.Add.Enabled(), 'The "Add" box can be enabled if the line needs no resolution.');

        OfficeSuggestedLineItems.First();
        OfficeSuggestedLineItems.Item.DrillDown();

        OfficeSuggestedLineItems.First();
        Assert.IsTrue(OfficeSuggestedLineItems.Add.Enabled(), 'The "Add" box can be enabled after the item is resolved.');
        Assert.IsTrue(OfficeSuggestedLineItems.Add.AsBoolean(), 'The "Add" box should be checked after the item is resolved.');

        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageChangeItem(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.First();
        Assert.IsTrue(OfficeSuggestedLineItems.Add.Enabled(), 'The "Add" box should be enabled for the item.');
        OfficeSuggestedLineItems.Item.DrillDown();
        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSuggestedLinesPageAddItems(var OfficeSuggestedLineItems: TestPage "Office Suggested Line Items")
    begin
        OfficeSuggestedLineItems.Last();
        OfficeSuggestedLineItems.Next();
        OfficeSuggestedLineItems.Item.DrillDown();
        OfficeSuggestedLineItems.Quantity.SetValue(13);

        OfficeSuggestedLineItems.Next();
        OfficeSuggestedLineItems.Item.DrillDown();
        OfficeSuggestedLineItems.Quantity.SetValue(26);

        OfficeSuggestedLineItems.Next();
        OfficeSuggestedLineItems.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResolveItemChooseFirst(var ItemList: TestPage "Item List")
    begin
        ItemList.First();
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResolveItemChooseLast(var ItemList: TestPage "Item List")
    begin
        ItemList.Last();
        ItemList.OK().Invoke();
    end;

    local procedure CreateDistinctItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateRandomItems(var Item: array[5] of Record Item; var Quantity: array[5] of Integer; "Count": Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do begin
            CreateDistinctItem(Item[i]);
            Quantity[i] := RandomQuantity();
        end;
    end;

    local procedure CreateSimilarItems(var Item: array[5] of Record Item; var Quantity: array[5] of Integer; "Count": Integer; Description: Text[20])
    var
        i: Integer;
    begin
        for i := 1 to Count do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Validate(Description, StrSubstNo('%1%1%1 %2', i, Description));
            Item[i].Modify();
            Quantity[i] := RandomQuantity();
        end;
    end;

    local procedure CrLf() NewLine: Text[2]
    begin
        NewLine[1] := 13;
        NewLine[2] := 10;
    end;

    local procedure EdgeCaseBodyText() BodyText: Text
    begin
        // This text catches some of the edge cases
        // 1. Multiple items referenced in close proximity
        // 2. Quantity comes after item reference
        // 3. Multiple references to the same item
        // 4. Reference item by full name early on, but only partially referenced next to quantity.

        // Here, %7 would be something like "London Swivel Chair" and %9 would be just "chairs".
        // The algorithm should automatically resolve "chairs" to "London Swivel Chair".
        BodyText := 'Hi there,' + CrLf() + CrLf() +
          'Could you give me a quote for %2 of your %1 and %4 %3? Also throw in %5 maybe %6 of them. ' +
          'Actually, only make that 3 of %5. Finally, I really like your %7. Can you give me %8 of yo' +
          'ur %9?' + CrLf() + CrLf() +
          'Thanks!' + CrLf() +
          'Frank';
    end;

    local procedure ExtraLongBodyText() BodyText: Text
    begin
        BodyText := 'Hi there,' + CrLf() + CrLf() +
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ' +
          'ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud %2 %1 exercitation' +
          ' ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehe' +
          'nderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occa' +
          'ecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
          '.' + CrLf() + CrLf() +
          'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laud' +
          'antium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto' +
          ' beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatu' +
          'r aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi' +
          ' nesciunt. Neque porro quisquam est %4 %3, qui dolorem ipsum quia dolor sit amet, consecte' +
          'tur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore m' +
          'agnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ul' +
          'lam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem ve' +
          'l eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, ' +
          'vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?' + CrLf() + CrLf() +
          'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium volu' +
          'ptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cup' +
          'iditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est' +
          ' laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio %6 %5. ' +
          'Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id ' +
          'quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus' +
          '. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe evenie' +
          't ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic te' +
          'netur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut pe' +
          'rferendis doloribus asperiores repellat.' + CrLf() + CrLf() + CrLf() +
          'Kind regards,' + CrLf() +
          'Jutta';
    end;

    local procedure IrrelevantBodyText() BodyText: Text
    begin
        BodyText := 'Hi there,' + CrLf() + CrLf() +
          'I am the new sales manager here at Fabrikam Precision Machining. I know we will have a goo' +
          'd business relationship, and I am happy to have made your acquaintance. I also need 100 ' +
          ' gzgcytbqnpfqwqctuqtzlnclbussjwibyypgreeaauoviqspkkcvjdfuqtihfwaubeznqepsmzksbqqluzb.' + CrLf() + CrLf() +
          'Best,' + CrLf() +
          'Sascha';
    end;

    local procedure MultipleQuantityBodyText() BodyText: Text
    begin
        BodyText := 'Hi there,' + CrLf() + CrLf() +
          'Could you give me a quote for %2 of your %1? Also throw in %4 of your %3.' + CrLf() + CrLf() +
          'Thanks!' + CrLf() +
          'Frank';
    end;

    local procedure SingleQuantityBodyText() BodyText: Text
    begin
        BodyText := 'Hi there,' + CrLf() + CrLf() +
          'We are interested in your %1. Could you give me a quote for %2 of your %1?' + CrLf() + CrLf() +
          'Thanks!' + CrLf() +
          'Maic';
    end;

    local procedure RandomCustomerEmail(): Text[80]
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        Customer.FindFirst();
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();

        Contact.Get(ContactBusinessRelation."Contact No.");
        exit(Contact."E-Mail");
    end;

    local procedure RandomVendorEmail(): Text[80]
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();

        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.Validate("E-Mail", StrSubstNo('%1@contoso.com', CreateGuid()));
        Contact.Modify();

        exit(Contact."E-Mail");
    end;

    local procedure RandomQuantity(): Integer
    begin
        exit(LibraryRandom.RandIntInRange(1, 20));
    end;

    [Normal]
    local procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context")
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
        CustomerCard: TestPage "Customer Card";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        CustomerCard.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    local procedure Setup(var OfficeAddinContext: Record "Office Add-in Context"; BodyText: Text; CommandType: Text)
    begin
        LibraryOfficeHostProvider.SetEmailBody(BodyText);
        OfficeAddinContext.SetRange(Email, RandomCustomerEmail());
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Message);
        OfficeAddinContext.SetRange(Command, CommandType);
    end;

    local procedure VerifyQuoteLines(var SalesQuote: TestPage "Sales Quote"; Item: array[5] of Record Item; Quantity: array[5] of Integer; "Count": Integer)
    var
        i: Integer;
    begin
        SalesQuote.SalesLines.First();
        for i := 1 to Count do begin
            SalesQuote.SalesLines."No.".AssertEquals(Item[i]."No.");
            SalesQuote.SalesLines.Quantity.AssertEquals(Quantity[i]);
            SalesQuote.SalesLines.Next();
        end;
    end;
}