// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

page 6635 "Return Reasons"
{
    ApplicationArea = SalesReturnOrder;
    Caption = 'Return Reasons';
    PageType = List;
    SourceTable = "Return Reason";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the description of the return reason.';
                }
                field("Default Location Code"; Rec."Default Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location where items that are returned for the reason in question are always placed.';
                }
                field("Inventory Value Zero"; Rec."Inventory Value Zero")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies that items that are returned for the reason in question do not increase the inventory value.';
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
    }
}

