page 1341 "Cust. Template Card"
{
    Caption = 'Customer Template';
    CardPageID = "Cust. Template Card";
    DataCaptionExpression = "Template Name";
    PageType = Card;
    PromotedActionCategories = 'New,Process,Reports,Master Data';
    RefreshOnActivate = true;
    SourceTable = "Mini Customer Template";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be replaced by other templates.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Template Name"; "Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the template.';

                    trigger OnValidate()
                    begin
                        SetDimensionsEnabled;
                    end;
                }
                field(TemplateEnabled; TemplateEnabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies if the template is ready to be used';

                    trigger OnValidate()
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                    begin
                        if ConfigTemplateHeader.Get(Code) then
                            ConfigTemplateHeader.SetTemplateEnabled(TemplateEnabled);
                    end;
                }
                field(NoSeries; NoSeries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. Series';
                    TableRelation = "No. Series";
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to customers.';

                    trigger OnValidate()
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                    begin
                        if ConfigTemplateHeader.Get(Code) then
                            ConfigTemplateHeader.SetNoSeries(NoSeries);
                    end;
                }
            }
            group(AddressDetails)
            {
                Caption = 'Address & Contact';
                group(Address)
                {
                    Caption = 'Address';
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s city.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                }
                group(Contact)
                {
                    Caption = 'Contact';
                    field("Document Sending Profile"; "Document Sending Profile")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the preferred method of sending documents to this customer.';
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Validate EU Vat Reg. No."; "Validate EU Vat Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT registration number has been validated by the VAT number validation service.';
                }
                group(PostingDetails)
                {
                    Caption = 'Posting Details';
                    field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer''s trade type to link transactions made for this customer with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer to.';
                    }
                    field("Customer Posting Group"; "Customer Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                    }
                }
                group(PricesandDiscounts)
                {
                    Caption = 'Prices and Discounts';
                    field("Customer Price Group"; "Customer Price Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer price group code, which you can use to set up special sales prices in the Sales Prices window.';
                    }
                    field("Customer Disc. Group"; "Customer Disc. Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer discount group code, which you can use as a criterion to set up special discounts in the Sales Line Discounts window.';
                    }
                    field("Allow Line Disc."; "Allow Line Disc.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if a sales line discount is calculated when a special sales price is offered according to setup in the Sales Prices window.';
                    }
                    field("Prices Including VAT"; "Prices Including VAT")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Currency Code"; "Currency Code")
                    {
                        ApplicationArea = Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies a default currency code for the customer.';
                    }
                    field("Language Code"; "Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the language to be used on printouts for this customer.';
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to apply payments to entries for this customer.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies at which terms you require the customer to pay for products.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how payment for the sales document must be submitted, such as bank transfer or check.';
                }
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
                }
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the finance charges that are calculated for the customer.';
                }
                field("Print Statements"; "Print Statements")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to include this customer when you print the Statement report.';
                }
                field("Block Payment Tolerance"; "Block Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the customer is not allowed a payment tolerance.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Master Data")
            {
                Caption = 'Master Data';
                action("Default Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = DimensionsEnabled;
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "Dimensions Template List";
                    RunPageLink = "Table Id" = CONST(18),
                                  "Master Record Template Code" = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetDimensionsEnabled;
        SetTemplateEnabled;
        SetNoSeries;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CheckTemplateNameProvided
    end;

    trigger OnOpenPage()
    begin
        if Customer."No." <> '' then
            CreateConfigTemplateFromExistingCustomer(Customer, Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        case CloseAction of
            ACTION::LookupOK:
                if Code <> '' then
                    CheckTemplateNameProvided;
            ACTION::LookupCancel:
                if Delete(true) then
                    ;
        end;
    end;

    var
        Customer: Record Customer;
        NoSeries: Code[20];
        [InDataSet]
        DimensionsEnabled: Boolean;
        ProvideTemplateNameErr: Label 'You must enter a %1.', Comment = '%1 Template Name';
        TemplateEnabled: Boolean;

    local procedure SetDimensionsEnabled()
    begin
        DimensionsEnabled := "Template Name" <> '';
    end;

    local procedure SetTemplateEnabled()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        TemplateEnabled := ConfigTemplateHeader.Get(Code) and ConfigTemplateHeader.Enabled;
    end;

    local procedure CheckTemplateNameProvided()
    begin
        if "Template Name" = '' then
            Error(ProvideTemplateNameErr, FieldCaption("Template Name"));
    end;

    procedure CreateFromCust(FromCustomer: Record Customer)
    begin
        Customer := FromCustomer;
    end;

    local procedure SetNoSeries()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        NoSeries := '';
        if ConfigTemplateHeader.Get(Code) then
            NoSeries := ConfigTemplateHeader."Instance No. Series";
    end;
}

