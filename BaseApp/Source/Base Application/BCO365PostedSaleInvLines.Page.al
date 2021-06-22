page 2304 "BC O365 Posted Sale Inv. Lines"
{
    Caption = 'Sent Invoice Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Invoice Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the item or service on the line.';
                }
                field(LineQuantity; LineQuantity)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Enabled = false;
                    ToolTip = 'Specifies the quantity of the item or service on the line.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price Per';
                    ToolTip = 'Specifies the unit of measure code for the item.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit on the sales line.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT';
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT group code for this item.';
                    Visible = IsUsingVAT;
                }
                field(LineAmountInclVAT; GetLineAmountInclVAT)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount Incl. VAT';
                    ToolTip = 'Specifies the net amounts, including VAT and excluding any invoice discount, that must be paid for products on the line.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                    Visible = ShowOnlyOnBrick;
                }
                field("Price description"; "Price description")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = ShowOnlyOnBrick;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        UpdatePriceDescription;
        UpdateCurrencyFormat;
        if VATProductPostingGroup.Get("VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description
        else
            Clear(VATProductPostingGroup);
        LineQuantity := Quantity;
        ShowOnlyOnBrick := false;
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        ShowOnlyOnBrick := true;
    end;

    var
        CurrencyFormat: Text;
        VATProductPostingGroupDescription: Text[100];
        LineQuantity: Decimal;
        IsUsingVAT: Boolean;
        ShowOnlyOnBrick: Boolean;

    local procedure UpdateCurrencyFormat()
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrencySymbol: Text[10];
    begin
        SalesInvoiceHeader.Get("Document No.");
        if SalesInvoiceHeader."Currency Code" = '' then begin
            GLSetup.Get;
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get(SalesInvoiceHeader."Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;
}

