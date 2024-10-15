page 10807 "Sales Tax Setup Wizard"
{
    Caption = 'Sales Tax Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Sales Tax Setup Wizard";

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT (Step = Step::Done);
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND (Step = Step::Done);
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = Step = Step::Intro;
                group("Para1.1")
                {
                    Caption = 'Welcome to Sales Tax Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can create a default tax area code to assign to customers and vendors so that sales tax is automatically calculated in sales or purchase documents.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to create a default tax group.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = Step = Step::TaxGroupCreated;
                group("Para2.1")
                {
                    Caption = 'Default tax group created';
                    group("Para2.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Tax Group of TAXABLE has been created. You will need to assign this group to your items that are taxable.';
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = Step = Step::TaxAccounts;
                group("Para3.1")
                {
                    Caption = 'Select which accounts you want to use with this tax group.';
                    field("Tax Account (Sales)"; Rec."Tax Account (Sales)")
                    {
                        ApplicationArea = SalesTax;

                        trigger OnValidate()
                        begin
                            NextEnabled := ("Tax Account (Sales)" <> '') or ("Tax Account (Purchases)" <> '');
                        end;
                    }
                    field("Tax Account (Purchases)"; Rec."Tax Account (Purchases)")
                    {
                        ApplicationArea = SalesTax;

                        trigger OnValidate()
                        begin
                            NextEnabled := ("Tax Account (Sales)" <> '') or ("Tax Account (Purchases)" <> '');
                        end;
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = Step = Step::TaxRates;
                group("Para4.1")
                {
                    Caption = 'Enter the tax information for your area; then click next.';
                    group("Para4.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Enter your city tax information';
                        Visible = CityAndCountyVisible;
                        field(City; City)
                        {
                            ApplicationArea = SalesTax;
                        }
                        field("City Rate"; Rec."City Rate")
                        {
                            ApplicationArea = SalesTax;

                            trigger OnValidate()
                            begin
                                Validate(City);
                            end;
                        }
                    }
                    group("Para4.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'Enter your county tax information';
                        //The GridLayout property is only supported on controls of type Grid
                        //GridLayout = Rows;
                        Visible = CityAndCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = SalesTax;
                        }
                        field("County Rate"; Rec."County Rate")
                        {
                            ApplicationArea = SalesTax;

                            trigger OnValidate()
                            begin
                                Validate(County);
                            end;
                        }
                    }
                    group("Para4.1.3")
                    {
                        Caption = '';
                        InstructionalText = 'Enter your state tax information';
                        //The GridLayout property is only supported on controls of type Grid
                        //GridLayout = Rows;
                        field(State; State)
                        {
                            ApplicationArea = SalesTax;
                        }
                        field("State Rate"; Rec."State Rate")
                        {
                            ApplicationArea = SalesTax;

                            trigger OnValidate()
                            begin
                                Validate(State);
                            end;
                        }
                        field("Country/Region"; Rec."Country/Region")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                    }
                }
            }
            group(Step5)
            {
                Caption = '';
                Visible = Step = Step::TaxAreaName;
                group("Para5.1")
                {
                    Caption = 'Enter a name for your new tax area';
                    field("Tax Area Code"; Rec."Tax Area Code")
                    {
                        ApplicationArea = SalesTax;

                        trigger OnValidate()
                        begin
                            "Tax Area Code" := DelChr("Tax Area Code", '<>', ' ');
                            NextEnabled := "Tax Area Code" <> '';
                        end;
                    }
                }
            }
            group(Step6)
            {
                Caption = '';
                Visible = Step = Step::Done;
                group("Para6.1")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to create this tax area and assign your customers to the new tax area.';
                    field(AssignToCustomers; AssignToCustomers)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'To Customers';
                    }
                    field(AssignToVendors; AssignToVendors)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'To Vendors';
                    }
                    field(AssignToLocations; AssignToLocations)
                    {
                        Caption = 'To Locations';
                    }
                    field(AssignToCompanyInfo; AssignToCompanyInfo)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'To Company Information';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Back)
            {
                ApplicationArea = SalesTax;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNextStep)
            {
                ApplicationArea = SalesTax;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(Finish)
            {
                ApplicationArea = SalesTax;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    Info: ModuleInfo;
                begin
                    StoreSalesTaxSetup();
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Sales Tax Setup Wizard");
                    CurrPage.Close();
                    AssignTaxAreaCode();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Get() then begin
            Init();
            Initialize();
            Insert();
        end;
        LoadTopBanners();
        ShowIntroStep();
        SetCityAndCountyVisible();
        SetDefaultCountry();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, PAGE::"Sales Tax Setup Wizard") then
                if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Sales Tax Setup Wizard") then
                    if not Confirm(NAVNotSetUpQst, false) then
                        Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,TaxGroupCreated,TaxAccounts,TaxRates,TaxAreaName,Done;
        GeneratedName: Code[20];
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        NAVNotSetUpQst: Label 'Sales tax has not been set up.\\Are you sure that you want to exit?';
        AssignToCustomers: Boolean;
        AssignToVendors: Boolean;
        AssignToCompanyInfo: Boolean;
        AssignToLocations: Boolean;
        CityAndCountyVisible: Boolean;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::TaxGroupCreated:
                ShowTaxGroupCreatedStep();
            Step::TaxAccounts:
                ShowTaxAccountsStep();
            Step::TaxRates:
                ShowTaxRatesStep();
            Step::TaxAreaName:
                ShowTaxAreaNameStep();
            Step::Done:
                ShowDoneStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        BackEnabled := false;
    end;

    local procedure ShowTaxGroupCreatedStep()
    begin
        ResetWizardControls();
        NextEnabled := true;
    end;

    local procedure ShowTaxAccountsStep()
    begin
        ResetWizardControls();
        NextEnabled := ("Tax Account (Purchases)" <> '') or ("Tax Account (Sales)" <> '');
    end;

    local procedure ShowTaxRatesStep()
    begin
        ResetWizardControls();
    end;

    local procedure ShowTaxAreaNameStep()
    begin
        ResetWizardControls();
        if "Tax Area Code" in ['', GeneratedName] then begin
            GeneratedName := GenerateTaxAreaCode();
            "Tax Area Code" := GeneratedName;
        end;
        NextEnabled := "Tax Area Code" <> '';
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls();
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;
    end;

    local procedure AssignTaxAreaCode()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        DummyCompanyInformation: Record "Company Information";
        AssignTaxAreaToCustomer: Report "Assign Tax Area to Customer";
        AssignTaxAreaToVendor: Report "Assign Tax Area to Vendor";
        AssignTaxAreaToLocation: Report "Assign Tax Area to Location";
    begin
        Commit();
        if AssignToCustomers then begin
            AssignTaxAreaToCustomer.SetTableView(Customer);
            AssignTaxAreaToCustomer.SetDefaultAreaCode("Tax Area Code");
            AssignTaxAreaToCustomer.Run();
            Commit();
        end;
        if AssignToVendors then begin
            AssignTaxAreaToVendor.SetTableView(Vendor);
            AssignTaxAreaToVendor.SetDefaultAreaCode("Tax Area Code");
            AssignTaxAreaToVendor.Run();
            Commit();
        end;
        if AssignToLocations then begin
            AssignTaxAreaToLocation.SetTableView(Location);
            AssignTaxAreaToLocation.SetDefaultAreaCode("Tax Area Code");
            AssignTaxAreaToLocation.Run();
            Commit();
        end;
        if AssignToCompanyInfo and DummyCompanyInformation.FindFirst() then begin
            DummyCompanyInformation.Validate("Tax Area Code", "Tax Area Code");
            DummyCompanyInformation.Modify();
            Commit();
        end;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure SetCityAndCountyVisible()
    var
        CompanyInformation: Record "Company Information";
    begin
        CityAndCountyVisible := not CompanyInformation.IsCanada();
    end;

    local procedure SetDefaultCountry()
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.IsCanada() then
            "Country/Region" := "Country/Region"::CA
        else
            "Country/Region" := "Country/Region"::US;
        Modify();
    end;
}

