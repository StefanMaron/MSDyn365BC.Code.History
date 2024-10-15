page 17487 "Person Job History"
{
    Caption = 'Person Job History';
    PageType = List;
    SourceTable = "Person Job History";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Person No."; "Person No.")
                {
                    Visible = false;
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
                field("Employer Name"; "Employer Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Period Starting Date"; "Insured Period Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Period Ending Date"; "Insured Period Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unbroken Record of Service"; "Unbroken Record of Service")
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
                field("Hire Conditions"; "Hire Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Work Mode"; "Work Mode")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
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
                field("Record of Service Reason"; "Record of Service Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Record of Service Additional"; "Record of Service Additional")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Service Years Reason"; "Service Years Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        RecordMgt.CalcPersonTotalService("Person No.", false, TotalService);
        RecordMgt.CalcPersonInsuredService("Person No.", InsuredService);
        RecordMgt.CalcPersonTotalService("Person No.", true, UnbrokenService);
        RecordMgt.UpdatePersonService("Person No.", TotalService, InsuredService, UnbrokenService);
    end;

    var
        RecordMgt: Codeunit "Record of Service Management";
        TotalService: array[3] of Integer;
        InsuredService: array[3] of Integer;
        UnbrokenService: array[3] of Integer;
}

