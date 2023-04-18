query 762 "Acc. Sched. Line Desc. Count"
{
    Caption = 'Acc. Sched. Line Desc. Count';

    elements
    {
        dataitem(Acc_Schedule_Line; "Acc. Schedule Line")
        {
            column(Schedule_Name; "Schedule Name")
            {
            }
            column(Description; Description)
            {
                ColumnFilter = Description = FILTER(<> '');
            }
            column(Count_)
            {
                ColumnFilter = Count_ = FILTER(> 1);
                Method = Count;
            }
        }
    }
}

