#if not CLEAN21
page 2107 "O365 Sales Customer Card"
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
                    ShowCaption = false;
                    ToolTip = 'Specifies the customer''s name.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ShowCaption = false;
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
                    ShowCaption = false;
                    ToolTip = 'Specifies the customer''s telephone number.';
                }
                group(Control17)
                {
                    ShowCaption = false;
                    Visible = Rec."Balance (LCY)" <> 0;
                    field("Balance (LCY)"; Rec."Balance (LCY)")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                        ApplicationArea = Invoicing, Basic, Suite;
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
                field("Sales (LCY)"; Rec."Sales (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                        Visible = (Rec."Contact Type" = Rec."Contact Type"::Company) AND IsUsingVAT;
                        field("VAT Registration No."; Rec."VAT Registration No.")
                        {
                            ApplicationArea = Invoicing, Basic, Suite;
                        }
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = (Rec."Contact Type" = Rec."Contact Type"::Person) AND IsAddressLookupAvailable AND CurrPageEditable;
                        field(AddressLookup; AddressLookupLbl)
                        {
                            ApplicationArea = Invoicing, Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    field(FullAddress; FullAddress)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address';
                        Editable = CurrPageEditable;
                        QuickEntry = false;

                        trigger OnAssistEdit()
                        var
                            TempStandardAddress: Record "Standard Address" temporary;
                        begin
                            CurrPage.SaveRecord();
                            Commit();
                            TempStandardAddress.CopyFromCustomer(Rec);
                            if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                                Rec.Get(Rec."No.");
                                FullAddress := TempStandardAddress.ToString();
                            end;
                        end;
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
                    Editable = CurrPageEditable;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the customer''s tax area.';

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
            group(Documents)
            {
                Visible = NOT CurrPageEditable;
                field(InvoicesForCustomer; InvoicesLabelText)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Invoice);
                        O365SalesDocument.SetRange("Sell-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"O365 Customer Sales Documents", O365SalesDocument);
                    end;
                }
                field(EstimatesForCustomer; EstimatesLabelText)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Quote);
                        O365SalesDocument.SetRange("Sell-to Customer No.", Rec."No.");
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Invoice Discounts';
                Image = Discount;
                ToolTip = 'Set up different discounts that are applied to invoices for the customer. An invoice discount is automatically granted to the customer when the total on a sales invoice exceeds a certain amount.';
                Visible = false;

                trigger OnAction()
                var
                    O365CustInvoiceDiscount: Page "O365 Cust. Invoice Discount";
                begin
                    O365CustInvoiceDiscount.FillO365CustInvDiscount(Rec."No.");
                    O365CustInvoiceDiscount.Run();
                end;
            }
            action(ImportDeviceContact)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Import Contact';
                Scope = Repeater;
                ToolTip = 'Import a contact directly from your iOS or Android device and have the new customer fields automatically populated. ';
                Visible = CurrPageEditable AND DeviceContactProviderIsAvailable;

                trigger OnAction()
                begin
                    if DeviceContactProviderIsAvailable then begin
                        if IsNull(DeviceContactProvider) then
                            DeviceContactProvider := DeviceContactProvider.Create();
                        DeviceContactProvider.RequestDeviceContactAsync();
                    end
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ImportDeviceContact_Promoted; ImportDeviceContact)
                {
                }
                actionref("Invoice Discounts_Promoted"; "Invoice Discounts")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Details', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TempStandardAddress: Record "Standard Address" temporary;
        TaxArea: Record "Tax Area";
    begin
        CreateCustomerFromTemplate();
        CurrPageEditable := CurrPage.Editable;

        OverdueAmount := Rec.CalcOverdueBalance();

        TempStandardAddress.CopyFromCustomer(Rec);
        FullAddress := TempStandardAddress.ToString();

        if TaxArea.Get(Rec."Tax Area Code") then
            TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguageFullLength();

        UpdateInvoicesLbl();
        UpdateEstimatesLbl();
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
        if O365SalesInitialSetup.Get() then
            IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
        IsAddressLookupAvailable := PostcodeServiceManager.IsConfigured();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec.Name = '' then
            CustomerCardState := CustomerCardState::Prompt
        else
            CustomerCardState := CustomerCardState::Keep;

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
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
        CurrPage.Editable := Rec.Blocked = Rec.Blocked::" ";
        Rec.SetRange("Date Filter", 0D, WorkDate());
        DeviceContactProviderIsAvailable := DeviceContactProvider.IsAvailable();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CanExitAfterProcessingCustomer());
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
        TaxAreaDescription: Text[100];
        InvoicesLabelText: Text;
        EstimatesLabelText: Text;

    local procedure CanExitAfterProcessingCustomer(): Boolean
    var
        Response: Option ,KeepEditing,Discard;
    begin
        if Rec."No." = '' then
            exit(true);

        if CustomerCardState = CustomerCardState::Delete then
            exit(DeleteCustomerRelatedData());

        if GuiAllowed and (CustomerCardState = CustomerCardState::Prompt) and (Rec.Blocked = Rec.Blocked::" ") then
            case StrMenu(ProcessNewCustomerOptionQst, Response::KeepEditing, ProcessNewCustomerInstructionTxt) of
                Response::Discard:
                    exit(DeleteCustomerRelatedData());
                else
                    exit(false);
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
    begin
        if NewMode then begin
            if CustomerTemplMgt.InsertCustomerFromTemplate(Customer) then begin
                Rec.Copy(Customer);
                CurrPage.Update();
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
        SalesHeader.SetRange("Sell-to Customer No.", Rec."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        NumberOfInvoices := SalesHeader.Count();

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Rec."No.");
        NumberOfInvoices := NumberOfInvoices + SalesInvoiceHeader.Count();

        InvoicesLabelText := StrSubstNo(InvoicesForCustomerLbl, NumberOfInvoices);
    end;

    local procedure UpdateEstimatesLbl()
    var
        SalesHeader: Record "Sales Header";
        NumberOfEstimates: Integer;
    begin
        SalesHeader.SetRange("Sell-to Customer No.", Rec."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        NumberOfEstimates := SalesHeader.Count();

        EstimatesLabelText := StrSubstNo(EstimatesForCustomerLbl, NumberOfEstimates);
    end;

    trigger DeviceContactProvider::DeviceContactRetrieved(deviceContact: DotNet DeviceContact)
    begin
        if deviceContact.Status <> 0 then
            exit;

        CreateCustomerFromTemplate();

        Rec.Name := CopyStr(deviceContact.PreferredName, 1, MaxStrLen(Rec.Name));
        Rec."E-Mail" := CopyStr(deviceContact.PreferredEmail, 1, MaxStrLen(Rec."E-Mail"));
        Rec."Phone No." := CopyStr(deviceContact.PreferredPhoneNumber, 1, MaxStrLen(Rec."Phone No."));
        Rec.Address := CopyStr(deviceContact.PreferredAddress.StreetAddress, 1, MaxStrLen(Rec.Address));
        Rec.City := CopyStr(deviceContact.PreferredAddress.Locality, 1, MaxStrLen(Rec.City));
        Rec.County := CopyStr(deviceContact.PreferredAddress.Region, 1, MaxStrLen(Rec.County));

        CurrPage.Update();
    end;
}
#endif
