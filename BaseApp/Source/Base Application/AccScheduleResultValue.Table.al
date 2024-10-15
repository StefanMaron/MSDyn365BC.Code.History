table 31087 "Acc. Schedule Result Value"
{
    Caption = 'Acc. Schedule Result Value';

    fields
    {
        field(1; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
            TableRelation = "Acc. Schedule Result Header";
        }
        field(2; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(4; Value; Decimal)
        {
            Caption = 'Value';

            trigger OnValidate()
            begin
                AddChangeHistoryEntry;
            end;
        }
    }

    keys
    {
        key(Key1; "Result Code", "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Validate(Value, 0);
    end;

    [Scope('OnPrem')]
    procedure AddChangeHistoryEntry()
    var
        AccScheduleResultHistory: Record "Acc. Schedule Result History";
        VariantNo: Integer;
    begin
        AccScheduleResultHistory.SetRange("Result Code", "Result Code");
        AccScheduleResultHistory.SetRange("Row No.", "Row No.");
        AccScheduleResultHistory.SetRange("Column No.", "Column No.");
        if AccScheduleResultHistory.FindLast then;
        VariantNo := AccScheduleResultHistory."Variant No." + 1;

        AccScheduleResultHistory.Init();
        AccScheduleResultHistory."Result Code" := "Result Code";
        AccScheduleResultHistory."Row No." := "Row No.";
        AccScheduleResultHistory."Column No." := "Column No.";
        AccScheduleResultHistory."Variant No." := VariantNo;
        AccScheduleResultHistory."New Value" := Value;
        AccScheduleResultHistory."Old Value" := xRec.Value;
        AccScheduleResultHistory.Insert(true);
    end;
}

