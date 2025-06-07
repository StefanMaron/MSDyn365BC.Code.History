// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

using System.Reflection;

page 9640 "Column Picker"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Page Table Field";
    AboutTitle = 'About Column Picker';
    AboutText = 'Use this page to add columns from the list of available fields for the selected page or the source table if no page is selected. Choose the fields you want to insert and click ''OK'' to include them in the analysis view.';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(SourcePage; SourcePageName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show available fields from';
                ToolTip = 'Specifies source page name.';
                AboutTitle = 'About the source page';
                AboutText = 'Displays the list of card and list pages that have the selected table as source. Select a page to view the fields available for that page.';
                Visible = AreTherePagesAvailable;
                InstructionalText = 'Select a page, or leave blank for all fields';
                LookupPageId = "List and Card page picker";
                TableRelation = "Page Metadata" where(SourceTable = field("Table No"),
                                                        PageType = filter('0|1'));

                trigger OnAfterLookup(Selected: RecordRef)
                var
                    PageMetadata: Record "Page Metadata";
                begin
                    Selected.SetTable(PageMetadata);
                    SourcePageName := PageMetadata.Caption;
                    ColumnPickerHelper.FilterAfterLookup(PageMetadata.ID, Rec);
                    CurrPage.Update();
                end;
            }

            field(Warning; UsingTableAsSourceMsg)
            {
                Visible = not AreTherePagesAvailable;
                ShowCaption = false;
                ApplicationArea = All;
                Editable = false;
                Style = Strong;
            }

            repeater(GroupName)
            {
                Editable = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table field id.';
                }
                field("Field ID"; Rec."Table Field Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field name.';
                }
                field(Example; Example)
                {
                    ApplicationArea = All;
                    Caption = 'Example';
                    Style = Subordinate;
                    ToolTip = 'Specifies an example value for the table field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description for the field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ColumnPickerHelper.Initialize(Rec);
        CurrPage.Caption := StrSubstNo(InsertColumnMsg, ColumnPickerHelper.GetRelatedTableName());
        AreTherePagesAvailable := ColumnPickerHelper.GetAreTherePagesAvailable();
    end;

    trigger OnAfterGetRecord()
    begin
        Example := ColumnPickerHelper.GetExampleValue(Rec."Table Field Id");
    end;

    var
        ColumnPickerHelper: Codeunit "Column Picker Helper";
        UsingTableAsSourceMsg: Label 'There are no list or card pages for the selected table, showing table fields instead.';
        InsertColumnMsg: Label 'Insert column(s) from %1', Comment = '%1 = The table name to insert columns from.';
        SourcePageName: Text;
        Example: Text;
        AreTherePagesAvailable: Boolean;
}