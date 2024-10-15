namespace Microsoft.Purchases.Pricing;

using Microsoft.Pricing.Asset;
#if not CLEAN23
using Microsoft.Pricing.Calculation;
#endif
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

page 7017 "Purchase Price Lists"
{
    Caption = 'Purchase Price Lists';
    CardPageID = "Purchase Price List";
    Editable = false;
    PageType = List;
    QueryCategory = 'Purchase Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = where("Source Group" = const(Vendor), "Price Type" = const(Purchase));
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
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and can be edited (when Allow Editing Active Price is enabled) and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list lines that contain default values from the header. This does not affect the ability to allow line or invoice discounts.';
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
                    Caption = 'Assign-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or projects.';
                }
                field(SourceType; CurrRec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign-to Type';
                    ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign-to';
                    ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
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
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

#if not CLEAN23
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
        OnAfterSetCurrRecOnAfterGetRecord(Rec, CurrRec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrRec := Rec;
        OnAfterSetCurrRecOnAfterGetCurrRecord(Rec, CurrRec);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrRecOnAfterGetRecord(var PriceListHeader: Record "Price List Header"; var PriceListHeaderCurrRec: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrRecOnAfterGetCurrRecord(var PriceListHeader: Record "Price List Header"; var PriceListHeaderCurrRec: Record "Price List Header")
    begin
    end;
}