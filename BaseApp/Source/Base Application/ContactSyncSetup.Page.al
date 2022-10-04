page 6701 "Contact Sync. Setup"
{
    Caption = 'Contact Sync. Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Exchange Sync";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Folder ID"; Rec."Folder ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the public folder on the Exchange server that you want to use for your queue and storage folders.';
                }
                field("Last Sync Date Time"; Rec."Last Sync Date Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date/time that the Exchange server was synchronized.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable Background Synchronization';
                    ToolTip = 'Specifies that data synchronization can occur while users perform related tasks.';

                    trigger OnValidate()
                    var
                        PrivacyNotice: Codeunit "Privacy Notice";
                        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
                    begin
                        if Enabled then
                            if not PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId()) then
                                Enabled := false; // Privacy notice was not approved
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
                    ToolTip = 'Test that the provided exchange server connection works.';

                    trigger OnAction()
                    begin
                        ProgressWindow.Open(ProgressWindowMsg);

                        if O365SyncManagement.CreateExchangeConnection(Rec) then
                            Message(ConnectionSuccessMsg)
                        else begin
                            ProgressWindow.Close();
                            Error(ConnectionFailureErr);
                        end;

                        ProgressWindow.Close();

                        Session.LogMessage('0000ACM', SetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                    end;
                }
                action(SyncO365)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sync with Office 365';
                    Image = Refresh;
                    ToolTip = 'Synchronize with Office 365 based on last sync date and last modified date. All changes in Office 365 since the last sync date will be synchronized back.';

                    trigger OnAction()
                    begin
                        Clear(O365SyncManagement);
                        if O365SyncManagement.IsO365Setup(false) then
                            O365SyncManagement.SyncExchangeContacts(Rec, false);
                    end;
                }
                action(SetSyncFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Sync Filter';
                    Image = "Filter";
                    ToolTip = 'Synchronize, but ignore the last synchronized and last modified dates. All changes will be pushed to Office 365 and take all contacts from your Exchange folder and sync back.';

                    trigger OnAction()
                    var
                        ExchangeContactSync: Codeunit "Exchange Contact Sync.";
                    begin
                        ExchangeContactSync.GetRequestParameters(Rec);
                    end;
                }
            }
            group(Logging)
            {
                Caption = 'Logging';
                action(ActivityLog)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Log';
                    Image = Log;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category5;
                    ToolTip = 'View the status and any errors related to the connection to Exchange.';

                    trigger OnAction()
                    var
                        ActivityLog: Record "Activity Log";
                    begin
                        ActivityLog.ShowEntries(Rec);
                    end;
                }
                action(DeleteActivityLog)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Activity Log';
                    Image = Delete;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category5;
                    ToolTip = 'Delete the exchange synchronization log file.';

                    trigger OnAction()
                    begin
                        DeleteActivityLog();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Validate Exchange Connection_Promoted"; "Validate Exchange Connection")
                {
                }
                actionref(SyncO365_Promoted; SyncO365)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Filter', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(SetSyncFilter_Promoted; SetSyncFilter)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Logging', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
        }
    }

    trigger OnOpenPage()
    var
        User: Record User;
    begin
        GetUser(User);
        if not O365SyncManagement.IsO365Setup(false) then
            Error(EmailMissingErr);
    end;

    var
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ProgressWindow: Dialog;
        ProgressWindowMsg: Label 'Validating the connection to Exchange.';
        ConnectionSuccessMsg: Label 'Connected successfully to Exchange.';
        ConnectionFailureErr: Label 'Cannot connect to Exchange. Check your user name, password and Folder ID, and then try again.';
        EmailMissingErr: Label 'An authentication email and Exchange password must be set in order to set up contact synchronization.';
        SetupTelemetryTxt: Label 'Contact Sync has been set up and validated.', Locked = true;

    local procedure GetUser(var User: Record User): Boolean
    begin
        User.SetRange("User Name", UserId);
        exit(User.FindFirst());
    end;
}

