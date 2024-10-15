#if not CLEAN20
page 5157 "Customer Template Card"
{
    Caption = 'Customer Template Card';
    PageType = Card;
    SourceTable = "Customer Template";
    ObsoleteReason = 'Deprecate mini and customer templates. Use "Customer Templ. Card" page instead and for extensions.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the contact conversion template. You can set up as many codes as you want. The code must be unique. You cannot have the same code twice in one table.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the contact conversion template.';
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of contact that will be converted to a customer with the template.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the customer that will be created with the template.';
                }
                field("Territory Code"; Rec."Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the territory code of the customer that will be created with the template.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the customer that will be created with the template.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer is liable for sales tax.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a tax area code for the company.';
                }
                field(State; State)
                {
                    ToolTip = 'Specifies the state/province of customers created from this template.';
                }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum credit (in LCY) that can be extended to customer''s created from a template.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the new customer to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new customer''s market type to link business transactions to.';
                }
                field("Customer Price Group"; Rec."Customer Price Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new customer''s price group, which you can use to set up special sales prices on the Sales Prices page.';
                }
                field("Customer Disc. Group"; Rec."Customer Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new customer''s discount group, which you can use to set up special sales discounts on the Sales Prices page.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that a line discount is calculated for the new customer when the sales price is offered.';
                }
                field("Invoice Disc. Code"; Rec."Invoice Disc. Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the invoice discount code of the customer that will be created with the template.';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT for the new customer.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount for the new customer.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how the new customer makes payment, such as with bank transfer, cash, or check.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the delivery conditions of the related shipments to the new customer, such as free on board (FOB).';
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
            group("&Contact Conversion Template")
            {
                Caption = '&Contact Conversion Template';
                Image = Template;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5105),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action(CopyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Template';
                    Image = Copy;
                    ToolTip = 'Copies all information to the current contact conversion template from the selected one.';

                    trigger OnAction()
                    var
                        CustomerTemplate: Record "Customer Template";
                        CustomerTemplateList: Page "Customer Template List";
                    begin
                        TestField(Code);
                        CustomerTemplate.SetFilter(Code, '<>%1', Code);
                        CustomerTemplateList.LookupMode(true);
                        CustomerTemplateList.SetTableView(CustomerTemplate);
                        if CustomerTemplateList.RunModal() = ACTION::LookupOK then begin
                            CustomerTemplateList.GetRecord(CustomerTemplate);
                            CopyTemplate(CustomerTemplate);
                        end;
                    end;
                }
            }
            group("S&ales")
            {
                Caption = 'S&ales';
                Image = Sales;
                action("Invoice &Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Invoice &Discounts';
                    Image = CalculateInvoiceDiscount;
                    RunObject = Page "Cust. Invoice Discounts";
                    RunPageLink = Code = FIELD("Invoice Disc. Code");
                    ToolTip = 'Set up different discounts that are applied to invoices for the customer that will be created from the template. An invoice discount is automatically granted to the customer when the total on a sales invoice exceeds a certain amount.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(CopyTemplate_Promoted; CopyTemplate)
                {
                }
            }
        }
    }
}
#endif

