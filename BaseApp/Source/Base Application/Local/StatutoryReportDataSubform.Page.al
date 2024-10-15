page 26564 "Statutory Report Data Subform"
{
    Caption = 'Statutory Report Data Subform';
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
        Text001: Label '* ERROR *';
        StatutoryReportTable: Record "Statutory Report Table";
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
        StatReportTableColumn: Record "Stat. Report Table Column";
        TempColumnLayout: Record "Stat. Report Table Column" temporary;
        ReportResultRow: Record "Stat. Report Table Row";
        TempReportResultRow: Record "Stat. Report Table Row" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        ShowError: Option "None","Division by Zero","Period Error",Both;
        CellValue: Text[150];
        ExcelSheetName: Text[30];
        Text004: Label 'Not Available';
        ShowOnlyChangedValues: Boolean;
        ResultsCode: Code[20];

    [Scope('OnPrem')]
    procedure UpdateForm(NewResultCode: Code[20]; NewTableName: Code[20]; NewExcelSheetName: Text[30]; NewShowOnlyChangedValues: Boolean)
    begin
    end;
}

