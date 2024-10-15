page 17354 "Person Medical Information"
{
    Caption = 'Person Medical Information';
    DataCaptionFields = "Employee No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Person Medical Info";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Insurer No."; "Insurer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Polyclinic Name"; "Polyclinic Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Stomatology; Stomatology)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Antenatal Clinic"; "Antenatal Clinic")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Police No."; "Police No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Disability Group"; "Disability Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("TEK Type"; "TEK Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("TEK Document No."; "TEK Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("TEK Document Date"; "TEK Document Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

