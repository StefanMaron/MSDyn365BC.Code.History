page 17357 "Employee Attestation"
{
    AutoSplitKey = true;
    Caption = 'Employee Attestation';
    DataCaptionFields = "Person No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Employee Qualification";
    SourceTableView = WHERE("Qualification Type" = FILTER(Attestation));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Qualification Code"; "Qualification Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("From Date"; "From Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
            }
        }
    }

    actions
    {
    }
}

