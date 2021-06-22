page 709 "Error Message Register"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Error Message Register';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Error Message Register";
    SourceTableView = SORTING("Created On")
                      ORDER(Descending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Created On"; "Created On")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Errors; Errors)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Error);
                    end;
                }
                field(Warnings; Warnings)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Warning);
                    end;
                }
                field(Information; Information)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Information);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Show)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show';
                Image = ShowList;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Open the list of all error messages related to the current register record.';

                trigger OnAction()
                begin
                    DrillDownErrors(MessageType::All);
                end;
            }
        }
    }

    var
        MessageType: Option Error,Warning,Information,All;

    local procedure DrillDownErrors(Type: Option)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
    begin
        ErrorMessage.SetRange("Register ID", ID);
        if Type <> MessageType::All then
            ErrorMessage.SetRange("Message Type", Type);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessages.RunModal;
    end;
}

