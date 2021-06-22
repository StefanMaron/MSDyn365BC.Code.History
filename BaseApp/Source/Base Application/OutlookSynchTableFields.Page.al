page 5309 "Outlook Synch. Table Fields"
{
    Caption = 'Outlook Synch. Table Fields';
    DataCaptionExpression = GetFormCaption;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Field";
    SourceTableView = SORTING(TableNo, "No.")
                      WHERE(Enabled = CONST(true),
                            Class = FILTER(<> FlowFilter));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(TableNo; TableNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table No.';
                    ToolTip = 'Specifies the number of the table.';
                    Visible = false;
                }
                field(TableName; TableName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Name';
                    ToolTip = 'Specifies the name of the table.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the field.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.';
                }
                field(FieldName; FieldName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field that will be synchronized.';
                    Visible = false;
                }
                field(Class; Class)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Class';
                    ToolTip = 'Specifies the class of the field that will be synchronized.';
                }
                field("Type Name"; "Type Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type Name';
                    ToolTip = 'Specifies the type name of the field that will be synchronized.';
                }
                field(RelationTableNo; RelationTableNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relation Table No.';
                    ToolTip = 'Specifies the number of any related table.';
                    Visible = false;
                }
                field(RelationFieldNo; RelationFieldNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relation Field No.';
                    ToolTip = 'Specifies the number of any related field.';
                    Visible = false;
                }
                field(SQLDataType; SQLDataType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SQL Data Type';
                    ToolTip = 'Specifies the SQL data type.';
                    Visible = false;
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

    procedure GetFormCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2', TableNo, TableName));
    end;
}

