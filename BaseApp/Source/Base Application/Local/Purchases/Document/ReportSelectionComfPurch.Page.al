// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 5005391 "Report Selection - Comf. Purch"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Comf. Purch';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "DACH Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ReportUsage2; ReportUsage2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Usage';
                    OptionCaption = 'Del. Rem. Test,Iss. Del. Rem.';
                    ToolTip = 'Specifies the report object that must run when you print.';

                    trigger OnValidate()
                    begin
                        SetUsageFilter();
                        ReportUsage2OnAfterValidate();
                    end;
                }
            }
            repeater(Control1140002)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where a report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that prints for this document type.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the name of the report that prints for this document type.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter();
    end;

    var
        ReportUsage2: Option "Delivery Reminder Test","Issued Delivery Reminder";

    local procedure SetUsageFilter()
    begin
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Delivery Reminder Test":
                Rec.SetRange(Usage, Rec.Usage::"Delivery Reminder Test");
            ReportUsage2::"Issued Delivery Reminder":
                Rec.SetRange(Usage, Rec.Usage::"Issued Delivery Reminder");
        end;
        Rec.FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

