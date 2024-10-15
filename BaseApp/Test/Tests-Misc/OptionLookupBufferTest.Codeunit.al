codeunit 134645 "Option Lookup Buffer Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Option Lookup]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        InvalidTypeErr: Label 'is not a valid type for this document';

    [Test]
    [Scope('OnPrem')]
    procedure FillOptionBufferForSalesTest()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Fill OptionLookupBuffer with values for Sales
        Initialize;

        // [GIVEN] Empty Option Lookup Buffer table
        // [WHEN] FillBuffer is called for LookupType::Sales
        TempOptionLookupBuffer.FillBuffer(TempOptionLookupBuffer."Lookup Type"::Sales.AsInteger());

        // [THEN] Buffer table is filled
        Assert.RecordCount(TempOptionLookupBuffer, 10);

        // [THEN] Buffer table has entry for 'Comment'
        TempOptionLookupBuffer.Get(SalesLine.FormatType);

        // [THEN] Buffer table has entry for 'G/L Account'
        TempOptionLookupBuffer.Get(Format(SalesLine.Type::"G/L Account"));

        // [THEN] Buffer table has entry for 'Inventory'
        TempOptionLookupBuffer.Get(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillOptionBufferWithCustomValuesForSalesTest()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        OptionLookupBufferTest: Codeunit "Option Lookup Buffer Test";
        SalesLine: Record "Sales Line";
        t: Text;
    begin
        // [SCENARIO 412825] Fill OptionLookupBuffer with custom values for Sales
        Initialize;

        // [GIVEN] Empty Option Lookup Buffer table
        // [GIVEN] Extend "Sales Line Type" enum and add handler for Test_Custom1 value
        BindSubscription(OptionLookupBufferTest); // to add handling of custom value
        // [WHEN] FillLookupBuffer is called for LookupType::Sales
        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);

        // [THEN] Buffer table is filled: 6 W1 values + 4 CH values + 1 custom
        Assert.RecordCount(TempOptionLookupBuffer, 11);

        // [THEN] Buffer table has entry for 'Comment'
        TempOptionLookupBuffer.Get(SalesLine.FormatType);

        // [THEN] Buffer table has entry for 'G/L Account'
        TempOptionLookupBuffer.Get(Format(SalesLine.Type::"G/L Account"));

        // [THEN] Buffer table has entry for 'Inventory'
        TempOptionLookupBuffer.Get(Format(SalesLine.Type::Item));

        // [THEN] Buffer table has entry for 'Test Custom1', ID is 134645
        SalesLine.Type := SalesLine.Type::Test_Custom1;
        TempOptionLookupBuffer.Get(Format(SalesLine.Type));
        TempOptionLookupBuffer.TestField(ID, SalesLine.Type::Test_Custom1.AsInteger());
        // [THEN] Buffer table has no entry for 'Test Custom2'
        assert.IsFalse(TempOptionLookupBuffer.Get(Format(SalesLine.Type::Test_Custom2)), 'Custom2 should not be found');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Option Lookup Buffer", 'OnBeforeIncludeOption', '', false, false)]
    local procedure OnBeforeIncludeOption(OptionLookupBuffer: Record "Option Lookup Buffer"; LookupType: Option; Option: Integer; var Handled: Boolean; var Result: Boolean);
    begin
        case LookupType of
            "Option Lookup Type"::Sales.AsInteger():
                if Option = "Sales Line Type"::Test_Custom1.AsInteger() then begin
                    Handled := true;
                    Result := true;
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillOptionBufferForPurchaseTest()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Fill OptionLookupBuffer with values for Purchase
        Initialize;

        // [GIVEN] Empty Option Lookup Buffer table
        // [WHEN] FillBuffer is called for LookupType::Purchase
        TempOptionLookupBuffer.FillBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases.AsInteger());

        // [THEN] Buffer table is filled
        Assert.RecordCount(TempOptionLookupBuffer, 6);

        // [THEN] Buffer table has entry for 'Comment'
        TempOptionLookupBuffer.Get(PurchaseLine.FormatType);

        // [THEN] Buffer table has entry for 'G/L Account'
        TempOptionLookupBuffer.Get(Format(PurchaseLine.Type::"G/L Account"));

        // [THEN] Buffer table has entry for 'Inventory'
        TempOptionLookupBuffer.Get(Format(PurchaseLine.Type::Item));

        // [THEN] Buffer table has entry for 'Resource'
        TempOptionLookupBuffer.Get(Format(PurchaseLine.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoCompleteOptionTest()
    var
        TempReferenceOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        InputText: Text[20];
        ExpectedText: Text[30];
    begin
        // [SCENARIO] Autocompleting a partial Option Caption

        // [GIVEN] A reference list of options
        TempReferenceOptionLookupBuffer.FillBuffer(TempReferenceOptionLookupBuffer."Lookup Type"::Purchases.AsInteger());
        TempReferenceOptionLookupBuffer.FindSet();

        repeat
            // [WHEN] Trying to autocomplete an incomplete option
            ExpectedText := TempReferenceOptionLookupBuffer."Option Caption";
            InputText := CopyStr(ExpectedText, 1, StrLen(ExpectedText) - 1);
            TempOptionLookupBuffer.AutoCompleteOption(InputText, TempOptionLookupBuffer."Lookup Type"::Purchases.AsInteger());

            // [THEN] The correct option is returned
            Assert.AreEqual(ExpectedText, InputText, 'AutoCompleteOption returned incorrect value');
        until TempReferenceOptionLookupBuffer.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOptionTest()
    var
        TempReferenceOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
    begin
        // [SCENARIO] Validating an Option Caption

        // [GIVEN] A reference list of options
        TempReferenceOptionLookupBuffer.FillBuffer(TempReferenceOptionLookupBuffer."Lookup Type"::Purchases.AsInteger());
        TempOptionLookupBuffer.FillBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases.AsInteger());
        TempReferenceOptionLookupBuffer.FindSet();

        repeat
            // [WHEN] Trying to validate an existing option
            // [THEN] No error is thrown
            TempOptionLookupBuffer.ValidateOption(TempReferenceOptionLookupBuffer."Option Caption");
        until TempReferenceOptionLookupBuffer.Next = 0;

        // [WHEN] Trying to validate an invalid option
        asserterror TempOptionLookupBuffer.ValidateOption(LibraryUtility.GenerateGUID);
        // [THEN] An error is thrown
        Assert.ExpectedError(InvalidTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTypeFieldVisibilityNonSaaS()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize;

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [WHEN] Opening a new Sales Invoice
        SalesInvoice.OpenNew;

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(SalesInvoice.SalesLines.Type.Visible, 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(SalesInvoice.SalesLines.FilteredTypeField.Visible, 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTypeFieldVisibilitySaaS()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize;

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Sales Invoice
        SalesInvoice.OpenNew;

        // [THEN] The Subtype field is visible and the type field is not
        asserterror SalesInvoice.SalesLines.Type.Activate;
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(SalesInvoice.SalesLines.FilteredTypeField.Visible, 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Sales Invoice and all values can be selected.
        Initialize;

        // [GIVEN] A Sales Invoice
        SalesInvoice.OpenNew;

        TempOptionLookupBuffer.FillBuffer(TempOptionLookupBuffer."Lookup Type"::Sales.AsInteger());
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            SalesInvoice.SalesLines.FilteredTypeField.Lookup;

            // [THEN] The Subtype is set to service
            SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubtypeAutoComplete()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize;

        // [GIVEN] A Sales Invoice
        SalesInvoice.OpenNew;

        // [WHEN] Setting the Subtype on the Sales Line to ac
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to it
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Item
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype on the Sales Line to fi
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"Fixed Asset"), 1, 2));
        // [THEN] The Subtype is set to Fixed Asset
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"Fixed Asset"));

        // [WHEN] Setting the Subtype on the Sales Line to re
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Resource), 1, 2));
        // [THEN] The Subtype is set to Resource
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Resource));

        // [WHEN] Setting the Subtype on the Sales Line to co
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(CopyStr(SalesLine.FormatType, 1, 2));
        // [THEN] The Subtype is set to Comment
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubtypeBlank()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize;

        // [GIVEN] A Sales Invoice
        SalesInvoice.OpenNew;

        // [WHEN] Setting the Subtype on the Sales Line to ' '
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType);

        // [WHEN] Setting the Subtype on the Sales Line to ''
        SalesInvoice.SalesLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDisallowedSubtypes()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, Item Subtype is set
        Initialize;

        // [GIVEN] A Sales Invoice
        SalesInvoice.OpenNew;

        // [WHEN] Setting the Subtype to Fixed Asset on the Sales Line
        SalesInvoice.SalesLines.FilteredTypeField.SetValue('AAA');
        // [THEN] An Item Subtype has been set
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to Resource on the Sales Line
        SalesInvoice.SalesLines.FilteredTypeField.SetValue('123ZZZ');
        // [THEN] An Item Subtype has been set
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to a random value on the Sales Line
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID);
        // [THEN] An Item Subtype has been set
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTypeFieldEditability()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] In View mode the field is not editable
        Initialize;

        // [GIVEN] A SaaS environment and a Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] Opening a Sales Invoice in EDIT
        SalesInvoice.OpenEdit;
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The Subtype field is editable
        Assert.IsTrue(SalesInvoice.SalesLines.FilteredTypeField.Editable, 'Subtype field should be editable');

        // [WHEN] Switching to VIEW
        SalesInvoice.View.Invoke;

        // [THEN] The Subtype field is NOT editable
        Assert.IsFalse(SalesInvoice.SalesLines.FilteredTypeField.Editable, 'Subtype field should NOT be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderLineSubtypeAutoComplete()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Resource]
        // [SCENARIO 289386] A partial Subtype is entered into the Subtype field triggers autocomplete in purchase order document line
        Initialize;

        // [GIVEN] Purchase order
        PurchaseOrder.OpenNew();

        // [WHEN] Setting the Subtype on the purchase line to 're'
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::Resource), 1, 2));
        // [THEN] The Subtype is set to "Resource"
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Resource));

        // [WHEN] Setting the Subtype on the purchase line to 'ac'
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::"G/L Account"), 5, 2));
        // [THEN] The Subtype is set to "G/L Account"
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the purchase line to 'it'
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to "Item"
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));

        // [WHEN] Setting the Subtype on the purchase line to 'co'
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(PurchaseLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to "Comment"
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.FormatType()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OptionLookupListModalHandler(var OptionLookupList: TestPage "Option Lookup List")
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
    begin
        TempOptionLookupBuffer.FillBuffer(LibraryVariableStorage.DequeueInteger);
        TempOptionLookupBuffer.FindSet();
        repeat
            OptionLookupList.GotoKey(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next = 0;

        OptionLookupList.GotoKey(LibraryVariableStorage.DequeueText);
        OptionLookupList.OK.Invoke;
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Option Lookup Buffer Test");
        ExperienceTierSetup.DeleteAll();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        LibraryVariableStorage.Clear;
        LibrarySales.DisableWarningOnCloseUnpostedDoc;
    end;
}

