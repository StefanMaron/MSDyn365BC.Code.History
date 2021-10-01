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
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines';
                    ToolTip = 'Specifies whether the price list defines prices, discounts, or both.';
                }
                field("Currency Code"; CurrRec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that is used on the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or jobs.';
                }
                field(SourceType; CurrRec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Type';
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to No.';
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Starting Date"; CurrRec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrRec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date when the purchase price agreement ends.';
                }
            }
        }
    }

#if not CLEAN19
    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;
#endif
    trigger OnAfterGetRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    var
        CurrRec: Record "Price List Header";

    procedure SetRecordFilter(var PriceListHeader: Record "Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(PriceListHeader);
        Rec.SetRange("Source Group", Rec."Source Group"::Vendor);
        Rec.SetRange("Price Type", Rec."Price Type"::Purchase);
        Rec.FilterGroup := 0;
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