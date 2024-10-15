namespace System.DataAdministration;

using System.Diagnostics;

page 9521 "Database Missing Indexes"
{
    Caption = 'Database Missing Indexes';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Database Missing Indexes";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'This page shows indexes that the SQL query optimizer suggests are added to the database. See the SQL documentation on sys.dm_db_missing_index_details for more information on missing indexes.';
                ShowCaption = false;
            }
            repeater(Group)
            {
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    ToolTip = 'Name of the table on the database.';
                }
                field("Extension Id"; Rec."Extension Id")
                {
                    ApplicationArea = All;
                    Caption = 'Extension Id';
                    ToolTip = 'Id of the extension that table belongs to.';
                }
                field("Index Equality Columns"; Rec."Index Equality Columns")
                {
                    ApplicationArea = All;
                    Caption = 'Index Equality Columns';
                    ToolTip = 'A list of columns that are used in WHERE equality predicates in the SQL query needing the index.';
                }
                field("Index Inequality Columns"; Rec."Index Inequality Columns")
                {
                    ApplicationArea = All;
                    Caption = 'Index Inequality Columns';
                    ToolTip = 'A list of columns that are used in WHERE inequality predicates (such as < or >) or ORDER BY in the SQL query needing the index.';
                }
                field("Index Include Columns"; Rec."Index Include Columns")
                {
                    ApplicationArea = All;
                    Caption = 'Index Include Columns';
                    ToolTip = 'A list of columns that are part of the SELECT clause in the SQL query needing the index.';
                }
            }
        }
    }

    actions
    {
    }
}