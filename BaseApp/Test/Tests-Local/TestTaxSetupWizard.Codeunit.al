codeunit 142095 "Test Tax Setup Wizard"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales Tax] [Wizard]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        CityTxt: Label 'My City';
        CountyTxt: Label 'My County';
        StateTxt: Label 'WA';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure TestRunFirstTime()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        // Init. Start with an empty table
        LibraryLowerPermissions.SetInvoiceApp;
        if SalesTaxSetupWizard.Get() then
            SalesTaxSetupWizard.Delete();

        // Execute the wizard, let the wizard decide a tax area code
        RunTaxWizard(false, CityTxt, 2, CountyTxt, 3, StateTxt, 4, '');

        // Validate
        SalesTaxSetupWizard.Get();
        ValidateTaxArea(SalesTaxSetupWizard."Tax Area Code", 9);
        RunTaxWizard(true, CityTxt, 2, CountyTxt, 3, StateTxt, 4, SalesTaxSetupWizard."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunSecondTimeSameCity()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        // Init. Start with an empty table
        LibraryLowerPermissions.SetInvoiceApp;
        if SalesTaxSetupWizard.Get() then
            SalesTaxSetupWizard.Delete();

        // Execute the wizard first time, let the wizard decide a tax area code
        RunTaxWizard(false, CityTxt, 2, CountyTxt, 3, StateTxt, 4, '');
        SalesTaxSetupWizard.Get();
        ValidateTaxArea(SalesTaxSetupWizard."Tax Area Code", 9);

        // Execute the wizard second time, let the wizard keep all values
        RunTaxWizard(false, CityTxt, 3, CountyTxt, 3, StateTxt, 4, '');

        // Validate
        SalesTaxSetupWizard.Get();
        ValidateTaxArea(SalesTaxSetupWizard."Tax Area Code", 10);
        RunTaxWizard(true, CityTxt, 3, CountyTxt, 3, StateTxt, 4, SalesTaxSetupWizard."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunSecondTimeOtherCity()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        // Init. Start with an empty table
        LibraryLowerPermissions.SetInvoiceApp;
        if SalesTaxSetupWizard.Get() then
            SalesTaxSetupWizard.Delete();

        // Execute the wizard first time, let the wizard decide a tax area code
        RunTaxWizard(false, CityTxt, 2, CountyTxt, 3, StateTxt, 4, '');
        SalesTaxSetupWizard.Get();
        ValidateTaxArea(SalesTaxSetupWizard."Tax Area Code", 9);

        // Execute the wizard second time, let the wizard keep all values
        RunTaxWizard(false, 'Some Other City', 3, CountyTxt, 3, StateTxt, 4, SalesTaxSetupWizard."Tax Area Code");

        // Validate
        SalesTaxSetupWizard.Get();
        ValidateTaxArea(SalesTaxSetupWizard."Tax Area Code", 10);
        RunTaxWizard(true, 'Some Other City', 3, CountyTxt, 3, StateTxt, 4, SalesTaxSetupWizard."Tax Area Code");
    end;

    local procedure RunTaxWizard(ValidateMode: Boolean; City: Text[50]; CityRate: Decimal; County: Text[50]; CountyRate: Decimal; State: Code[10]; StateRate: Decimal; AreaCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizardPage: TestPage "Sales Tax Setup Wizard";
    begin
        // ValidateMode=true -> no values are set, but only used to compare to previous values.

        if not ValidateMode then begin
            LibraryERM.CreateGLAccount(GLAccount);
            GLAccount.Find();
            if GLAccount."Income/Balance" <> GLAccount."Income/Balance"::"Balance Sheet" then begin
                GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
                GLAccount.Modify();
            end;
        end;

        // Run the wizard
        SalesTaxSetupWizardPage.OpenEdit; // Shows Welcome
        SalesTaxSetupWizardPage.ActionNextStep.Invoke; // Goto Default tax group created

        SalesTaxSetupWizardPage.ActionNextStep.Invoke; // Goto account selection
        if ValidateMode then begin
            Assert.AreNotEqual('', SalesTaxSetupWizardPage."Tax Account (Sales)".Value, 'Sales tax account was blank');
            Assert.AreNotEqual('', SalesTaxSetupWizardPage."Tax Account (Purchases)".Value, 'Purchase tax account was blank');
        end else begin
            SalesTaxSetupWizardPage."Tax Account (Sales)".SetValue(GLAccount."No.");
            SalesTaxSetupWizardPage."Tax Account (Purchases)".SetValue(GLAccount."No.");
        end;

        SalesTaxSetupWizardPage.ActionNextStep.Invoke; // Goto city/county/state rate page
        if ValidateMode then begin
            Assert.AreEqual(City, SalesTaxSetupWizardPage.City.Value, 'Wrong City');
            Assert.AreEqual(CityRate, SalesTaxSetupWizardPage."City Rate".AsDEcimal, 'Wrong city rate');
            Assert.AreEqual(County, SalesTaxSetupWizardPage.County.Value, 'Wrong county');
            Assert.AreEqual(CountyRate, SalesTaxSetupWizardPage."County Rate".AsDEcimal, 'Wrong county value');
            Assert.AreEqual(State, SalesTaxSetupWizardPage.State.Value, 'Wrong state');
            Assert.AreEqual(StateRate, SalesTaxSetupWizardPage."State Rate".AsDEcimal, 'Wrong state rate');
        end else begin
            SalesTaxSetupWizardPage.City.SetValue(City);
            SalesTaxSetupWizardPage."City Rate".SetValue(CityRate);
            SalesTaxSetupWizardPage.County.SetValue(County);
            SalesTaxSetupWizardPage."County Rate".SetValue(CountyRate);
            SalesTaxSetupWizardPage.State.SetValue(State);
            SalesTaxSetupWizardPage."State Rate".SetValue(StateRate);
        end;

        SalesTaxSetupWizardPage.ActionNextStep.Invoke; // Goto Tax Area Code page
        if AreaCode <> '' then
            if ValidateMode then
                Assert.AreEqual(AreaCode, SalesTaxSetupWizardPage."Tax Area Code".Value, 'Wrong area code')
            else
                SalesTaxSetupWizardPage."Tax Area Code".SetValue(AreaCode);

        SalesTaxSetupWizardPage.ActionNextStep.Invoke; // Goto 'update related tables' page
        SalesTaxSetupWizardPage.Finish.Invoke;
    end;

    local procedure ValidateTaxArea(AreaCode: Code[20]; SalesTaxRate: Decimal)
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TotalSalesTaxRate: Decimal;
    begin
        TaxArea.Get(AreaCode);
        TaxAreaLine.SetRange("Tax Area", TaxArea.Code);
        Assert.AreEqual(3, TaxAreaLine.Count, 'Wrong number of Tax Area Lines');
        TaxAreaLine.FindSet();
        TotalSalesTaxRate := 0;
        repeat
            TaxDetail.SetRange("Tax Group Code", SalesTaxSetupWizard.GetDefaultTaxGroupCode);
            TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
            TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
            TaxDetail.FindLast();
            TotalSalesTaxRate += TaxDetail."Tax Below Maximum";
        until TaxAreaLine.Next() = 0;
        Assert.AreEqual(SalesTaxRate, TotalSalesTaxRate, 'Wrong sales tax rate sum');
    end;
}

