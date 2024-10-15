page 10350 "BC O365 Tax Settings Card"
{
    Caption = 'Tax Rate';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    SourceTable = "Tax Area";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control1020019)
            {
                ShowCaption = false;
                Visible = NOT IsCanada;
                group(Control1020001)
                {
                    InstructionalText = 'Enter your city tax information';
                    ShowCaption = false;
                    field(City; TempSalesTaxSetupWizard.City)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the tax rate.';

                        trigger OnValidate()
                        begin
                            UpdateDescription;
                        end;
                    }
                    field(CityRate; TempSalesTaxSetupWizard."City Rate")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        BlankZero = true;
                        Caption = 'City Rate';
                        MinValue = 0;
                        ToolTip = 'Specifies the city rate.';

                        trigger OnValidate()
                        begin
                            if TempSalesTaxSetupWizard.City <> '' then begin
                                UpdateTotalTaxRate;
                                UpdateDescription;
                            end;
                        end;
                    }
                }
                group(Control1020006)
                {
                    InstructionalText = 'Enter your state tax information';
                    ShowCaption = false;
                    field(State; TempSalesTaxSetupWizard.State)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'State';
                        ToolTip = 'Specifies the state of the tax rate.';

                        trigger OnValidate()
                        begin
                            UpdateDescription;
                        end;
                    }
                    field(StateRate; TempSalesTaxSetupWizard."State Rate")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        BlankZero = true;
                        Caption = 'State Rate';
                        MinValue = 0;
                        ToolTip = 'Specifies the state rate.';

                        trigger OnValidate()
                        begin
                            if TempSalesTaxSetupWizard.State <> '' then begin
                                UpdateTotalTaxRate;
                                UpdateDescription;
                            end;
                        end;
                    }
                }
            }
            group(Control1020017)
            {
                ShowCaption = false;
                Visible = IsCanada;
                group(Control1020012)
                {
                    ShowCaption = false;
                    Visible = GSTorHSTVisible;
                    field(GSTorHST; GSTorHST)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'GST/HST';
                        Editable = false;
                        TableRelation = "Tax Jurisdiction" WHERE("Country/Region" = CONST(CA),
                                                                  "Report-to Jurisdiction" = CONST('CA'));

                        trigger OnValidate()
                        begin
                            GSTorHSTCode := CopyStr(GSTorHST, 1, MaxStrLen(GSTorHSTCode));
                            GSTorHST := CopyStr(GetProvince(GSTorHSTCode), 1, MaxStrLen(GSTorHST));
                            GSTorHSTrate := O365TaxSettingsManagement.GetTaxRate(GSTorHSTCode)
                        end;
                    }
                    field(GSTorHSTrate; GSTorHSTrate)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'GST/HST Rate';
                        DecimalPlaces = 1 : 3;
                        Editable = (GSTorHST <> '');
                    }
                }
                group(Control1020018)
                {
                    ShowCaption = false;
                    Visible = PSTVisible;
                    field(PST; PST)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'PST';
                        Editable = false;
                        TableRelation = "Tax Jurisdiction" WHERE("Country/Region" = CONST(CA),
                                                                  "Report-to Jurisdiction" = FILTER(<> 'CA'));

                        trigger OnValidate()
                        begin
                            PSTCode := CopyStr(PST, 1, MaxStrLen(PSTCode));
                            PST := CopyStr(GetProvince(PSTCode), 1, MaxStrLen(GSTorHST));
                            PSTrate := O365TaxSettingsManagement.GetTaxRate(PSTCode)
                        end;
                    }
                    field(PSTrate; PSTrate)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'PST Rate';
                        DecimalPlaces = 1 : 3;
                        Editable = (PST <> '');
                    }
                }
            }
            field(Total; TotalRate)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Total rate';
                DecimalPlaces = 1 : 3;
                Editable = false;
                ToolTip = 'Specifies the total tax rate.';
            }
            field(Default; DefaultTxt)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                Enabled = NOT IsDefaultArea;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    if (TempSalesTaxSetupWizard.City = '') and (TempSalesTaxSetupWizard.State = '') and not IsCanada then
                        Error(CityOrStateMustBeSpecifiedErr);
                    StoreTaxSettings;
                    O365TaxSettingsManagement.UpdateSalesTaxSetupWizard(TempSalesTaxSetupWizard);
                    DefaultTxt := ThisIsDefaultTxt;
                    IsDefaultArea := true;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RemoveTaxRate)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Remove tax rate';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Removes the current tax rate.';
                Visible = NOT IsCanada;

                trigger OnAction()
                var
                    TaxArea: Record "Tax Area";
                begin
                    // Page runs on a temporary record: delete the real record and then the temporary one
                    if TaxArea.Get(Code) then
                        Deleted := O365TaxSettingsManagement.DeleteTaxArea(TaxArea);

                    if Deleted then
                        if O365TaxSettingsManagement.DeleteTaxArea(Rec) then;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetDefaults;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ResponseOpt: Option ,KeepEditing,Discard;
    begin
        if Deleted then
            exit;
        with TempSalesTaxSetupWizard do
            if (("City Rate" <> 0) and (City = '')) or (("State Rate" <> 0) and (State = '')) then begin
                ResponseOpt := StrMenu(DiscardWithNoNameOptionQst, 3, DiscardWithNoNameInstructionTxt);
                exit(ResponseOpt = ResponseOpt::Discard);
            end;

        exit(StoreTaxSettings);
    end;

    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
        PSTCode: Code[10];
        GSTorHSTCode: Code[10];
        GSTorHST: Text[50];
        PST: Text[50];
        TaxRateDescription: Text[50];
        DefaultTxt: Text;
        GSTorHSTrate: Decimal;
        PSTrate: Decimal;
        TotalRate: Decimal;
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        CATxt: Label 'CA', Locked = true;
        PSTVisible: Boolean;
        GSTorHSTVisible: Boolean;
        ThisIsDefaultTxt: Label 'This is the default tax rate';
        SetAsDefaultTxt: Label 'Set as default tax rate';
        IsDefaultArea: Boolean;
        IsCanada: Boolean;
        PercentTxt: Label '%';
        DiscardWithNoNameOptionQst: Label 'Keep editing,Discard';
        DiscardWithNoNameInstructionTxt: Label 'City or state name must be filled in.';
        Deleted: Boolean;
        CityOrStateMustBeSpecifiedErr: Label 'City or state name must be filled in.';

    local procedure SetDefaults()
    begin
        InitializeDefaultTaxArea;
        InitializeDefaultCountryCode;
        TempSalesTaxSetupWizard.Initialize;
        TempSalesTaxSetupWizard."Tax Area Code" := DelChr(Code, '<>', ' ');
        InitializeTaxAreaLines;
        if not IsCanada then
            UpdateDescription;
    end;

    local procedure InitializeDefaultTaxArea()
    begin
        IsDefaultArea := O365TaxSettingsManagement.IsDefaultTaxAreaAPI(Code);
        if IsDefaultArea then
            DefaultTxt := ThisIsDefaultTxt
        else
            DefaultTxt := SetAsDefaultTxt;
    end;

    local procedure InitializeDefaultCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.IsCanada then begin
            IsCanada := true;
            "Country/Region" := "Country/Region"::CA;
        end else
            "Country/Region" := "Country/Region"::US;
    end;

    local procedure InitializeTaxAreaLines()
    begin
        if TempSalesTaxSetupWizard."Tax Area Code" <> '' then begin
            if IsCanada then
                InitializeTaxSetupFromTaxAreaLinesForCA
            else
                O365TaxSettingsManagement.InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);
        end;
        UpdateTotalTaxRate;
    end;

    local procedure InitializeTaxSetupFromTaxAreaLinesForCA()
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        ClearFieldsForCA;
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if TaxAreaLine.FindSet then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst then
                    if TaxJurisdiction."Report-to Jurisdiction" = CATxt then begin
                        GSTorHSTCode := TaxJurisdiction.Code;
                        GSTorHST := GetProvince(GSTorHSTCode);
                        GSTorHSTrate := O365TaxSettingsManagement.GetTaxRate(GSTorHSTCode)
                    end else begin
                        PSTCode := TaxJurisdiction.Code;
                        PST := GetProvince(PSTCode);
                        PSTrate := O365TaxSettingsManagement.GetTaxRate(PSTCode)
                    end;
            until TaxAreaLine.Next = 0;
        GSTorHSTVisible := GSTorHST <> '';
        PSTVisible := PST <> '';
    end;

    local procedure ClearFieldsForCA()
    begin
        Clear(PSTCode);
        Clear(PST);
        Clear(PSTrate);
        Clear(GSTorHST);
        Clear(GSTorHSTCode);
        Clear(GSTorHSTrate);
    end;

    local procedure GetProvince(JurisdictionCode: Code[10]): Text[50]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if not TaxJurisdiction.Get(JurisdictionCode) then
            exit('');

        exit(TaxJurisdiction.GetDescriptionInCurrentLanguage);
    end;

    local procedure UpdateTotalTaxRate()
    begin
        if IsCanada then
            TotalRate := GSTorHSTrate + PSTrate
        else
            TotalRate := TempSalesTaxSetupWizard."City Rate" + TempSalesTaxSetupWizard."State Rate";
    end;

    local procedure StoreTaxSettings() CanClosePage: Boolean
    begin
        CanClosePage := true;

        if IsCanada then
            StoreTaxSettingsForCA
        else
            CanClosePage := O365TaxSettingsManagement.StoreTaxSettingsForUS(TempSalesTaxSetupWizard, TaxRateDescription);

        if IsDefaultArea then
            O365TaxSettingsManagement.AssignDefaultTaxArea(TempSalesTaxSetupWizard."Tax Area Code");
    end;

    local procedure StoreTaxSettingsForCA()
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        if TempSalesTaxSetupWizard."Tax Area Code" = '' then
            exit;
        TempSalesTaxSetupWizard.SetTaxArea(TaxArea);
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if not TaxAreaLine.IsEmpty then
            TaxAreaLine.DeleteAll();
        if GSTorHSTCode <> '' then begin
            TempSalesTaxSetupWizard.SetTaxJurisdiction(GSTorHSTCode, GSTorHST, CATxt);
            TempSalesTaxSetupWizard.SetTaxAreaLine(TaxArea, GSTorHSTCode);
            TempSalesTaxSetupWizard.SetTaxDetail(GSTorHSTCode, TaxableCodeTxt, GSTorHSTrate);
        end;
        if PSTCode <> '' then begin
            TempSalesTaxSetupWizard.SetTaxJurisdiction(PSTCode, PST, PSTCode);
            TempSalesTaxSetupWizard.SetTaxAreaLine(TaxArea, PSTCode);
            TempSalesTaxSetupWizard.SetTaxDetail(PSTCode, TaxableCodeTxt, PSTrate);
        end;
    end;

    local procedure UpdateDescription()
    begin
        TaxRateDescription := GenerateDescription;
    end;

    local procedure GenerateDescription(): Text[50]
    var
        Result: Text;
    begin
        Result := Format(TotalRate);
        Result := Result + PercentTxt;
        if StrLen(TempSalesTaxSetupWizard.State) > 0 then
            Result := StrSubstNo('%1%2%3', TempSalesTaxSetupWizard.State, ', ', Result);
        if StrLen(TempSalesTaxSetupWizard.City) > 0 then
            Result := StrSubstNo('%1%2%3', TempSalesTaxSetupWizard.City, ', ', Result);
        Result := CopyStr(Result, 1, MaxStrLen(Description));
        exit(Result);
    end;
}

