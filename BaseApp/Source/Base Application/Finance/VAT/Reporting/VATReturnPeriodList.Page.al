﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 737 "VAT Return Period List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Return Periods';
    CardPageID = "VAT Return Period Card";
    PageType = List;
    SourceTable = "VAT Return Period";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                Editable = IsEditable;
                ShowCaption = false;
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the VAT return period.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the VAT return period.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = WarningStyleExpr;
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = WarningStyleExpr;
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
                field("Received Date"; Rec."Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT return period received date.';
                }
            }
        }
        area(factboxes)
        {
            part(Control9; "VAT Return Period FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get VAT Return Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get VAT Return Periods';
                Image = GetLines;
                ToolTip = 'Load the VAT return periods that are set up in the system.';
                Visible = not IsEditable;
            }
            action("Create VAT Return")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create VAT Return';
                Enabled = CreateVATReturnEnabled;
                Image = RefreshLines;
                ToolTip = 'Create a new VAT return from the selected VAT return period.';
            }
        }
        area(navigation)
        {
            action("Open VAT Return Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open VAT Return Card';
                Enabled = OpenVATReturnEnabled;
                Image = ShowList;
                ToolTip = 'Open the VAT return card for the selected VAT return period.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Get VAT Return Periods_Promoted"; "Get VAT Return Periods")
                {
                }
                actionref("Create VAT Return_Promoted"; "Create VAT Return")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        InitPageControllers();
    end;

    trigger OnAfterGetRecord()
    begin
        InitPageControllers();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not IsEditable then
            Error('');
    end;

    trigger OnOpenPage()
    begin
        VATReportSetup.Get();
        IsEditable := VATReportSetup."Manual Receive Period CU ID" = 0;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        WarningStyleExpr: Text;
        CreateVATReturnEnabled: Boolean;
        OpenVATReturnEnabled: Boolean;
        IsEditable: Boolean;

    local procedure InitPageControllers()
    begin
        CreateVATReturnEnabled := Rec.Status = Rec.Status::Open;
        OpenVATReturnEnabled := true;
        Rec.CheckOpenOrOverdue();
    end;
}
