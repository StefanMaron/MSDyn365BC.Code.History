#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AuditFileExport;
using System.Environment.Configuration;

page 11212 "SIE Dimensions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SIE Dimensions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "SIE Dimension";
    UsageCategory = Lists;
    ObsoleteReason = 'Replaced by Dimensions SIE page of the Standard Import Export (SIE) extension';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1070000)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Dimension CodeEditable";
                    ToolTip = 'Specifies a dimension code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = NameEditable;
                    ToolTip = 'Specifies a descriptive name for the dimension.';
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this dimension should be used when importing or exporting G/L data.';
                }
                field("SIE Dimension"; Rec."SIE Dimension")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "SIE DimensionEditable";
                    ToolTip = 'Specifies the number you want to assign to the dimension.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "SIE DimensionEditable" := true;
        NameEditable := true;
        "Dimension CodeEditable" := true;
    end;

    trigger OnOpenPage()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if FeatureKeyManagement.IsSIEAuditFileExportEnabled() then begin
            Page.Run(5315); // page 5315 "Dimensions SIE"
            Error('');
        end;

        if CurrPage.LookupMode then begin
            "Dimension CodeEditable" := false;
            NameEditable := false;
            "SIE DimensionEditable" := false;
        end;
    end;

    var
        "Dimension CodeEditable": Boolean;
        NameEditable: Boolean;
        "SIE DimensionEditable": Boolean;
}

#endif