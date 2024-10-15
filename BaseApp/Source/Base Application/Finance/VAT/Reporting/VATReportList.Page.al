// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;

page 744 "VAT Report List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Returns';
    CardPageID = "VAT Report";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    SourceTableView = where("VAT Report Config. Code" = const("VAT Return"));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("VAT Report Config. Code"; Rec."VAT Report Config. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the appropriate configuration code.';
                    Visible = false;
                }
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"VAT Report Header"), "No." = field("No."), "VAT Report Config. Code" = field("VAT Report Config. Code");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Create From VAT Return Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create From VAT Return Period';
                Image = GetLines;
                ToolTip = 'Create a new VAT return from an existing VAT return period.';

                trigger OnAction()
                var
                    VATReturnPeriod: Record "VAT Return Period";
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    if PAGE.RunModal(0, VATReturnPeriod) = ACTION::LookupOK then
                        VATReportMgt.CreateVATReturnFromVATPeriod(VATReturnPeriod);
                end;
            }
        }
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
                action("Open VAT Return Period Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open VAT Return Period Card';
                    Image = ShowList;
                    ToolTip = 'Open the VAT return period card for the selected VAT return.';
                    Visible = ReturnPeriodEnabled;

                    trigger OnAction()
                    var
                        VATReportMgt: Codeunit "VAT Report Mgt.";
                    begin
                        VATReportMgt.OpenVATPeriodCardFromVATReturn(Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Create From VAT Return Period_Promoted"; "Create From VAT Return Period")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Report Setup_Promoted"; "Report Setup")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReturnPeriodEnabled := Rec."Return Period No." <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        ReturnPeriodEnabled := Rec."Return Period No." <> '';
    end;

    var
        ReturnPeriodEnabled: Boolean;
}

