page 2841 "Native - SMTP Mail Setup"
{
    Caption = 'nativeInvoicingSMTPMailSetup', Locked = true;
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "SMTP Mail Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(primaryKey; "Primary Key")
                {
                    ApplicationArea = All;
                    Caption = 'primaryKey', Locked = true;
                    Editable = false;
                }
                field(SMTPServer; "SMTP Server")
                {
                    ApplicationArea = All;
                    Caption = 'SMTPSeverPort', Locked = true;
                }
                field(authentication; Authentication)
                {
                    ApplicationArea = All;
                    Caption = 'authentication', Locked = true;
                }
                field(userName; "User ID")
                {
                    ApplicationArea = All;
                    Caption = 'userName', Locked = true;
                }
                field(SMTPServerPort; "SMTP Server Port")
                {
                    ApplicationArea = All;
                    Caption = 'SMTPServerPort', Locked = true;
                }
                field(secureConnection; "Secure Connection")
                {
                    ApplicationArea = All;
                    Caption = 'secureConnection', Locked = true;
                }
                field(passWord; Password)
                {
                    ApplicationArea = All;
                    Caption = 'passWord', Locked = true;
                    ToolTip = 'Specifies the password of the smtp mail setup.';

                    trigger OnValidate()
                    begin
                        SetPassword(Password);
                        Clear(Password);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        Password: Text[250];
}

