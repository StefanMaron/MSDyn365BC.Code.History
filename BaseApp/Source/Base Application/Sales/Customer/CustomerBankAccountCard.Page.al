namespace Microsoft.Sales.Customer;

using Microsoft.Bank.DirectDebit;
using Microsoft.Foundation.Address;

page 423 "Customer Bank Account Card"
{
    Caption = 'Customer Bank Account Card';
    PageType = Card;
    SourceTable = "Customer Bank Account";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this customer bank account.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where the customer has the bank account.';
                }
                group(Control1040004)
                {
                    ShowCaption = false;
                    Visible = IsAddressLookupTextEnabled;
                    field(LookupAddress; LookupAddressLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ShowPostcodeLookup(true);
                        end;
                    }
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';

                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                    end;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the bank where the customer has the bank account.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county of the bank where the customer has the bank account. ';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        HandleAddressLookupVisibility();
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where the customer has the bank account.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the postal code.';

                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                        ShowPostcodeLookup(false);
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank branch.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Transit No."; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where the customer has the bank account.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the customer has the account.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("Bank Clearing Standard"; Rec."Bank Clearing Standard")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
                }
                field("Bank Clearing Code"; Rec."Bank Clearing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Direct Debit Mandates")
            {
                ApplicationArea = Suite;
                Caption = 'Direct Debit Mandates';
                Image = MakeAgreement;
                RunObject = Page "SEPA Direct Debit Mandates";
                RunPageLink = "Customer No." = field("Customer No."),
                              "Customer Bank Account Code" = field(Code);
                ToolTip = 'View or edit direct-debit mandates that you set up to reflect agreements with customers to collect invoice payments from their bank account.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Direct Debit Mandates_Promoted"; "Direct Debit Mandates")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HandleAddressLookupVisibility();
    end;

    var
        LookupAddressLbl: Label 'Lookup address from postcode';
        IsAddressLookupTextEnabled: Boolean;

    local procedure ShowPostcodeLookup(ShowInputFields: Boolean)
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not PostcodeBusinessLogic.SupportedCountryOrRegionCode(Rec."Country/Region Code") then
            exit;

        if not PostcodeBusinessLogic.IsConfigured() or ((Rec."Post Code" = '') and not ShowInputFields) then
            exit;

        TempEnteredAutocompleteAddress.Address := Rec.Address;
        TempEnteredAutocompleteAddress.Postcode := Rec."Post Code";

        if not PostcodeBusinessLogic.ShowLookupWindow(TempEnteredAutocompleteAddress, ShowInputFields, TempAutocompleteAddress) then
            exit;

        CopyAutocompleteFields(TempAutocompleteAddress);
        HandleAddressLookupVisibility();
    end;

    local procedure CopyAutocompleteFields(var TempAutocompleteAddress: Record "Autocomplete Address" temporary)
    begin
        Rec.Address := TempAutocompleteAddress.Address;
        Rec."Address 2" := TempAutocompleteAddress."Address 2";
        Rec."Post Code" := TempAutocompleteAddress.Postcode;
        Rec.City := TempAutocompleteAddress.City;
        Rec.County := TempAutocompleteAddress.County;
        Rec."Country/Region Code" := TempAutocompleteAddress."Country / Region";
    end;

    local procedure HandleAddressLookupVisibility()
    var
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not CurrPage.Editable or not PostcodeBusinessLogic.IsConfigured() then
            IsAddressLookupTextEnabled := false
        else
            IsAddressLookupTextEnabled := PostcodeBusinessLogic.SupportedCountryOrRegionCode(Rec."Country/Region Code");
    end;
}

