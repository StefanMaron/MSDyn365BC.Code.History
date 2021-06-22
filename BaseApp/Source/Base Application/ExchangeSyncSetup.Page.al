page 6700 "Exchange Sync. Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Exchange Sync. Setup';
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    SourceTable = "Exchange Sync";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(ExchangeAccountUserName; ExchangeAccountUserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Authentication Email';
                    Editable = false;
                    Enabled = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address that you use to authenticate yourself on the Exchange server.';
                }
                field(ExchangeAccountPasswordTemp; ExchangeAccountPasswordTemp)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exchange Account Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the user account that has access to Exchange.';
                    Visible = PasswordRequired;

                    trigger OnValidate()
                    begin
                        SetExchangeAccountPassword(ExchangeAccountPasswordTemp);
                        Commit();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                Image = "Action";
                action("Validate Exchange Connection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Exchange Connection';
                    Image = ValidateEmailLoggingSetup;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Test that the provided exchange server connection works.';

                    trigger OnAction()
                    begin
                        ProgressWindow.Open(ProgressWindowMsg);

                        if O365SyncManagement.CreateExchangeConnection(Rec) then
                            Message(ConnectionSuccessMsg)
                        else begin
                            ProgressWindow.Close;
                            Error(ConnectionFailureErr);
                        end;

                        ProgressWindow.Close;
                    end;
                }
            }
            group(Navigate)
            {
                Caption = 'Navigate';
                action(SetupBookingSync)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bookings Sync. Setup';
                    Image = BookingsLogo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Open the Bookings Sync. Setup page.';

                    trigger OnAction()
                    begin
                        if PasswordRequired and IsNullGuid("Exchange Account Password Key") then
                            Error(PasswordMissingErr);

                        PAGE.RunModal(PAGE::"Booking Sync. Setup");
                    end;
                }
                action(SetupContactSync)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact Sync. Setup';
                    Image = ExportSalesPerson;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Open the Contact Sync. Setup page.';

                    trigger OnAction()
                    begin
                        if PasswordRequired and IsNullGuid("Exchange Account Password Key") then
                            Error(PasswordMissingErr);

                        PAGE.RunModal(PAGE::"Contact Sync. Setup", Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        User: Record User;
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        Reset;
        GetUser(User);

        if User."Authentication Email" = '' then
            Error(EmailMissingErr);

        ExchangeAccountUserName := User."Authentication Email";

        if not Get(UserId) then begin
            Init;
            "User ID" := UserId;
            "Folder ID" := PRODUCTNAME.Short;
            Insert;
            Commit();
        end;

        PasswordRequired := AzureADMgt.GetAccessToken(AzureADMgt.GetO365Resource, AzureADMgt.GetO365ResourceName, false) = '';

        if (ExchangeAccountUserName <> '') and (not IsNullGuid("Exchange Account Password Key")) then
            ExchangeAccountPasswordTemp := '**********';
    end;

    var
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ProgressWindow: Dialog;
        ExchangeAccountPasswordTemp: Text;
        ProgressWindowMsg: Label 'Validating the connection to Exchange.';
        ConnectionSuccessMsg: Label 'Connected successfully to Exchange.';
        ExchangeAccountUserName: Text[250];
        ConnectionFailureErr: Label 'Cannot connect to Exchange. Check your user name, password and Folder ID, and then try again.';
        EmailMissingErr: Label 'You must specify an authentication email address for this user.';
        PasswordMissingErr: Label 'You must specify your Exchange credentials for this user first.';
        PasswordRequired: Boolean;

    local procedure GetUser(var User: Record User): Boolean
    begin
        with User do begin
            SetRange("User Name", UserId);
            if FindFirst then
                exit(true);
        end;
    end;
}

