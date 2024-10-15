﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

#pragma warning disable AS0030
page 323 "EC Sales List Reports"
#pragma warning restore AS0030
{
    ApplicationArea = VAT;
    Caption = 'EC Sales List Reports';
    CardPageID = "ECSL Report";
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the appropriate configuration code for EC Sales List Reports.';
                    Visible = false;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the first date of the reporting period.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the last date of the EC sales list report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the status of the report.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Original Report No."; Rec."Original Report No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the original report.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the ECSL report.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = VAT;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Report Setup_Promoted"; "Report Setup")
                {
                }
            }
        }
    }
}

