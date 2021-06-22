page 1313 "Dynamics CRM Admin Credentials"
{
    Caption = 'Dynamics 365 Sales Admin Credentials';
    PageType = StandardDialog;
    Permissions = TableData "Office Admin. Credentials" = rimd;
    SourceTable = "Office Admin. Credentials";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            label("Specify the account that must be used to import the solution.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Specify the account that must be used to import the solution.';
            }
            field(Email; Email)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the email address that is associated with the account.';
            }
            field(Password; Password)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the password that is associated with the account.';
            }
            label(InvalidUserMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'This account must be a valid user in Dynamics 365 Sales with the security roles System Administrator and Solution Customizer.';
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::OK) or (CloseAction = ACTION::LookupOK) then begin
            if not Get then
                Insert;
        end;
    end;
}

