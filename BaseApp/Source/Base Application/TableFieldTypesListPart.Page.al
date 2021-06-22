page 9622 "Table Field Types ListPart"
{
    Caption = 'Table Field Types ListPart';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Table Field Types";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Name displayed to users.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FieldType := Format(FieldTypeGroup);
    end;

    var
        FieldType: Text;

    procedure GetSelectedRecord(var TableFieldTypes: Record "Table Field Types")
    begin
        CurrPage.SetSelectionFilter(TableFieldTypes);
    end;

    procedure GetSelectedRecType(): Text
    begin
        exit(FieldType);
    end;
}

