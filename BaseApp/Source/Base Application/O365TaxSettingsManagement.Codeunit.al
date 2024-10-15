codeunit 10150 "O365 Tax Settings Management"
{

    trigger OnRun()
    begin
    end;

    var
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        PercentTxt: Label '%';
        DiscardWithNoNameOptionQst: Label 'Keep editing,Discard';
        DiscardWithNoNameInstructionTxt: Label 'City or state name must be filled in.';
        UpdateOtherAreasOptionQst: Label 'Continue,Undo';
        UpdateOtherAreasInstructionTxt: Label 'Updating a city or state tax rate will affect all customers using the rate.';
#if not CLEAN20        
        CannotSetPSTRateErr: Label 'It is not possible to set the PST Rate on the %1 tax area.', Comment = '%1 - Code of tax area in Canada. E.g. NB,AB...';
#endif
        DefaultTxt: Label 'DEFAULT', Comment = 'Please translate all caps with max length 20 chars.';
        TemplateTaxAreaDoesNotExistMsg: Label 'Customer template tax area %1 does not exist.', Locked = true;
        TemplateInvoicingCategoryTxt: Label 'AL Inv template', Locked = true;
        CannotRemoveDefaultTaxAreaErr: Label 'You cannot remove the default tax area.';

    procedure IsDefaultTaxAreaAPI(TaxAreaCode: Code[20]): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get then
            exit(CompanyInformation."Tax Area Code" = TaxAreaCode);

        exit(TaxAreaCode = DefaultTxt);
    end;

    procedure UpdateSalesTaxSetupWizard(TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary)
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        if SalesTaxSetupWizard.Get then
            SalesTaxSetupWizard.Delete();

        SalesTaxSetupWizard := TempSalesTaxSetupWizard;
        SalesTaxSetupWizard.Insert(true);
    end;

    procedure InitializeTaxSetupFromTaxAreaLinesForUS(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst() then
                    if TaxJurisdiction."Report-to Jurisdiction" = TaxJurisdiction.Code then begin
                        TempSalesTaxSetupWizard.State := CopyStr(TaxJurisdiction.Code, 1, MaxStrLen(TempSalesTaxSetupWizard.State));
                        TempSalesTaxSetupWizard."State Rate" += GetTaxRate(TaxJurisdiction.Code)
                    end else begin
                        TempSalesTaxSetupWizard.City := TaxJurisdiction.GetName;
                        TempSalesTaxSetupWizard."City Rate" += GetTaxRate(TaxJurisdiction.Code)
                    end;
            until TaxAreaLine.Next() = 0;
    end;


#if not CLEAN21
    [Obsolete('Replaced with GetProvinceFullLength.', '21.0')]
    procedure GetProvince(JurisdictionCode: Code[10]): Text[50]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if not TaxJurisdiction.Get(JurisdictionCode) then
            exit('');

        exit(TaxJurisdiction.GetDescriptionInCurrentLanguage);
    end;
#endif

    procedure GetProvinceFullLength(JurisdictionCode: Code[10]): Text[100]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if not TaxJurisdiction.Get(JurisdictionCode) then
            exit('');
        exit(TaxJurisdiction.GetDescriptionInCurrentLanguageFullLength());
    end;

    procedure GetTaxRate(JurisdictionCode: Code[10]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        if GetDefaultTaxDetail(TaxDetail, JurisdictionCode) then
            exit(TaxDetail."Tax Below Maximum");
    end;

    procedure GetDefaultTaxDetail(var TaxDetail: Record "Tax Detail"; JurisdictionCode: Code[10]): Boolean
    begin
        TaxDetail.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        TaxDetail.SetRange("Tax Group Code", TaxableCodeTxt);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        if TaxDetail.FindLast() then
            exit(true);

        TaxDetail.Reset();
        exit(false);
    end;

    procedure GetDefaultTaxArea(): Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get then
            exit(CompanyInformation."Tax Area Code");
    end;

    [Scope('OnPrem')]
    procedure GenerateTaxAreaDescription(TotalRate: Decimal; City: Text; State: Code[10]): Text[100]
    var
        DummyTaxArea: Record "Tax Area";
        Result: Text;
    begin
        Result := Format(TotalRate) + PercentTxt;

        case true of
            (State <> '') and (City <> ''):
                Result := StrSubstNo('%1, %2, %3', City, State, Result);
            City <> '':
                Result := StrSubstNo('%1, %2', City, Result);
            State <> '':
                Result := StrSubstNo('%1, %2', State, Result);
        end;

        exit(CopyStr(Result, 1, MaxStrLen(DummyTaxArea.Description)));
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxAreaDescriptionsWithSameStateOrCity(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard")
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TempSalesTaxSetupWizard2: Record "Sales Tax Setup Wizard" temporary;
        SalesLine: Record "Sales Line";
    begin
        TaxAreaLine.SetFilter(
          "Tax Jurisdiction Code", '%1|%2', SalesTaxSetupWizard.State, GetCityCodeFromSalesTaxSetup(SalesTaxSetupWizard));

        // For each tax area pair using the modified state or city, regenerate the tax area description
        // Also update the invoice amount for all existing invoices using these tax areas
        if TaxAreaLine.FindSet() then
            repeat
                if TaxArea.Get(TaxAreaLine."Tax Area") then begin
                    TempSalesTaxSetupWizard2.Init();
                    TempSalesTaxSetupWizard2."Tax Area Code" := TaxArea.Code;
                    InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard2);

                    TaxArea.Description := GenerateTaxAreaDescription(
                        TempSalesTaxSetupWizard2."City Rate" + TempSalesTaxSetupWizard2."State Rate",
                        TempSalesTaxSetupWizard2.City, TempSalesTaxSetupWizard2.State);
                    TaxArea.Modify(true);

                    SalesLine.SetRange("Tax Area Code", TaxArea.Code);
                    if SalesLine.FindSet() then
                        repeat
                            SalesLine.UpdateAmounts;
                            SalesLine.Modify(true);
                        until SalesLine.Next() = 0;
                end;
            until TaxAreaLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CountTaxAreaLinesWithJurisdictionCode(JurisdictionCode: Code[10]): Integer
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        exit(TaxAreaLine.Count);
    end;

    [Scope('OnPrem')]
    procedure HasBeenModifiedUS(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard"): Boolean
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
    begin
        TempSalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard."Tax Area Code";
        InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);

        if (TempSalesTaxSetupWizard.City <> SalesTaxSetupWizard.City) or
           (TempSalesTaxSetupWizard."City Rate" <> SalesTaxSetupWizard."City Rate") or
           (TempSalesTaxSetupWizard.State <> SalesTaxSetupWizard.State) or
           (TempSalesTaxSetupWizard."State Rate" <> SalesTaxSetupWizard."State Rate")
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure OtherTaxAreasWithSameStateOrCityExist(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard") DoOtherTaxAreasExist: Boolean
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        CityCode: Code[10];
        ExistingTaxAreaLines: Integer;
    begin
        TempSalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard."Tax Area Code";
        InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);

        ExistingTaxAreaLines := CountTaxAreaLinesWithJurisdictionCode(SalesTaxSetupWizard.State);

        // Only if the state name is unchanged, expect to find one tax area line (for the existing record)
        if (SalesTaxSetupWizard.State <> '') and (SalesTaxSetupWizard.State = TempSalesTaxSetupWizard.State) then
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 1)
        else
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 0);

        CityCode := GetCityCodeFromSalesTaxSetup(SalesTaxSetupWizard);
        ExistingTaxAreaLines := CountTaxAreaLinesWithJurisdictionCode(CityCode);

        // Only if the city name is unchanged, expect to find one tax area line (for the existing record)
        if (SalesTaxSetupWizard.City <> '') and (SalesTaxSetupWizard.City = TempSalesTaxSetupWizard.City) then
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 1)
        else
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 0);
    end;

    local procedure AssignTaxAreaToCustomersAndSalesLines(TaxAreaCode: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        OldSalesLine: Record "Sales Line";
    begin
        Customer.SetFilter("Tax Area Code", '%1', '');
        if not Customer.IsEmpty() then
            Customer.ModifyAll("Tax Area Code", TaxAreaCode);

        SalesLine.LockTable();
        SalesLine.SetRange("Tax Area Code", TaxAreaCode);
        SalesLine.SetFilter(Quantity, '<>%1', 0);
        SalesLine.SetFilter("Unit Price", '<>%1', 0);
        if SalesLine.FindSet() then
            repeat
                OldSalesLine := SalesLine;
                SalesLine.UpdateAmounts;
                if (OldSalesLine."Amount Including VAT" <> SalesLine."Amount Including VAT") or
                   (OldSalesLine.Amount <> SalesLine.Amount)
                then
                    SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure StoreTaxSettingsForUS(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary; TaxRateDescription: Text[100]): Boolean
    var
        TaxArea: Record "Tax Area";
        ResponseOptNoName: Option Cancel,KeepEditing,Discard;
        ResponseOptUpdate: Option Cancel,Continue,Undo;
    begin
        if not HasBeenModifiedUS(TempSalesTaxSetupWizard) then
            exit(true);

        if GuiAllowed then
            with TempSalesTaxSetupWizard do
                if (("City Rate" <> 0) and (City = '')) or (("State Rate" <> 0) and (State = '')) then begin
                    ResponseOptNoName := StrMenu(DiscardWithNoNameOptionQst, 0, DiscardWithNoNameInstructionTxt);
                    exit(ResponseOptNoName = ResponseOptNoName::Discard);
                end;

        if GuiAllowed then
            if OtherTaxAreasWithSameStateOrCityExist(TempSalesTaxSetupWizard) then begin
                ResponseOptUpdate := StrMenu(UpdateOtherAreasOptionQst, 0, UpdateOtherAreasInstructionTxt);
                if ResponseOptUpdate = ResponseOptUpdate::Cancel then
                    exit(false);
                if ResponseOptUpdate = ResponseOptUpdate::Undo then
                    exit(true);
            end;

        UpdateTaxAreaNameUS(TempSalesTaxSetupWizard);
        if TempSalesTaxSetupWizard."Tax Area Code" <> '' then begin
            TempSalesTaxSetupWizard.StoreSalesTaxSetup;
            if TaxArea.Get(TempSalesTaxSetupWizard."Tax Area Code") then begin
                TaxArea.Validate(Description, TaxRateDescription);
                TaxArea.Modify();
            end;
            AssignTaxAreaToCustomersAndSalesLines(TempSalesTaxSetupWizard."Tax Area Code");
        end;

        UpdateTaxAreaDescriptionsWithSameStateOrCity(TempSalesTaxSetupWizard);

        exit(true);
    end;

#if not CLEAN20    
    local procedure StoreTaxSettingsForCA(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary; var TempNativeAPITaxSetup: Record "Native - API Tax Setup" temporary)
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        if TempSalesTaxSetupWizard."Tax Area Code" = '' then
            exit;

        TempSalesTaxSetupWizard.SetTaxArea(TaxArea);
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if not TaxAreaLine.IsEmpty() then
            TaxAreaLine.DeleteAll();

        if TempNativeAPITaxSetup."GST or HST Code" <> '' then begin
            TempSalesTaxSetupWizard.SetTaxJurisdiction(
              TempNativeAPITaxSetup."GST or HST Code", TempNativeAPITaxSetup."GST or HST Description", GetCARegionCode());
            TempSalesTaxSetupWizard.SetTaxAreaLine(TaxArea, TempNativeAPITaxSetup."GST or HST Code");
            TempSalesTaxSetupWizard.SetTaxDetail(
              TempNativeAPITaxSetup."GST or HST Code", TaxableCodeTxt, TempNativeAPITaxSetup."GST or HST Rate");
        end;
        if TempNativeAPITaxSetup."PST Code" <> '' then begin
            TempSalesTaxSetupWizard.SetTaxJurisdiction(
              TempNativeAPITaxSetup."PST Code", TempNativeAPITaxSetup."PST Description", TempNativeAPITaxSetup."PST Code");
            TempSalesTaxSetupWizard.SetTaxAreaLine(TaxArea, TempNativeAPITaxSetup."PST Code");
            TempSalesTaxSetupWizard.SetTaxDetail(TempNativeAPITaxSetup."PST Code", TaxableCodeTxt, TempNativeAPITaxSetup."PST Rate");
        end else
            if TempNativeAPITaxSetup."PST Rate" <> 0 then
                Error(CannotSetPSTRateErr, TempNativeAPITaxSetup.Code);
    end;
#endif

    [Scope('OnPrem')]
    procedure UpdateTaxAreaNameUS(var SalesTaxSetupWizard: Record "Sales Tax Setup Wizard")
    begin
        if SalesTaxSetupWizard."Tax Area Code" = '' then
            SalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard.GenerateTaxAreaCode;
    end;

#if not CLEAN20
    [EventSubscriber(ObjectType::Table, Database::"Native - API Tax Setup", 'OnLoadSalesTaxSettings', '', false, false)]
    local procedure HandleOnLoadSalesTaxSettings(var NativeAPITaxSetup: Record "Native - API Tax Setup"; var TempTaxAreaBuffer: Record "Tax Area Buffer" temporary)
    var
        CompanyInformation: Record "Company Information";
        IsCanada: Boolean;
    begin
        if not TempTaxAreaBuffer.FindFirst() then
            exit;

        IsCanada := CompanyInformation.IsCanada;

        repeat
            NativeAPITaxSetup.Init();
            NativeAPITaxSetup.TransferFields(TempTaxAreaBuffer, true);
            LoadSalesTaxSettingsFromTaxArea(NativeAPITaxSetup, IsCanada);
            NativeAPITaxSetup.Insert(true);
        until TempTaxAreaBuffer.Next() = 0;
    end;

    local procedure LoadSalesTaxSettingsFromTaxArea(var NativeAPITaxSetup: Record "Native - API Tax Setup"; IsCanada: Boolean)
    var
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
    begin
        NativeAPITaxSetup.Default := O365TaxSettingsManagement.IsDefaultTaxAreaAPI(NativeAPITaxSetup.Code);

        if IsCanada then
            LoadCanadianTaxSettings(NativeAPITaxSetup)
        else
            LoadUsTaxSettings(NativeAPITaxSetup);
    end;

    local procedure LoadCanadianTaxSettings(var NativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
    begin
        NativeAPITaxSetup."Country/Region" := NativeAPITaxSetup."Country/Region"::CA;
        TempSalesTaxSetupWizard.Initialize();
        TempSalesTaxSetupWizard."Tax Area Code" := DelChr(NativeAPITaxSetup.Code, '<>', ' ');
        InitializeTaxSetupFromTaxAreaLinesForCA(TempSalesTaxSetupWizard, NativeAPITaxSetup);
        NativeAPITaxSetup."Total Tax Percentage" := NativeAPITaxSetup."PST Rate" + NativeAPITaxSetup."GST or HST Rate";
    end;

    local procedure LoadUsTaxSettings(var NativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
    begin
        NativeAPITaxSetup."Country/Region" := NativeAPITaxSetup."Country/Region"::US;

        TempSalesTaxSetupWizard.Initialize();
        TempSalesTaxSetupWizard."Tax Area Code" := DelChr(NativeAPITaxSetup.Code, '<>', ' ');
        InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);
        NativeAPITaxSetup.City := TempSalesTaxSetupWizard.City;
        NativeAPITaxSetup."City Rate" := TempSalesTaxSetupWizard."City Rate";
        NativeAPITaxSetup.State := TempSalesTaxSetupWizard.State;
        NativeAPITaxSetup."State Rate" := TempSalesTaxSetupWizard."State Rate";
        NativeAPITaxSetup."Total Tax Percentage" := NativeAPITaxSetup."State Rate" + NativeAPITaxSetup."City Rate";
        NativeAPITaxSetup.Description :=
          GenerateTaxAreaDescription(NativeAPITaxSetup."Total Tax Percentage", NativeAPITaxSetup.City, NativeAPITaxSetup.State)
    end;
#endif

    [Scope('OnPrem')]
    procedure AssignDefaultTaxArea(NewTaxAreaCode: Code[20])
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
#if not CLEAN18
        MarketingSetup: Record "Marketing Setup";
        CustomerTemplate: Record "Customer Template";
#endif
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Tax Area Code"), NewTaxAreaCode);

#if not CLEAN18
        if MarketingSetup.Get then begin
            CustomerTemplate.LockTable();
            if CustomerTemplate.Get(MarketingSetup."Cust. Template Company Code") then begin
                CustomerTemplate.Validate("Tax Area Code", NewTaxAreaCode);
                CustomerTemplate.Modify(true);
            end;

            if CustomerTemplate.Get(MarketingSetup."Cust. Template Person Code") then begin
                CustomerTemplate.Validate("Tax Area Code", NewTaxAreaCode);
                CustomerTemplate.Modify(true);
            end;
        end;
#endif
        CompanyInformation.LockTable();
        if CompanyInformation.Get then
            if CompanyInformation."Tax Area Code" <> NewTaxAreaCode then begin
                CompanyInformation.Validate("Tax Area Code", NewTaxAreaCode);
                CompanyInformation.Modify();
            end;
    end;

#if not CLEAN20
    local procedure InitializeTaxSetupFromTaxAreaLinesForCA(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary; var NativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst() then
                    if TaxJurisdiction."Report-to Jurisdiction" = GetCARegionCode() then begin
                        NativeAPITaxSetup."GST or HST Code" := TaxJurisdiction.Code;
                        NativeAPITaxSetup."GST or HST Description" := CopyStr(GetProvinceFullLength(NativeAPITaxSetup."GST or HST Code"), 1, 50);
                        NativeAPITaxSetup."GST or HST Rate" := GetTaxRate(NativeAPITaxSetup."GST or HST Code")
                    end else begin
                        NativeAPITaxSetup."PST Code" := TaxJurisdiction.Code;
                        NativeAPITaxSetup."PST Description" := CopyStr(GetProvinceFullLength(NativeAPITaxSetup."PST Code"), 1, 50);
                        NativeAPITaxSetup."PST Rate" := GetTaxRate(NativeAPITaxSetup."PST Code")
                    end;
            until TaxAreaLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Native - API Tax Setup", 'OnSaveSalesTaxSettings', '', false, false)]
    local procedure HandleOnSaveSalesTaxSettings(var NewNativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        CompanyInformation: Record "Company Information";
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        TaxArea: Record "Tax Area";
        IsCanada: Boolean;
    begin
        TempSalesTaxSetupWizard.Initialize();
        TempSalesTaxSetupWizard."Tax Area Code" := DelChr(NewNativeAPITaxSetup.Code, '<>', ' ');

        IsCanada := CompanyInformation.IsCanada;

        if IsCanada then
            StoreTaxSettingsForCA(TempSalesTaxSetupWizard, NewNativeAPITaxSetup)
        else begin
            TempSalesTaxSetupWizard.City := NewNativeAPITaxSetup.City;
            TempSalesTaxSetupWizard."City Rate" := NewNativeAPITaxSetup."City Rate";
            TempSalesTaxSetupWizard.State := NewNativeAPITaxSetup.State;
            TempSalesTaxSetupWizard."State Rate" := NewNativeAPITaxSetup."State Rate";
            NewNativeAPITaxSetup.Description :=
              GenerateTaxAreaDescription(NewNativeAPITaxSetup."Total Tax Percentage", NewNativeAPITaxSetup.City, NewNativeAPITaxSetup.State);
            UpdateSalesTaxSetupWizard(TempSalesTaxSetupWizard);
            StoreTaxSettingsForUS(TempSalesTaxSetupWizard, NewNativeAPITaxSetup.Description);
        end;

        if NewNativeAPITaxSetup.Default then
            AssignDefaultTaxArea(TempSalesTaxSetupWizard."Tax Area Code");

        if not IsNullGuid(NewNativeAPITaxSetup.Id) then
            exit;

        TaxArea.Get(TempSalesTaxSetupWizard."Tax Area Code");
        NewNativeAPITaxSetup.Id := TaxArea.Id;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Native - API Tax Setup", 'OnCanDeleteTaxSetup', '', false, false)]
    local procedure HandleOnCanDeleteTaxSetup(var PreventDeletion: Boolean; var NativeAPITaxSetup: Record "Native - API Tax Setup")
    begin
        if PreventDeletion then
            exit;

        if NativeAPITaxSetup."Country/Region" <> NativeAPITaxSetup."Country/Region"::US then
            PreventDeletion := true;
    end;
#endif

    procedure GetTotalTaxRate(TaxAreaCode: Code[20]) TaxRate: Decimal
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.FindSet() then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst() then
                    TaxRate := TaxRate + GetTaxRate(TaxJurisdiction.Code)
            until TaxAreaLine.Next() = 0;
    end;

#if not CLEAN20
    local procedure GetCARegionCode(): Code[10]
    begin
        exit('CA');
    end;
#endif
    [Scope('OnPrem')]
    procedure IsTaxSet(TaxAreaCode: Code[20]): Boolean
    begin
        exit(GetTotalTaxRate(TaxAreaCode) <> 0);
    end;

    local procedure GetCityCodeFromSalesTaxSetup(var SalesTaxSetupWizard: Record "Sales Tax Setup Wizard"): Code[10]
    begin
        exit(CopyStr(DelChr(SalesTaxSetupWizard.City, '<>', ' '), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure CheckCustomerTemplateTaxIntegrity()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        DummyCustomer: Record Customer;
        TaxArea: Record "Tax Area";
        CompanyInformation: Record "Company Information";
    begin
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.SetRange(Enabled, true);

        if ConfigTemplateHeader.FindSet() then
            repeat
                ConfigTemplateLine.LockTable();
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Table ID", DATABASE::Customer);
                ConfigTemplateLine.SetRange("Field ID", DummyCustomer.FieldNo("Tax Area Code"));

                if ConfigTemplateLine.FindFirst() then
                    if not TaxArea.Get(ConfigTemplateLine."Default Value") then begin
                        OnBeforeSanitizeCustomerTemplateTax(ConfigTemplateLine);
                        if CompanyInformation.Get then
                            if TaxArea.Get(CompanyInformation."Tax Area Code") then begin
                                ConfigTemplateLine.Validate("Default Value", CompanyInformation."Tax Area Code");
                                ConfigTemplateLine.Modify(true);
                            end;
                    end;
            until ConfigTemplateHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSanitizeCustomerTemplateTax(ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O365 Tax Settings Management", 'OnBeforeSanitizeCustomerTemplateTax', '', true, true)]
    local procedure LogWarningIfTemplateIncorrect(ConfigTemplateLine: Record "Config. Template Line")
    begin
        Session.LogMessage('00001OQ', StrSubstNo(TemplateTaxAreaDoesNotExistMsg, ConfigTemplateLine."Default Value"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TemplateInvoicingCategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure DeleteTaxArea(var TaxArea: Record "Tax Area"): Boolean
    begin
        if IsDefaultTaxAreaAPI(TaxArea.Code) then
            Error(CannotRemoveDefaultTaxAreaErr);
        exit(TaxArea.Delete(true));
    end;
}
