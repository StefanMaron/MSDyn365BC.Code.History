page 7003 "Duplicate Price Lines"
{
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Duplicate Price Line";
    SourceTableView = sorting("Duplicate To Line No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Remove; Rec.Remove)
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies if the price list line should be removed to resolve duplication.';
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field("Price List Line No."; Rec."Price List Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the price list line.';
                }
                field("Source Type"; CurrPriceListLine."Source Type")
                {
                    Caption = 'Applies-to Type';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the type of the source the price applies to.';
                }
                field("Source No."; CurrPriceListLine."Source No.")
                {
                    Caption = 'Applies-to No.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the source the price applies to.';
                }
                field("Asset Type"; CurrPriceListLine."Asset Type")
                {
                    Caption = 'Product Type';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; CurrPriceListLine."Asset No.")
                {
                    Caption = 'Product No.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the product.';
                }
                field(Description; CurrPriceListLine.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the description of the product.';
                }
                field("Variant Code"; CurrPriceListLine."Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; CurrPriceListLine."Work Type Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; CurrPriceListLine."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; CurrPriceListLine."Minimum Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; CurrPriceListLine."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the data that is defined in the price list line. It can be either price or discount, or both';
                }
                field("Currency Code"; CurrPriceListLine."Currency Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field("Unit Price"; CurrPriceListLine."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and IsSalesPrice;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; CurrPriceListLine."Cost Factor")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and IsSalesPrice;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit cost factor for job-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Unit Cost"; CurrPriceListLine."Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and not IsSalesPrice;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit cost of the product.';
                }
                field(DirectUnitCost; CurrPriceListLine."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and not IsSalesPrice;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Allow Line Disc."; CurrPriceListLine."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Editable = false;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; CurrPriceListLine."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and IsSalesPrice;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field(PurchLineDiscountPct; CurrPriceListLine."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and not IsSalesPrice;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; CurrPriceListLine."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible and IsSalesPrice;
                    Editable = false;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("Starting Date"; CurrPriceListLine."Starting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrPriceListLine."Ending Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Not Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the date when the price agreement ends.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if CurrPriceListLine.Get(Rec."Price List Code", Rec."Price List Line No.") then;
    end;

    var
        CurrPriceListLine: Record "Price List Line";
        DiscountVisible: Boolean;
        PriceVisible: Boolean;
        IsSalesPrice: Boolean;

    procedure Set(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var DuplicatePriceLine: Record "Duplicate Price Line")
    begin
        Rec.Copy(DuplicatePriceLine, true);
        DiscountVisible := AmountType in ["Price Amount Type"::Any, "Price Amount Type"::Discount];
        PriceVisible := AmountType in ["Price Amount Type"::Any, "Price Amount Type"::Price];
        IsSalesPrice := PriceType = "Price Type"::Sale;
    end;

    procedure GetLines(var DuplicatePriceLine: Record "Duplicate Price Line")
    begin
        DuplicatePriceLine.Copy(Rec, true);
    end;
}