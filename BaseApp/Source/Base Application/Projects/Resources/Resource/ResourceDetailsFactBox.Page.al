namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
#if not CLEAN25
using Microsoft.Projects.Resources.Pricing;
#endif

page 9108 "Resource Details FactBox"
{
    Caption = 'Resource Details';
    PageType = CardPart;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource No.';
                ToolTip = 'Specifies a number for the resource.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
#if not CLEAN25
            field(NoOfResourcePrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Prices';
                DrillDown = true;
                Editable = true;
                Visible = not ExtendedPriceEnabled;
                ToolTip = 'Specifies the resource prices.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '16.0';

                trigger OnDrillDown()
                var
                    RescPrice: Record "Resource Price";
                begin
                    RescPrice.SetRange(Type, RescPrice.Type::Resource);
                    RescPrice.SetRange(Code, Rec."No.");

                    PAGE.Run(PAGE::"Resource Prices", RescPrice);
                end;
            }
            field(NoOfResourceCosts; NoOfResourceCosts)
            {
                ApplicationArea = Jobs;
                Caption = 'Costs';
                DrillDown = true;
                Editable = true;
                Visible = not ExtendedPriceEnabled;
                ToolTip = 'Specifies detailed information about costs for the resource.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '17.0';

                trigger OnDrillDown()
                var
                    RescCost: Record "Resource Cost";
                begin
                    RescCost.SetRange(Type, RescCost.Type::Resource);
                    RescCost.SetRange(Code, Rec."No.");

                    PAGE.Run(PAGE::"Resource Costs", RescCost);
                end;
            }
#endif
            field(NoOfResPrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Prices';
                DrillDown = true;
                Editable = true;
                Visible = ExtendedPriceEnabled;
                ToolTip = 'Specifies the resource prices.';

                trigger OnDrillDown()
                begin
                    Rec.ShowPriceListLines(Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Any);
                end;
            }
            field(NoOfResCosts; NoOfResourceCosts)
            {
                ApplicationArea = Jobs;
                Caption = 'Costs';
                DrillDown = true;
                Editable = true;
                Visible = ExtendedPriceEnabled;
                ToolTip = 'Specifies detailed information about costs for the resource.';

                trigger OnDrillDown()
                begin
                    Rec.ShowPriceListLines(Enum::"Price Type"::Purchase, Enum::"Price Amount Type"::Any);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcNoOfRecords();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfResourcePrices := 0;
        NoOfResourceCosts := 0;

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        CalcNoOfRecords();
    end;

    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        NoOfResourcePrices: Integer;
        NoOfResourceCosts: Integer;
        ExtendedPriceEnabled: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Resource Card", Rec);
    end;

    local procedure CalcNoOfRecords()
    var
        PriceListLine: Record "Price List Line";
    begin
#if not CLEAN25
        if CalcOldNoOfRecords() then
            exit;
#endif
        PriceListLine.SetRange(Status, Enum::"Price Status"::Active);
        PriceListLine.SetRange("Asset Type", Enum::"Price Asset Type"::Resource);
        PriceListLine.SetRange("Asset No.", Rec."No.");
        PriceListLine.SetRange("Price Type", Enum::"Price Type"::Sale);
        NoOfResourcePrices := PriceListLine.Count();

        PriceListLine.SetRange("Price Type", Enum::"Price Type"::Purchase);
        NoOfResourceCosts := PriceListLine.Count();
    end;

#if not CLEAN25
    local procedure CalcOldNoOfRecords(): Boolean;
    var
        ResourcePrice: Record "Resource Price";
        ResourceCost: Record "Resource Cost";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(false);

        ResourcePrice.Reset();
        ResourcePrice.SetRange(Type, ResourcePrice.Type::Resource);
        ResourcePrice.SetRange(Code, Rec."No.");
        NoOfResourcePrices := ResourcePrice.Count();

        ResourceCost.Reset();
        ResourceCost.SetRange(Type, ResourceCost.Type::Resource);
        ResourceCost.SetRange(Code, Rec."No.");
        NoOfResourceCosts := ResourceCost.Count();
        exit(true);
    end;
#endif
}

