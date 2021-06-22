query 763 "Colm. Layt. Colm. Header Count"
{
    Caption = 'Colm. Layt. Colm. Header Count';

    elements
    {
        dataitem(Column_Layout; "Column Layout")
        {
            column(Column_Layout_Name; "Column Layout Name")
            {
            }
            column(Column_Header; "Column Header")
            {
            }
            column(Count_)
            {
                ColumnFilter = Count_ = FILTER(> 1);
                Method = Count;
            }
        }
    }
}

