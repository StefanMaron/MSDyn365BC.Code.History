#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AutomaticAccounts;

using System.Telemetry;
using System.Environment.Configuration;

page 11208 "Automatic Acc. List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Automatic Account Groups';
    CardPageID = "Automatic Acc. Header";
    Editable = false;
    PageType = List;
    SourceTable = "Automatic Acc. Header";
    UsageCategory = Lists;
    ObsoleteReason = 'Moved to Automatic Account Codes app.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1070002)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the automatic account group number in this field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an appropriate description of the automatic account group in this field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureKeyManagemnt: Codeunit "Feature Key Management";
    begin
        FeatureTelemetry.LogUptake('0001P8Z', AccTok, Enum::"Feature Uptake Status"::Discovered);
        if FeatureKeyManagemnt.IsAutomaticAccountCodesEnabled() then begin
            Page.Run(4852); // page 4852 "Automatic Account List"
            Error('');
        end;
    end;

    var
        AccTok: Label 'SE Automatic Account', Locked = true;
}
#endif
