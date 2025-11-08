#if not CLEAN28
// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

page 9642 "Table Relations Picker"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Table Relations Buffer";
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
    ObsoleteReason = 'The Analysis View module is being moved to be part of the Business Central platform.';
    Caption = 'Choose a source page';
    Editable = false;
    ShowFilter = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Table Name"; Rec."Table Name")
                {
                    ToolTip = 'Specifies the table name.';
                }
                field("Related Table Name"; Rec."Related Table Name")
                {
                    ToolTip = 'Specifies the related table name.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ToolTip = 'Specifies the field name.';
                }
                field("Related Field Name"; Rec."Related Field Name")
                {
                    ToolTip = 'Specifies the related field name.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Rec.PopulateFields(Rec."Table ID");
        CurrPage.Update();
    end;
}
#endif