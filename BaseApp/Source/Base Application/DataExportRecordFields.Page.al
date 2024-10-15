page 11027 "Data Export Record Fields"
{
    Caption = 'Data Export Record Fields';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Data Export Record Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the field that you have added to the record source.';
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = FlowFieldStyle;
                    ToolTip = 'Specifies the name of the field that is specified in the Field No. field.';
                }
                field("Field Type"; "Field Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type of the selected field.';
                }
                field("Field Class"; "Field Class")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = FlowFieldStyle;
                    ToolTip = 'Specifies the class of the specified field.';
                }
                field("Date Filter Handling"; "Date Filter Handling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the field Starting Date and Ending Date in the Export Business Data batch job, influence the calculation.';
                }
                field("Export Field Name"; "Export Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for the data from this field that can be accepted by the auditor''s tools.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Add ")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Add';
                Image = Add;
                ToolTip = 'Add the selected fields to the source table for data export.';

                trigger OnAction()
                var
                    "Field": Record "Field";
                    DataExportFieldList: Page "Data Export Field List";
                    DataExportCode: Code[10];
                    DataExportRecTypeCode: Code[10];
                    CurrGroup: Integer;
                    TableNo: Integer;
                    SelectedLineNo: Integer;
                    SourceLineNo: Integer;
                begin
                    CurrGroup := FilterGroup;
                    FilterGroup(4);
                    Evaluate(TableNo, GetFilter("Table No."));
                    Evaluate(SourceLineNo, GetFilter("Source Line No."));
                    DataExportCode := GetRangeMin("Data Export Code");
                    DataExportRecTypeCode := GetRangeMin("Data Exp. Rec. Type Code");
                    FilterGroup(CurrGroup);
                    Field.FilterGroup(4);
                    Field.SetRange(TableNo, TableNo);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    Field.SetFilter(Type, '%1|%2|%3|%4|%5|%6|%7',
                      Field.Type::Option, Field.Type::Text, Field.Type::Code, Field.Type::Integer, Field.Type::Decimal,
                      Field.Type::Date, Field.Type::Boolean);
                    Field.FilterGroup(0);

                    Clear(DataExportFieldList);
                    DataExportFieldList.SetTableView(Field);
                    DataExportFieldList.LookupMode := true;
                    if DataExportFieldList.RunModal = ACTION::LookupOK then begin
                        DataExportFieldList.SetSelectionFilter(Field);
                        SelectedLineNo := GetSelectedFieldsLineNo(DataExportCode, DataExportRecTypeCode, SourceLineNo);
                        InsertSelectedFields(Field, DataExportCode, DataExportRecTypeCode, SourceLineNo, SelectedLineNo);
                    end;
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Remove the selected fields from the data export.';

                trigger OnAction()
                var
                    DataExportRecordField: Record "Data Export Record Field";
                begin
                    CurrPage.SetSelectionFilter(DataExportRecordField);
                    DataExportRecordField.DeleteAll();
                end;
            }
            action(MoveUp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Image = MoveUp;
                ToolTip = 'Change the order of the selected field.';

                trigger OnAction()
                begin
                    MoveRecordUp(Rec);
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Image = MoveDown;
                ToolTip = 'Change the order of the selected field.';

                trigger OnAction()
                begin
                    MoveRecordDown(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "Field Class" = "Field Class"::FlowField then
            FlowFieldStyle := 'StandardAccent'
        else
            FlowFieldStyle := 'Normal';
    end;

    var
        FlowFieldStyle: Text[30];

    [Scope('OnPrem')]
    procedure GetSelectedFieldsLineNo(DataExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer) SelectedLineNo: Integer
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.SetRange("Data Export Code", DataExportCode);
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordField.SetRange("Source Line No.", SourceLineNo);
        if DataExportRecordField.IsEmpty then
            SelectedLineNo := 0
        else
            SelectedLineNo := "Line No.";
    end;
}

