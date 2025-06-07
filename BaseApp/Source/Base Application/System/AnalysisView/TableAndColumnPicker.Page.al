// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

page 9643 "Table and Column Picker"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Table Relations Buffer";
    Caption = 'Insert column(s)';
    DataCaptionExpression = '';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(SourceTable; RelatedTableName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Source table';
                Editable = not IsTableSet;
                ToolTip = 'Specifies source table name.';
                InstructionalText = 'Select a table to join';
                AboutTitle = 'About the source table';
                AboutText = 'Displays the list of related tables from which fields can be added, along with the type of data join performed. These are the tables linked to the current page''s source table through the TableRelation property. Select a table to view its available fields.';
                TableRelation = "Table Relations Buffer" where("Table ID" = field("Table ID"));
                LookupPageId = "Table Relations Picker";

                trigger OnAfterLookup(Selected: RecordRef)
                var
                    TableRelationsBuffer: Record "Table Relations Buffer";
                begin
                    Selected.SetTable(TableRelationsBuffer);
                    IsTableSet := true;

                    RelatedTableName := StrSubstNo(TableRelationNameLbl, TableRelationsBuffer."Related Table Name", TableRelationsBuffer."Field Name", TableRelationsBuffer."Related Field Name");

                    Rec.SetFilter("Related Table ID", '%1', TableRelationsBuffer."Related Table ID");
                    CurrPage.Update(false);
                end;
            }

            part(ColumnPicker; "Column Picker Part")
            {
                Visible = IsTableSet;
                UpdatePropagation = Both;
                ApplicationArea = All;
                SubPageLink = "Table No" = field("Related Table ID");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Rec.PopulateFields(Rec."Table ID");
    end;

    var
        TableRelationNameLbl: Label '%1 - Via: %2 = %3', Comment = '%1 = Related Table Name, %2 = Field Name, %3 = Related Field Name';
        RelatedTableName: Text[250];
        IsTableSet: Boolean;
}