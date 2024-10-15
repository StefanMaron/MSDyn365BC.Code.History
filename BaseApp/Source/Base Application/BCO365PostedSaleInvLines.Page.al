#if not CLEAN21
page 2304 "BC O365 Posted Sale Inv. Lines"
{
    Caption = 'Sent Invoice Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Invoice Line";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the item or service on the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field(LineQuantity; LineQuantity)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Enabled = false;
                    ToolTip = 'Specifies the quantity of the item or service on the line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Price Per';
                    ToolTip = 'Specifies the unit of measure code for the item.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit on the sales line.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'VAT';
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT group code for this item.';
                    Visible = IsUsingVAT;
                }
                field(LineAmountInclVAT; GetLineAmountInclVAT())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount Incl. VAT';
                    ToolTip = 'Specifies the net amounts, including VAT and excluding any invoice discount, that must be paid for products on the line.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                    Visible = ShowOnlyOnBrick;
                }
                field("Price description"; Rec."Price description")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
        UpdatePriceDescription();
        UpdateCurrencyFormat();
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
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
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
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol();
        end else begin
            if Currency.Get(SalesInvoiceHeader."Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol();
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;
}
#endif
