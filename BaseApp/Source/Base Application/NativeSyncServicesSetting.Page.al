page 2843 "Native - Sync Services Setting"
{
    Caption = 'nativeSyncServicesSettings', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(qboSyncTitle; QBOSyncTitle)
                {
                    ApplicationArea = All;
                    Caption = 'qboSyncTitle', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies QuickBooks Online Sync title.';
                }
                field(qboSyncDescription; QBOSyncDescription)
                {
                    ApplicationArea = All;
                    Caption = 'qboSyncDescription', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies QuickBooks Online Sync description.';
                }
                field(qboSyncEnabled; QBOSyncEnabled)
                {
                    ApplicationArea = All;
                    Caption = 'qboSyncEnabled', Locked = true;
                    ToolTip = 'Specifies QuickBooks Online Sync enabled.';

                    trigger OnValidate()
                    begin
                        if QBOSyncEnabled then
                            Error(CantEnableSyncFromHereErr);
                        QBOSyncProxy.SetQBOSyncEnabled(QBOSyncEnabled);
                    end;
                }
                field(qbdSyncTitle; QBDSyncTitle)
                {
                    ApplicationArea = All;
                    Caption = 'qbdSyncTitle', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies QuickBooks Desktop Sync title';
                }
                field(qbdSyncDescription; QBDSyncDescription)
                {
                    ApplicationArea = All;
                    Caption = 'qbdSyncDescription', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies QuickBooks Desktop Sync description';
                }
                field(qbdSyncEnabled; QBDSyncEnabled)
                {
                    ApplicationArea = All;
                    Caption = 'qbdSyncEnabled', Locked = true;
                    ToolTip = 'Specifies QuickBooks Desktop Sync enabled';

                    trigger OnValidate()
                    begin
                        QBDSyncProxy.SetQBDSyncEnabled(QBDSyncEnabled);
                    end;
                }
                field(qbdSyncSendToEmail; QBDSyncSendToEmail)
                {
                    ApplicationArea = All;
                    Caption = 'qbdSyncSendToEmail', Locked = true;
                    ToolTip = 'Specifies the email to send QuickBooks Desktop Sync setup instructions to.';

                    trigger OnValidate()
                    begin
                        if QBDSyncSendToEmail = '' then
                            Error(SendToEmailErr);

                        QBDSyncProxy.SetQBDSyncSendToEmail(QBDSyncSendToEmail);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnInit()
    begin
        Insert;
    end;

    trigger OnOpenPage()
    begin
        SetCalculatedFields;
    end;

    var
        QBDSyncProxy: Codeunit "QBD Sync Proxy";
        QBOSyncProxy: Codeunit "QBO Sync Proxy";
        QBOSyncTitle: Text;
        QBOSyncDescription: Text;
        QBOSyncEnabled: Boolean;
        QBDSyncTitle: Text;
        QBDSyncDescription: Text;
        QBDSyncEnabled: Boolean;
        QBDSyncSendToEmail: Text;
        SendToEmailErr: Label 'Send to email is not specified.';
        SendingEmailErr: Label 'Error while sending email.';
        CantEnableSyncFromHereErr: Label 'Can''t enable sync from here. Use QBO Sync. Auth service instead.';

    [ServiceEnabled]
    procedure SendInstructionsByEmail(var ActionContext: DotNet WebServiceActionContext)
    var
        ODataActionManagement: Codeunit "OData Action Management";
        Handled: Boolean;
    begin
        QBDSyncProxy.SendEmailInBackground(Handled);
        if not Handled then
            Error(SendingEmailErr);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Sync Services Setting");
    end;

    local procedure SetCalculatedFields()
    begin
        QBOSyncProxy.GetQBOSyncSettings(QBOSyncTitle, QBOSyncDescription, QBOSyncEnabled);
        QBDSyncProxy.GetQBDSyncSettings(QBDSyncTitle, QBDSyncDescription, QBDSyncEnabled, QBDSyncSendToEmail);
    end;
}

