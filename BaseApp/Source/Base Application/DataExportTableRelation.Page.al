page 11007 "Data Export Table Relation"
{
    Caption = 'Data Export Table Relationship';
    DataCaptionExpression = GetCaption;
    DataCaptionFields = "Data Exp. Rec. Type Code";
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Data Export Record Source";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Relation To Table No."; "Relation To Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From Table No.';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the parent table associated with this table.';
                }
                field("Relation To Table Name"; "Relation To Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From Table Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the table that is specified in the Relation To Table No. field.';
                }
                field(ToTableID; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Table No.';
                    Editable = false;
                    Lookup = false;
                    LookupPageID = Objects;
                    TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));
                    ToolTip = 'Specifies the number of the table that you selected for the record source.';
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Table Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the table that you selected in the Table No. field.';
                }
            }
            part(Relationships; "Data Export Table Relation Sub")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Relationships';
                SubPageLink = "Data Export Code" = FIELD("Data Export Code"),
                              "Data Exp. Rec. Type Code" = FIELD("Data Exp. Rec. Type Code"),
                              "From Table No." = FIELD("Relation To Table No."),
                              "To Table No." = FIELD("Table No.");
                SubPageView = SORTING("Data Export Code", "Data Exp. Rec. Type Code", "From Table No.", "From Field No.", "To Table No.", "To Field No.");
            }
        }
    }

    actions
    {
    }

    local procedure GetCaption(): Text[250]
    var
        DataExportRecordType: Record "Data Export Record Type";
    begin
        if DataExportRecordType.Get("Data Exp. Rec. Type Code") then
            exit(DataExportRecordType.Code + ' ' + DataExportRecordType.Description);
    end;
}

