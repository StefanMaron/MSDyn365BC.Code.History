#if not CLEAN18
page 31125 "EET Entry Status Log"
{
    Caption = 'EET Entry Status Log (Obsolete)';
    DataCaptionFields = "EET Entry No.";
    Editable = false;
    PageType = List;
    SourceTable = "EET Entry Status";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Change Datetime"; "Change Datetime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time of the last status change for the EET entry.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current state of the EET entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("EET Entry No."; "EET Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related EET entry number.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
            }
        }
        area(factboxes)
        {
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Errors and Warnings';
                ShowFilter = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowErrors;
    end;

    local procedure ShowErrors()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update;
    end;
}
#endif