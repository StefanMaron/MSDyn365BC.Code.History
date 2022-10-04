#if not CLEAN21
page 9552 "Document Service Acc. Pwd."
{
    Caption = 'Document Service Acc. Pwd.';
    PageType = StandardDialog;

    ObsoleteReason = 'Use the new Document Service Setup page to configure the Document Service';
    ObsoleteTag = '21.0';
    ObsoleteState = Pending;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'Enter the password for your online document storage account.';
                ShowCaption = false;
                field(PasswordField; PasswordField)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Password';
                    ExtendedDatatype = Masked;
                    ShowCaption = true;
                    ToolTip = 'Specifies the password for your online storage account.';
                }
                field(ConfirmPasswordField; ConfirmPasswordField)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Confirm Password';
                    ExtendedDatatype = Masked;
                    ShowCaption = true;
                    ToolTip = 'Specifies the password repeated.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if PasswordField <> ConfirmPasswordField then
                Error(PasswordValidationErr);
    end;

    var
        PasswordField: Text[80];
        ConfirmPasswordField: Text[80];
        PasswordValidationErr: Label 'The passwords that you entered do not match.';

    procedure GetData(): Text[80]
    begin
        exit(PasswordField);
    end;
}
#endif
