// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Reflection;

page 11000013 "Objects (Telebanking)"
{
    Caption = 'Objects';
    PageType = List;
    SourceTable = "Object";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with the AL Objects (Telebanking) page';
    ObsoleteTag = '15.2';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the object.';
                    Visible = TypeVisible;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object.';
                }
                field(Modified; Rec.Modified)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the object was last modified.';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the object was added.';
                    Visible = false;
                }
                field("Version List"; Rec."Version List")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Telebanking object versions.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        TypeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := Rec.GetFilter(Type) = '';
    end;

    var
        TypeVisible: Boolean;
}

