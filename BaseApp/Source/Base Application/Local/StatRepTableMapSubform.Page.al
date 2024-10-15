page 26593 "Stat. Rep. Table Map. Subform"
{
    Caption = 'Stat. Rep. Table Map. Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Stat. Report Table Row";

    layout
    {
    }

    actions
    {
    }

    var
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        CellValue: Text[250];

    [Scope('OnPrem')]
    procedure UpdateForm(ReportCode: Code[20]; TableCode: Code[20])
    begin
    end;
}

