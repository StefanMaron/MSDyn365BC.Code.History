page 1386 "Vendor Templ. Card"
{
    Caption = 'Vendor Template';
    PageType = Card;
    SourceTable = "Vendor Templ.";

    layout
    {
        area(content)
        {
            group(Template)
            {
                Caption = 'General';
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
                field("Contact Type"; "Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of contact that will be used to create a vendor with the template.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which transactions with the vendor that cannot be processed, for example a vendor that is declared insolvent.';
                }
            }
            group(AddressAndContact)
            {
                Caption = 'Address & Contact';
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s city.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state, province or county as a part of the address.';
                }
                group(Contact)
                {
                    Caption = 'Contact';
                    field("Language Code"; "Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Validate EU Vat Reg. No."; "Validate EU Vat Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT registration number has been validated by the VAT number validation service.';
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of a different vendor whom you pay for products delivered by the vendor on the vendor card.';
                }
                field("Invoice Disc. Code"; "Invoice Disc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the vendor''s invoice discount code. When you set up a new vendor card, the number you have entered in the No. field is automatically inserted.';
                }
                field("Prices Including VAT"; "Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                }
                group(PostingDetails)
                {
                    Caption = 'Posting details';
                    field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the vendor''s trade type to link transactions made for this vendor with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field("Vendor Posting Group"; "Vendor Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Currency Code"; "Currency Code")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the default currency on purchase documents or journal lines that you create for the vendor.';
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to apply payments to entries for this vendor.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to make payments, such as with bank transfers or by cash or check.';
                }
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how the vendor calculates finance charges.';
                }
                field("Block Payment Tolerance"; "Block Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow a payment tolerance for the vendor.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Default Dimensions";
                RunPageLink = "Table ID" = const(1383),
                              "No." = field(Code);
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action(CopyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Template';
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Copies all information to the current template from the selected one.';

                trigger OnAction()
                var
                    VendorTempl: Record "Vendor Templ.";
                    VendorTemplList: Page "Vendor Templ. List";
                begin
                    TestField(Code);
                    VendorTempl.SetFilter(Code, '<>%1', Code);
                    VendorTemplList.LookupMode(true);
                    VendorTemplList.SetTableView(VendorTempl);
                    if VendorTemplList.RunModal() = Action::LookupOK then begin
                        VendorTemplList.GetRecord(VendorTempl);
                        CopyFromTemplate(VendorTempl);
                    end;
                end;
            }
        }
    }
}
