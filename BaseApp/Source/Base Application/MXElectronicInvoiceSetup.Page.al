page 10457 "MX Electronic Invoice Setup"
{
    ApplicationArea = BasicMX;
    Caption = 'Electronic Invoicing Setup for Mexico';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "MX Electronic Invoicing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            part(Control1310001; "MX Electroninc - CompanyInfo")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1310002; "MX Electroninc - GLSetup")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Download XML with Requests"; "Download XML with Requests")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Download the XML document when sending a request to an electronic invoicing authority.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        MailManagement: Codeunit "Mail Management";
        Notify: Notification;
        IsEmailEnabled: Boolean;
    begin
        IsEmailEnabled := MailManagement.IsEnabled();

        if not IsEmailEnabled then begin
            Notify.Message(EmailSetupMissingMsg);
            Notify.AddAction(SetupEmailMsg, CODEUNIT::"E-Invoice Mgt.", 'OpenAssistedSetup');
            Notify.Send;
        end;
        EInvoiceMgt.SetupService;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
    begin
        if CompanyInformation.CheckIfMissingMXEInvRequiredFields and PACWebService.CheckIfMissingMXEInvRequiredFields and
           GeneralLedgerSetup.CheckIfMissingMXEInvRequiredFields
        then
            Enabled := false
        else
            Enabled := true;

        Modify;
    end;

    var
        EmailSetupMissingMsg: Label 'You must set up email in Business Central before you can send electronic invoices.';
        SetupEmailMsg: Label 'Go to Set Up Email.';
}

