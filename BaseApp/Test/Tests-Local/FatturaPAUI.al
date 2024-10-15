codeunit 144211 "FatturaPA UI"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [UI]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAFieldsExistsInSalesOrderPage()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 361252] FatturaPA fields are visible in the Sales Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesOrder.OpenEdit();
        Assert.IsTrue(SalesOrder."Fattura Project Code".Visible(), 'Fattura Project Code is not visible');
        Assert.IsTrue(SalesOrder."Fattura Tender Code".Visible(), 'Fattura Tender Code is not visible');
        SalesOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAFieldsExistsInServiceOrderPage()
    var
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 361252] FatturaPA fields are visible in the Service Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        ServiceOrder.OpenEdit();
        Assert.IsTrue(ServiceOrder."Fattura Project Code".Visible(), 'Fattura Project Code is not visible');
        Assert.IsTrue(ServiceOrder."Fattura Tender Code".Visible(), 'Fattura Tender Code is not visible');
        ServiceOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"FatturaPA UI");
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"FatturaPA UI");

        LibraryITLocalization.SetupFatturaPA;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"FatturaPA UI");
    end;
}

