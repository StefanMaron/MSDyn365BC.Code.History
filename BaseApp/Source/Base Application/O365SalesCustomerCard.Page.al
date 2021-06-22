page 2107 "O365 Sales Customer Card"
{
    Caption = 'Customer';
    DataCaptionExpression = Name;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Details';
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ShowCaption = false;
                    ToolTip = 'Specifies the customer''s name.';
                }
                field("Contact Type"; "Contact Type")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    OptionCaption = 'Company contact,Person';
                    ShowCaption = false;
                    ToolTip = 'Specifies if the contact is a company or a person.';

                    trigger OnValidate()
                    begin
                        Validate("Prices Including VAT", "Contact Type" = "Contact Type"::Person);
                    end;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ShowCaption = false;
                    ToolTip = 'Specifies the customer''s email address.';

                    trigger OnValidate()
                    var
                        MailManagement: Codeunit "Mail Management";
                    begin
                        MailManagement.ValidateEmailAddressField("E-Mail");
                    end;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Phone Number';
                    ShowCaption = false;
                    ToolTip = 'Specifies the customer''s telephone number.';
                }
                group(Control17)
                {
                    ShowCaption = false;
                    Visible = "Balance (LCY)" <> 0;
                    field("Balance (LCY)"; "Balance (LCY)")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = '1';
                        AutoFormatType = 10;
                        Caption = 'Outstanding';
                        DrillDown = false;
                        Importance = Additional;
                        Lookup = false;
                        ToolTip = 'Specifies the customer''s balance.';
                    }
                }
                group(Control18)
                {
                    ShowCaption = false;
                    Visible = OverdueAmount <> 0;
                    field(OverdueAmount; OverdueAmount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        AutoFormatExpression = '1';
                        AutoFormatType = 10;
                        Caption = 'Overdue';
                        DrillDown = false;
                        Editable = false;
                        Importance = Additional;
                        Lookup = false;
                        Style = Unfavorable;
                        StyleExpr = OverdueAmount > 0;
                        ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';
                    }
                }
                field("Sales (LCY)"; "Sales (LCY)")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Total Sales (Excl. VAT)';
                    DrillDown = false;
                    Importance = Additional;
                    Lookup = false;
                    ToolTip = 'Specifies the total net amount of sales to the customer in LCY.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                group(Control26)
                {
                    ShowCaption = false;
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = ("Contact Type" = "Contact Type"::Company) AND IsUsingVAT;
                        field("VAT Registration No."; "VAT Registration No.")
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                        }
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = ("Contact Type" = "Contact Type"::Person) AND IsAddressLookupAvailable AND CurrPageEditable;
                        field(AddressLookup; AddressLookupLbl)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    field(FullAddress; FullAddress)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address';
                        Editable = CurrPageEditable;
                        QuickEntry = false;

                        trigger OnAssistEdit()
                        var
                            TempStandardAddress: Record "Standard Address" temporary;
                        begin
                            CurrPage.SaveRecord;
                            Commit();
                            TempStandardAddress.CopyFromCustomer(Rec);
                            if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                                Get("No.");
                                FullAddress := TempStandardAddress.ToString;
                            end;
                        end;
                    }
                }
            }
            group("Tax Information")
            {
                Caption = 'Tax';
                Visible = NOT IsUsingVAT;
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';
                }
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Tax Rate';
                    Editable = CurrPageEditable;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the customer''s tax area.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxArea: Record "Tax Area";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                            Validate("Tax Area Code", TaxArea.Code);
                            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
                        end;
                    end;
                }
            }
            group(Documents)
            {
                Visible = NOT CurrPageEditable;
                field(InvoicesForCustomer; InvoicesLabelText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Invoice);
                        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
                        PAGE.Run(PAGE::"O365 Customer Sales Documents", O365SalesDocument);
                    end;
                }
                field(EstimatesForCustomer; EstimatesLabelText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Quote);
                        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
                        O365SalesDocument.SetRange(Posted, false);
                        PAGE.Run(PAGE::"O365 Customer Sales Documents", O365SalesDocument);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Invoice Discounts")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Invoice Discounts';
                Image = Discount;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Set up different discounts that are applied to invoices for the customer. An invoice discount is automatically granted to the customer when the total on a sales invoice exceeds a certain amount.';
                Visible = false;

                trigger OnAction()
                var
                    O365CustInvoiceDiscount: Page "O365 Cust. Invoice Discount";
                begin
                    O365CustInvoiceDiscount.FillO365CustInvDiscount("No.");
                    O365CustInvoiceDiscount.Run;
                end;
            }
            action(ImportDeviceContact)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Import Contact';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Import a contact directly from your iOS or Android device and have the new customer fields automatically populated. ';
                Visible = CurrPageEditable AND DeviceContactProviderIsAvailable;

                trigger OnAction()
                begin
                    if DeviceContactProviderIsAvailable then begin
                        if IsNull(DeviceContactProvider) then
                            DeviceContactProvider := DeviceContactProvider.Create;
                        DeviceContactProvider.RequestDeviceContactAsync;
                    end
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TempStandardAddress: Record "Standard Address" temporary;
        TaxArea: Record "Tax Area";
    begin
        CreateCustomerFromTemplate;
        CurrPageEditable := CurrPage.Editable;

        OverdueAmount := CalcOverdueBalance;

        TempStandardAddress.CopyFromCustomer(Rec);
        FullAddress := TempStandardAddress.ToString;

        if TaxArea.Get("Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;

        UpdateInvoicesLbl;
        UpdateEstimatesLbl;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Rec);
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
    begin
        if O365SalesInitialSetup.Get then
            IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        IsAddressLookupAvailable := PostcodeServiceManager.IsConfigured;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Name = '' then
            CustomerCardState := CustomerCardState::Prompt
        else
            CustomerCardState := CustomerCardState::Keep;

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Name = '' then
            CustomerCardState := CustomerCardState::Prompt
        else
            CustomerCardState := CustomerCardState::Keep;

        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable := Blocked = Blocked::" ";
        SetRange("Date Filter", 0D, WorkDate);
        DeviceContactProviderIsAvailable := DeviceContactProvider.IsAvailable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CanExitAfterProcessingCustomer);
    end;

    var
        CustContUpdate: Codeunit "CustCont-Update";
        O365SalesManagement: Codeunit "O365 Sales Management";
        ProcessNewCustomerOptionQst: Label 'Keep editing,Discard';
        ProcessNewCustomerInstructionTxt: Label 'Name is missing. Keep the customer?';
        AddressLookupLbl: Label 'Lookup customer address';
        InvoicesForCustomerLbl: Label 'Invoices (%1)', Comment = '%1= positive or zero integer: the number of invoices for the customer';
        EstimatesForCustomerLbl: Label 'Estimates (%1)', Comment = '%1= positive or zero integer: the number of estimates for the customer';
        [RunOnClient]
        [WithEvents]
        DeviceContactProvider: DotNet DeviceContactProvider;
        CustomerCardState: Option Keep,Delete,Prompt;
        DeviceContactProviderIsAvailable: Boolean;
        NewMode: Boolean;
        IsAddressLookupAvailable: Boolean;
        CurrPageEditable: Boolean;
        IsUsingVAT: Boolean;
        OverdueAmount: Decimal;
        FullAddress: Text;
        TaxAreaDescription: Text[50];
        InvoicesLabelText: Text;
        EstimatesLabelText: Text;

    local procedure CanExitAfterProcessingCustomer(): Boolean
    var
        Response: Option ,KeepEditing,Discard;
    begin
        if "No." = '' then
            exit(true);

        if CustomerCardState = CustomerCardState::Delete then
            exit(DeleteCustomerRelatedData);

        if GuiAllowed and (CustomerCardState = CustomerCardState::Prompt) and (Blocked = Blocked::" ") then
            case StrMenu(ProcessNewCustomerOptionQst, Response::KeepEditing, ProcessNewCustomerInstructionTxt) of
                Response::Discard:
                    exit(DeleteCustomerRelatedData);
                else
                    exit(false);
            end;

        exit(true);
    end;

    local procedure DeleteCustomerRelatedData(): Boolean
    begin
        CustContUpdate.DeleteCustomerContacts(Rec);

        // workaround for bug: delete for new empty record returns false
        if Delete(true) then;
        exit(true);
    end;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed and DocumentNoVisibility.CustomerNoSeriesIsDefault then
            NewMode := true;
    end;

    local procedure CreateCustomerFromTemplate()
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
        Customer: Record Customer;
    begin
        if NewMode then begin
            if MiniCustomerTemplate.NewCustomerFromTemplate(Customer) then begin
                Copy(Customer);
                CurrPage.Update;
            end;
            CustomerCardState := CustomerCardState::Delete;
            NewMode := false;
        end;
    end;

    local procedure UpdateInvoicesLbl()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        NumberOfInvoices: Integer;
    begin
        SalesHeader.SetRange("Sell-to Customer No.", "No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        NumberOfInvoices := SalesHeader.Count();

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", "No.");
        NumberOfInvoices := NumberOfInvoices + SalesInvoiceHeader.Count();

        InvoicesLabelText := StrSubstNo(InvoicesForCustomerLbl, NumberOfInvoices);
    end;

    local procedure UpdateEstimatesLbl()
    var
        SalesHeader: Record "Sales Header";
        NumberOfEstimates: Integer;
    begin
        SalesHeader.SetRange("Sell-to Customer No.", "No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        NumberOfEstimates := SalesHeader.Count();

        EstimatesLabelText := StrSubstNo(EstimatesForCustomerLbl, NumberOfEstimates);
    end;

    trigger DeviceContactProvider::DeviceContactRetrieved(deviceContact: DotNet DeviceContact)
    begin
        if deviceContact.Status <> 0 then
            exit;

        CreateCustomerFromTemplate;

        Name := CopyStr(deviceContact.PreferredName, 1, MaxStrLen(Name));
        "E-Mail" := CopyStr(deviceContact.PreferredEmail, 1, MaxStrLen("E-Mail"));
        "Phone No." := CopyStr(deviceContact.PreferredPhoneNumber, 1, MaxStrLen("Phone No."));
        Address := CopyStr(deviceContact.PreferredAddress.StreetAddress, 1, MaxStrLen(Address));
        City := CopyStr(deviceContact.PreferredAddress.Locality, 1, MaxStrLen(City));
        County := CopyStr(deviceContact.PreferredAddress.Region, 1, MaxStrLen(County));

        CurrPage.Update;
    end;
}

