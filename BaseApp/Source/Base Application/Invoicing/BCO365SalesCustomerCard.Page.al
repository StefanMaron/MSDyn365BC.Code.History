#if not CLEAN21
page 2318 "BC O365 Sales Customer Card"
{
    Caption = 'Customer';
    DataCaptionExpression = Rec.Name;
    PageType = Card;
    SourceTable = Customer;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the customer''s name.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies if the contact is a company or a person.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            group("Contact & Address")
            {
                Caption = 'Contact & Address';
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Email Address';
                        ExtendedDatatype = EMail;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer''s email address.';

                        trigger OnValidate()
                        var
                            MailManagement: Codeunit "Mail Management";
                        begin
                            MailManagement.ValidateEmailAddressField(Rec."E-Mail");
                        end;
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Phone Number';
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer''s telephone number.';
                    }
                    field(FullAddress; FullAddress)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                        Visible = IsDevice;

                        trigger OnAssistEdit()
                        var
                            TempStandardAddress: Record "Standard Address" temporary;
                        begin
                            if not CurrPageEditable then
                                exit;
                            if Rec.Name = '' then
                                exit;

                            CurrPage.SaveRecord();
                            Commit();
                            TempStandardAddress.CopyFromCustomer(Rec);
                            if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                                Rec.Find();
                                CurrPage.Update(true);
                            end;
                        end;
                    }
                }
                group(AddressDetails)
                {
                    Caption = 'Address';
                    Visible = NOT IsDevice;
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Lookup = false;
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Lookup = false;
                    }
                    field(County; Rec.County)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                    }
                    field(CountryRegionCode; CountryRegionCode)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Country/Region Code';
                        Editable = CurrPageEditable;
                        Lookup = true;
                        LookupPageID = "BC O365 Country/Region List";
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            CountryRegionCode := O365SalesInvoiceMgmt.FindCountryCodeFromInput(CountryRegionCode);

                            // Do not VALIDATE("Country/Region Code",CountryRegionCode), as it wipes city, post code and county
                            Rec."Country/Region Code" := CountryRegionCode;
                        end;
                    }
                }
            }
            group("Sales and Payments")
            {
                Caption = 'Sales and Payments';
                Visible = SalesAndPaymentsVisible;
                group(Control16)
                {
                    ShowCaption = false;
                    Visible = NOT TotalsHidden;
                    field("Balance (LCY)"; Rec."Balance (LCY)")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = '1';
                        AutoFormatType = 10;
                        Caption = 'Outstanding';
                        DrillDown = false;
                        Importance = Promoted;
                        Lookup = false;
                        ToolTip = 'Specifies the customer''s balance.';
                    }
                    field(OverdueAmount; OverdueAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = '1';
                        AutoFormatType = 10;
                        Caption = 'Overdue';
                        DrillDown = false;
                        Editable = false;
                        Lookup = false;
                        Style = Unfavorable;
                        StyleExpr = OverdueAmount > 0;
                        ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';
                    }
                    field("Sales (LCY)"; Rec."Sales (LCY)")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = '1';
                        AutoFormatType = 10;
                        Caption = 'Total Sales (Excl. VAT)';
                        DrillDown = false;
                        Lookup = false;
                        ToolTip = 'Specifies the total net amount of sales to the customer in LCY.';
                    }
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = (Rec."Contact Type" = Rec."Contact Type"::Company) AND IsUsingVAT;
                    field("VAT Registration No."; Rec."VAT Registration No.")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                    }
                }
            }
            group("Tax Information")
            {
                Caption = 'Tax';
                Visible = NOT IsUsingVAT;
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Tax Rate';
                    Editable = false;
                    Enabled = CurrPageEditable;
                    Importance = Promoted;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the customer''s tax area.';

                    trigger OnAssistEdit()
                    var
                        TaxArea: Record "Tax Area";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Rec.Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxArea: Record "Tax Area";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Rec.Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();
                        end;
                    end;
                }
            }
            group(Status)
            {
                Caption = 'Status';
                Visible = BlockedStatus;
                field(BlockedStatus; BlockedStatus)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Blocked';
                    ToolTip = 'Specifies if you want to block the customer for any further business.';

                    trigger OnValidate()
                    begin
                        if not BlockedStatus then
                            if Confirm(UnblockCustomerQst) then begin
                                Rec.Validate(Blocked, Rec.Blocked::" ");
                                if not ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, Rec."No.") then
                                    CustContUpdate.OnInsert(Rec)
                            end else
                                BlockedStatus := true
                        else
                            Rec.Validate(Blocked, Rec.Blocked::All)
                    end;
                }
            }
            group(Privacy)
            {
                InstructionalText = 'Export customer privacy data in an Excel file and email it to yourself for review before sending it to the customer.';
                field(ExportData; ExportDataLbl)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Rec.SetRecFilter();
                        PAGE.RunModal(PAGE::"O365 Export Customer Data", Rec);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control50; "Customer Picture")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                SubPageLink = "No." = field("No.");
            }
            part(SalesHistSelltoFactBox; "BC O365 Hist. Sell-to FactBox")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Sales History';
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        TaxArea: Record "Tax Area";
        TempStandardAddress: Record "Standard Address" temporary;
    begin
        CreateCustomerFromTemplate();

        OverdueAmount := Rec.CalcOverdueBalance();

        if TaxArea.Get(Rec."Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();

        BlockedStatus := Rec.IsBlocked();

        // Supergroup is visible only if one of the two subgroups is visible
        SalesAndPaymentsVisible := (not TotalsHidden) or
          ((Rec."Contact Type" = "Contact Type"::Company) and IsUsingVAT);

        TempStandardAddress.CopyFromCustomer(Rec);
        FullAddress := TempStandardAddress.ToString();
        CountryRegionCode := Rec."Country/Region Code";
        CurrPageEditable := CurrPage.Editable;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Rec);
        exit(false);
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if O365SalesInitialSetup.Get() then
            IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();

        IsDevice := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if NewMode then
            exit(true);

        if Rec.Name = '' then
            CustomerCardState := CustomerCardState::Prompt
        else
            CustomerCardState := CustomerCardState::Keep;

        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("Date Filter", 0D, WorkDate());
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CanExitAfterProcessingCustomer());
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        CustContUpdate: Codeunit "CustCont-Update";
        O365SalesManagement: Codeunit "O365 Sales Management";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        ClientTypeManagement: Codeunit "Client Type Management";
        CustomerCardState: Option Keep,Delete,Prompt;
        NewMode: Boolean;
        IsUsingVAT: Boolean;
        OverdueAmount: Decimal;
        TaxAreaDescription: Text[100];
        TotalsHidden: Boolean;
        SalesAndPaymentsVisible: Boolean;
        ClosePageQst: Label 'You haven''t specified a name. Do you want to save this customer?';
        CountryRegionCode: Code[10];
        BlockedStatus: Boolean;
        UnblockCustomerQst: Label 'Are you sure you want to unblock the customer for further business?';
        ExportDataLbl: Label 'Export customer privacy data';
        CurrPageEditable: Boolean;
        IsDevice: Boolean;
        FullAddress: Text;

    local procedure CanExitAfterProcessingCustomer(): Boolean
    begin
        if Rec."No." = '' then
            exit(true);

        if CustomerCardState = CustomerCardState::Delete then
            exit(DeleteCustomerRelatedData());

        if GuiAllowed and (CustomerCardState = CustomerCardState::Prompt) and not Rec.IsBlocked()
        then begin
            if Confirm(ClosePageQst, true) then
                exit(true);
            exit(DeleteCustomerRelatedData());
        end;

        exit(true);
    end;

    local procedure DeleteCustomerRelatedData(): Boolean
    begin
        CustContUpdate.DeleteCustomerContacts(Rec);

        // workaround for bug: delete for new empty record returns false
        if Rec.Delete(true) then;
        exit(true);
    end;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed and DocumentNoVisibility.CustomerNoSeriesIsDefault() then
            NewMode := true;
    end;

    local procedure CreateCustomerFromTemplate()
    var
        Customer: Record Customer;
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
    begin
        if NewMode then begin
            O365TaxSettingsManagement.CheckCustomerTemplateTaxIntegrity;
            if CustomerTemplMgt.InsertCustomerFromTemplate(Customer) then
                Rec.Copy(Customer);

            TotalsHidden := true;

            CustomerCardState := CustomerCardState::Delete;
            CurrPage.Update();
            NewMode := false;
        end;
    end;
}
#endif
