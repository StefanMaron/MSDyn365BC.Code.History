page 17373 "Employee Job Entry"
{
    Caption = 'Employee Job Entry';
    DataCaptionFields = "Employee No.";
    Editable = false;
    PageType = List;
    SourceTable = "Employee Job Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Supplement No."; "Supplement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Position Changed"; "Position Changed")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Position No."; "Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Insured Period Starting Date"; "Insured Period Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Period Ending Date"; "Insured Period Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Uninterrupted Service"; "Uninterrupted Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Speciality Code"; "Speciality Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Speciality Name"; "Speciality Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Position Rate"; "Position Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Worktime Norm"; "Worktime Norm")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use Trial Period"; "Use Trial Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trial Period"; "Trial Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Liability for Breakage"; "Liability for Breakage")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Hire Conditions"; "Hire Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Territorial Conditions"; "Territorial Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Conditions"; "Special Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Work Mode"; "Work Mode")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Working Schedule"; "Working Schedule")
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

