page 365 "Post and Send Confirmation"
{
    Caption = 'Post and Send Confirmation';
    InstructionalText = 'Do you want to post and send the document?';
    PageType = ConfirmationDialog;
    SourceTable = "Document Sending Profile";

    layout
    {
        area(content)
        {
            field(SelectedSendingProfiles; GetRecordAsText())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send Document to';
                Editable = false;
                MultiLine = true;
                Style = Strong;
                StyleExpr = TRUE;
                ToolTip = 'Specifies how the document is sent when you choose the Post and Send action.';

                trigger OnAssistEdit()
                var
                    TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
                begin
                    TempDocumentSendingProfile.Copy(Rec);
                    TempDocumentSendingProfile.Code := CurrentDocumentSendingProfileCode;
                    TempDocumentSendingProfile.Insert();

                    if PAGE.RunModal(PAGE::"Select Sending Options", TempDocumentSendingProfile) = ACTION::LookupOK then begin
                        Copy(TempDocumentSendingProfile);
                        UpdatePromptMessage();
                    end;
                end;
            }
            field(ChoicesForSendingTxt; ChoicesForSendingTxt)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Enabled = false;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    Message('');
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePromptMessage();
        CurrentDocumentSendingProfileCode := Code;
    end;

    var
        ChoicesForSendingTxt: Text;
        PromptsForAdditionalSettingsTxt: Label 'Dialogs will appear because sending options require user input.';
        CurrentDocumentSendingProfileCode: Code[20];

    local procedure UpdatePromptMessage()
    begin
        if WillUserBePrompted() then
            ChoicesForSendingTxt := PromptsForAdditionalSettingsTxt
        else
            ChoicesForSendingTxt := '';
    end;
}

