#if not CLEAN23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using System.Environment.Configuration;

pageextension 7049 "Price Calc. Update Parameters" extends "Schedule Feature Data Update"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'SalesPrice feature will be enabled by default in version 22.0.';
#pragma warning disable AS0072
    ObsoleteTag = '19.0';
#pragma warning restore AS0072

    layout
    {
        addbefore(Review)
        {
            group(PriceCalc)
            {
                ShowCaption = false;
                Visible = SalesPrices;
                ObsoleteState = Pending;
                ObsoleteReason = 'SalesPrice feature will be enabled by default in version 22.0.';
                ObsoleteTag = '19.0';
                field("Use Default Price Lists"; Rec."Use Default Price Lists")
                {
                    ApplicationArea = All;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'SalesPrice feature will be enabled by default in version 22.0.';
#pragma warning disable AS0072
                    ObsoleteTag = '19.0';
#pragma warning restore AS0072
                    ToolTip = 'Specifies if the old pricing data should be split to separate price lists.';
                    trigger OnValidate()
                    begin
                        SetSplitDataDescription();
                    end;
                }
                field(SplitDataDescription; SplitDataDescription)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Visible = SplitDataDescription <> '';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the description of how "Split Data to Price Lists" affects the data update task.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'SalesPrice feature will be enabled by default in version 22.0.';
#pragma warning disable AS0072
                    ObsoleteTag = '19.0';
#pragma warning restore AS0072
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SalesPrices := FeatureDataUpdateMgt.FeatureKeyMatches(Rec, Enum::"Feature To Update"::SalesPrices);
        if SalesPrices then begin
            Rec."Use Default Price Lists" := true;
            Rec.Modify();
            SetSplitDataDescription();
        end;
    end;

    var
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        SplitDataDescription: Text;
        SalesPrices: Boolean;
        DefaultDescriptionMsg: Label 'Existing prices will be converted to default price lists per areas (sales, purchase, and jobs) allowing you to edit prices as in old experience.';
        SplitDescriptionMsg: Label 'Existing prices will be converted to new price lists according to what they apply to, what starting and ending dates they have, currencies, units of measure, and minimum quantity.';

    local procedure SetSplitDataDescription()
    begin
        if Rec."Use Default Price Lists" then
            SplitDataDescription := DefaultDescriptionMsg
        else
            SplitDataDescription := SplitDescriptionMsg;
    end;
}
#endif