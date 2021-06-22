page 7017 "Purchase Price Lists"
{
    Caption = 'Purchase Price Lists';
    CardPageID = "Purchase Price List";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report';
    QueryCategory = 'Purchase Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Source Group" = CONST(Vendor), "Price Type" = CONST(Purchase));
    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the code of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price list status.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the price list defines prices, discounts or both.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the source group of the price list.';
                }
                field(SourceType; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the source for the price list.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the purchase price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the purchase price agreement ends.';
                }
            }
        }
    }

    procedure SetRecordFilter(var PriceListHeader: Record "Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(PriceListHeader);
        Rec.SetRange("Source Group", Rec."Source Group"::Vendor);
        Rec.SetRange("Price Type", Rec."Price Type"::Purchase);
        Rec.FilterGroup := 0;
    end;

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

    procedure SetAsset(PriceAsset: Record "Price Asset"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceAsset."Price Type", AmountType);
    end;
}