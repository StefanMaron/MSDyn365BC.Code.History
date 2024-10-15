page 2000043 "CODA Statement Info"
{
    Caption = 'CODA Statement Info';
    Editable = false;
    PageType = List;
    SourceTable = "CODA Statement Line";
    SourceTableView = SORTING("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Statement Message"; "Statement Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message as reflected on the bank account statement.';
                }
            }
        }
    }

    actions
    {
    }
}

