page 7020 "Purchase Job Price Lists"
{
    Caption = 'Purchase Job Price Lists';
    CardPageID = "Purchase Price List";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report';
    QueryCategory = 'Purchase Job Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Source Group" = CONST(Job), "Price Type" = CONST(Purchase));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the code of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price list status.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the price list defines prices, discounts or both.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the source group of the price list.';
                }
                field(SourceType; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the source for the price list.';
                }
                field(ParentSourceNo; Rec."Parent Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number that is the parent of the job task the price list applies to.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the purchase price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the purchase price agreement ends.';
                }
            }
        }
    }

    trigger OnInit()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.TestIsEnabled();
    end;

    procedure SetSource(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceSourceList, AmountType);
    end;
}