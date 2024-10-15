page 31128 "EET Entry Status Log Preview"
{
    Caption = 'EET Entry Status Log Preview';
    DataCaptionFields = "EET Entry No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "EET Entry Status";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Change Datetime"; "Change Datetime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time of the last status change for the EET entry.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current state of the EET entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
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
        SetErrorMessages;
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;

    [Scope('OnPrem')]
    procedure Set(var TempEETEntryStatusParam: Record "EET Entry Status" temporary; var TempErrorMessageParam: Record "Error Message" temporary)
    begin
        Copy(TempEETEntryStatusParam, true);
        TempErrorMessage.Copy(TempErrorMessageParam, true);
    end;

    local procedure SetErrorMessages()
    var
        TempErrorMessage2: Record "Error Message" temporary;
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", RecordId);
        TempErrorMessage.CopyToTemp(TempErrorMessage2);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage2);
        CurrPage.ErrorMessagesPart.PAGE.Update;
    end;
}

