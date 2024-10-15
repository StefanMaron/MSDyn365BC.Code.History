table 11766 "Statement File Mapping"
{
    Caption = 'Statement File Mapping';

    fields
    {
        field(3; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(4; "Schedule Line No."; Integer)
        {
            Caption = 'Schedule Line No.';
            TableRelation = "Acc. Schedule Line"."Line No." WHERE("Schedule Name" = FIELD("Schedule Name"));
        }
        field(5; "Schedule Column Layout Name"; Code[10])
        {
            Caption = 'Schedule Column Layout Name';
            TableRelation = "Column Layout Name".Name;
        }
        field(6; "Schedule Column No."; Integer)
        {
            Caption = 'Schedule Column No.';
            TableRelation = "Column Layout"."Line No." WHERE("Column Layout Name" = FIELD("Schedule Column Layout Name"));
        }
        field(8; "Excel Cell"; Code[50])
        {
            Caption = 'Excel Cell';
            CharAllowed = '09,R,C';

            trigger OnValidate()
            begin
                if "Excel Cell" <> '' then begin
                    TestRowColumn("Excel Cell");
                    StmtFileMapping.Reset();
                    StmtFileMapping.SetRange("Schedule Name", "Schedule Name");
                    StmtFileMapping.SetRange("Schedule Column Layout Name", "Schedule Column Layout Name");
                    StmtFileMapping.SetRange("Excel Cell", "Excel Cell");
                    StmtFileMapping.SetFilter("Schedule Line No.", '<>%1', "Schedule Line No.");
                    if StmtFileMapping.FindFirst then
                        if not Confirm(DuplicateQst, true, StmtFileMapping."Schedule Line No.", StmtFileMapping."Schedule Column No.") then
                            Error('');
                    StmtFileMapping.SetRange("Schedule Line No.");
                    StmtFileMapping.SetFilter("Schedule Column No.", '<>%1', "Schedule Column No.");
                    if StmtFileMapping.FindFirst then
                        if not Confirm(DuplicateQst, true, StmtFileMapping."Schedule Line No.", StmtFileMapping."Schedule Column No.") then
                            Error('');

                    Evaluate("Excel Row No.", CopyStr("Excel Cell", 2, Cpos - 2));
                    Evaluate("Excel Column No.", CopyStr("Excel Cell", Cpos + 1, StrLen("Excel Cell")));
                end else begin
                    "Excel Row No." := 0;
                    "Excel Column No." := 0;
                end;
            end;
        }
        field(10; "Excel Row No."; Integer)
        {
            Caption = 'Excel Row No.';
        }
        field(11; "Excel Column No."; Integer)
        {
            Caption = 'Excel Column No.';
        }
        field(20; Split; Option)
        {
            Caption = 'Split';
            OptionCaption = ' ,Right,Left';
            OptionMembers = " ",Right,Left;
        }
        field(21; Offset; Integer)
        {
            Caption = 'Offset';
        }
    }

    keys
    {
        key(Key1; "Schedule Name", "Schedule Line No.", "Schedule Column Layout Name", "Schedule Column No.", "Excel Cell")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        StmtFileMapping: Record "Statement File Mapping";
        CellFormatErr: Label 'Cell must be on format RxCy.';
        DuplicateQst: Label 'In line %1 and column %2 is same cell.\Continue?';
        Cpos: Integer;
        RowTxt: Label 'R', Comment = 'R';
        ColumnTxt: Label 'C', Comment = 'C';

    [Scope('OnPrem')]
    procedure TestRowColumn(Cell: Code[50])
    begin
        if CopyStr(Cell, 1, 1) <> RowTxt then
            Error(CellFormatErr);

        Cpos := StrPos(Cell, ColumnTxt);
        if Cpos < 3 then
            Error(CellFormatErr);
    end;
}

