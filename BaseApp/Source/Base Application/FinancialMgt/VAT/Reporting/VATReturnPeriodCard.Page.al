// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 738 "VAT Return Period Card"
{
    Caption = 'VAT Return Period';
    Editable = false;
    SourceTable = "VAT Return Period";

    layout
    {
        area(content)
        {
            group("Period Info")
            {
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
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
                field("Received Date"; Rec."Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT return period received date.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Receive Submitted VAT Returns")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receive Submitted VAT Returns';
                Image = RefreshLines;
                ToolTip = 'Receive the VAT returns that have been submitted.';
                Visible = IsReceiveSubmittedEnabled;
            }
            action("Create VAT Return")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create VAT Return';
                Enabled = CreateVATReturnEnabled;
                Image = RefreshLines;
                ToolTip = 'Create a new VAT return from this VAT return period.';
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
                ToolTip = 'Open the VAT return card for this VAT return period.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Receive Submitted VAT Returns_Promoted"; "Receive Submitted VAT Returns")
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

    trigger OnOpenPage()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        IsReceiveSubmittedEnabled := VATReportSetup."Receive Submitted Return CU ID" <> 0;
    end;

    var
        CreateVATReturnEnabled: Boolean;
        OpenVATReturnEnabled: Boolean;
        IsReceiveSubmittedEnabled: Boolean;

    local procedure InitPageControllers()
    begin
        CreateVATReturnEnabled := Rec.Status = Rec.Status::Open;
        OpenVATReturnEnabled := true;
    end;
}

