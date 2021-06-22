page 6702 "Booking Sync. Setup"
{
    Caption = 'Booking Sync. Setup';
    DataCaptionExpression = "Booking Mailbox Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Navigate,Filter';
    SourceTable = "Booking Sync";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bookings Company"; "Booking Mailbox Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bookings Company';
                    ToolTip = 'Specifies the Bookings company with which to synchronize customers and services.';

                    trigger OnValidate()
                    var
                        BookingMailbox: Record "Booking Mailbox";
                        BookingMailboxList: Page "Booking Mailbox List";
                    begin
                        if Format("Last Customer Sync") + Format("Last Service Sync") <> '' then
                            if not Confirm(ChangeCompanyQst) then begin
                                "Booking Mailbox Name" := xRec."Booking Mailbox Name";
                                exit;
                            end;

                        O365SyncManagement.GetBookingMailboxes(Rec, TempBookingMailbox, "Booking Mailbox Name");

                        if TempBookingMailbox.Count = 0 then
                            Error(NoMailboxErr);

                        if TempBookingMailbox.Count = 1 then begin
                            "Booking Mailbox Address" := TempBookingMailbox.SmtpAddress;
                            "Booking Mailbox Name" := TempBookingMailbox."Display Name";
                        end else begin
                            BookingMailboxList.SetMailboxes(TempBookingMailbox);
                            BookingMailboxList.LookupMode(true);
                            if BookingMailboxList.RunModal in [ACTION::LookupOK, ACTION::OK] then begin
                                BookingMailboxList.GetRecord(BookingMailbox);
                                "Booking Mailbox Address" := BookingMailbox.SmtpAddress;
                                "Booking Mailbox Name" := BookingMailbox."Display Name";
                            end else
                                "Booking Mailbox Name" := xRec."Booking Mailbox Name";
                        end;

                        if "Booking Mailbox Name" <> xRec."Booking Mailbox Name" then begin
                            Clear("Last Customer Sync");
                            Clear("Last Service Sync");
                            Modify;
                            CurrPage.Update;
                        end;

                        SendTraceTag('0000ACL', O365SyncManagement.TraceCategory(), Verbosity::Normal, SetupTelemetryTxt, DataClassification::SystemMetadata);
                    end;
                }
                field(SyncUser; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Synchronization User';
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the user on behalf of which to run the synchronize operation.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable Background Synchronization';
                    ToolTip = 'Specifies whether to allow synchronization to occur periodically in the background.';
                }
            }
            group(Synchronize)
            {
                Caption = 'Synchronize';
                field("Sync Customers"; "Sync Customers")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to synchronize Bookings customers.';
                    Visible = NOT GraphSyncEnabled;
                }
                field("Customer Template Code"; "Customer Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Customer Template';
                    ToolTip = 'Specifies the customer template to use when creating new Customers from the Bookings company.';
                    Visible = NOT GraphSyncEnabled;
                }
                field("Sync Services"; "Sync Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to synchronize services.';
                }
                field("Item Template Code"; "Item Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Item Template';
                    ToolTip = 'Specifies the template to use when creating new service items from the Bookings company.';
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
                        if O365SyncManagement.IsO365Setup(false) then
                            O365SyncManagement.ValidateExchangeConnection(ExchangeAccountUserName, ExchangeSync);
                    end;
                }
                action(SyncWithBookings)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sync with Bookings';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Synchronize changes made in Bookings since the last sync date and last modified date.';

                    trigger OnAction()
                    var
                        O365SyncManagement: Codeunit "O365 Sync. Management";
                    begin
                        Clear(O365SyncManagement);
                        if O365SyncManagement.IsO365Setup(false) then begin
                            if "Sync Customers" then
                                O365SyncManagement.SyncBookingCustomers(Rec);
                            if "Sync Services" then
                                O365SyncManagement.SyncBookingServices(Rec);
                        end;
                    end;
                }
                action(SetSyncUser)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Sync. User';
                    Enabled = NOT IsSyncUser;
                    Image = User;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Set the synchronization user to be you.';

                    trigger OnAction()
                    begin
                        if Confirm(SetSyncUserQst) then begin
                            Validate("User ID", UserId);
                            GetExchangeAccount;
                        end;
                    end;
                }
                action("Invoice Appointments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Appointments';
                    Image = NewInvoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'View Booking appointments and create invoices for your customers.';
                    Visible = IsSaaS;

                    trigger OnAction()
                    var
                        BookingManager: Codeunit "Booking Manager";
                    begin
                        BookingManager.InvoiceBookingItems;
                    end;
                }
            }
            group("Filter")
            {
                Caption = 'Filter';
                action(SetCustomerSyncFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Customer Sync Filter';
                    Image = ContactFilter;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Set a filter to use when syncing customers.';

                    trigger OnAction()
                    var
                        BookingCustomerSync: Codeunit "Booking Customer Sync.";
                    begin
                        CalcFields("Customer Filter");
                        BookingCustomerSync.GetRequestParameters(Rec);
                    end;
                }
                action(SetServiceSyncFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Service Sync Filter';
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Set a filter to use when syncing service items.';

                    trigger OnAction()
                    var
                        BookingServiceSync: Codeunit "Booking Service Sync.";
                    begin
                        CalcFields("Item Filter");
                        BookingServiceSync.GetRequestParameters(Rec);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if MarketingSetup.Get then
            GraphSyncEnabled := MarketingSetup."Sync with Microsoft Graph";
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CheckExistingSetup;
        GetExchangeAccount;
        IsSyncUser := "User ID" = UserId;
        IsSaaS := EnvironmentInfo.IsSaaS;
    end;

    var
        ExchangeSync: Record "Exchange Sync";
        TempBookingMailbox: Record "Booking Mailbox" temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ExchangeAccountUserName: Text[250];
        ChangeCompanyQst: Label 'The synchronization has been run against the current company. The process will no longer synchronize customer and service records with the current company, and synchronize against the new selected company. Do you want to continue?';
        SetSyncUserQst: Label 'Setting the synchronization user will assign your Exchange email and password as the credentials that are used to synchronize customers and service items to Bookings for this company. Any user already assigned as the synchronization user will be replaced with your User ID. Do you want to continue?';
        ExchangeSyncErr: Label 'Exchange sync. must be setup before using Bookings Sync.';
        NoMailboxErr: Label 'No matching mailboxes found.';
        BookingsSetupErr: Label 'Cannot open the Bookings Sync. Setup page. Make sure that your company is set up in the Bookings application in Office 365.';
        SetupTelemetryTxt: Label 'Bookings sync has been set up.', Locked = true;
        IsSyncUser: Boolean;
        GraphSyncEnabled: Boolean;
        IsSaaS: Boolean;

    local procedure CheckExistingSetup()
    begin
        if not ExchangeSync.Get(UserId) or not O365SyncManagement.IsO365Setup(false) then
            Error(ExchangeSyncErr);

        if not Get then begin
            Init;
            "User ID" := UserId;
            O365SyncManagement.GetBookingMailboxes(Rec, TempBookingMailbox, '');

            if TempBookingMailbox.Count = 0 then
                Error(BookingsSetupErr);

            if TempBookingMailbox.Count = 1 then begin
                "Booking Mailbox Address" := TempBookingMailbox.SmtpAddress;
                "Booking Mailbox Name" := TempBookingMailbox."Display Name";
            end;
            Insert(true);
        end;
    end;

    local procedure GetExchangeAccount()
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst then
            ExchangeAccountUserName := User."Authentication Email";
    end;
}

