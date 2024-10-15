page 11009 "Data Export Field List"
{
    Caption = 'Data Export Field List';
    DataCaptionExpression = GetCaption;
    Editable = false;
    PageType = List;
    SourceTable = "Field";
    SourceTableView = SORTING(TableNo, "No.");

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Field No.';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the number of field that holds the data to be exported.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the name of field that holds the data to be exported.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the type.';
                }
                field(Class; Class)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Class';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the class of the field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if Class = Class::FlowField then
            ClassColumnStyle := 'StandardAccent'
        else
            ClassColumnStyle := 'Normal';
    end;

    var
        ClassColumnStyle: Text[30];

    local procedure GetCaption(): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableNo) then
            exit(Format(TableNo) + ' ' + AllObjWithCaption."Object Caption");

        exit('');
    end;
}

