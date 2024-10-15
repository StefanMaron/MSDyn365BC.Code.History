table 342 "Acc. Sched. Cell Value"
{
    Caption = 'Acc. Sched. Cell Value';
#if CLEAN21
    TableType = Temporary;
#else
    ObsoleteReason = 'This table will be marked as temporary. Make sure you are not using this table to store records.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
        field(31080; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
#if CLEAN21
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'The field is not used anymore.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
#if CLEAN21
        key(Key1; "Row No.", "Column No.")
#else
        key(Key1; "Schedule Name", "Row No.", "Column No.")
#endif
        {
            Clustered = true;
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteReason = 'The obsoleted fields will be removed from primary key.';
            ObsoleteTag = '21.0';
#endif
        }
    }

    fieldgroups
    {
    }

#if not CLEAN21
    [Obsolete('Use the Get function without the "Schedule Name" parameter instead. This field is obsolete and will be removed from primary key.', '21.0')]
    procedure Get(ScheduleName: Code[10]; RowNo: Integer; ColumnNo: Integer) Result: Boolean
    var
        TempAccSchedCellValue: Record "Acc. Sched. Cell Value" temporary;
    begin
        TempAccSchedCellValue.CopyFilters(Rec);
        Reset();
        SetRange("Row No.", RowNo);
        SetRange("Column No.", ColumnNo);
        if Count() > 1 then
            SetRange("Schedule Name", ScheduleName);
        Result := FindFirst();
        CopyFilters(TempAccSchedCellValue);
    end;

    [Obsolete('You can ignore this warning. This function will be replaced by built-in Get function.', '21.0')]
    procedure Get(RowNo: Integer; ColumnNo: Integer) Result: Boolean
    begin
        exit(Get('', RowNo, ColumnNo));
    end;
#endif
}

