tableextension 11751 "Acc. Schedule Line CZL" extends "Acc. Schedule Line"
{
    fields
    {
        field(31070; "Calc CZL"; Enum "Accounting Schedule Calc CZL")
        {
            Caption = 'Calc';
            DataClassification = CustomerContent;
        }
        field(31071; "Row Correction CZL"; Code[10])
        {
            Caption = 'Row Correction';
            DataClassification = CustomerContent;
        }
        field(31072; "Assets/Liabilities Type CZL"; Enum "Assets Liabilities Type CZL")
        {
            Caption = 'Assets/Liabilities Type';
            DataClassification = CustomerContent;
        }
    }

    trigger OnDelete()
    var
        AccScheduleFileMappingCZL: Record "Acc. Schedule File Mapping CZL";
    begin
        AccScheduleFileMappingCZL.SetRange("Schedule Name", "Schedule Name");
        AccScheduleFileMappingCZL.SetRange("Schedule Line No.", "Line No.");
        AccScheduleFileMappingCZL.DeleteAll();
    end;
}
