page 5339 "Integration Synch. Error List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Synchronization Errors';
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Integration Synch. Job Errors";
    SourceTableView = SORTING("Date/Time", "Integration Synch. Job ID")
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Date/Time"; "Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the error in the integration synchronization job occurred.';
                }
                field(Message; ErrorMessage)
                {
                    ApplicationArea = Suite;
                    Caption = 'Error Message';
                    ToolTip = 'Specifies the error that occurred in the integration synchronization job.';
                    Width = 100;
                }
                field(HelpLink; HelpLink)
                {
                    ApplicationArea = Suite;
                    Caption = 'Help Link';
                    ToolTip = 'Specifies the link to the documentation page that could help to resolve the integration synchronization job failure.';

                    trigger OnDrillDown()
                    var
                        HelpLinkUrl: Text;
                    begin
                        HelpLinkUrl := GetHelpLink();
                        if HelpLinkUrl <> '' then
                            HyperLink(HelpLinkUrl);
                    end;
                }
                field("Exception Detail"; "Exception Detail")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the exception that occurred in the integration synchronization job.';
                    Visible = false;
                }
                field(Source; OpenSourcePageTxt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the record that supplied the data to destination record in integration synchronization job that failed.';

                    trigger OnDrillDown()
                    var
                        CRMSynchHelper: Codeunit "CRM Synch. Helper";
                    begin
                        CRMSynchHelper.ShowPage("Source Record ID");
                    end;
                }
                field(Destination; OpenDestinationPageTxt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Destination';
                    ToolTip = 'Specifies the record that received the data from the source record in integration synchronization job that failed.';

                    trigger OnDrillDown()
                    var
                        CRMSynchHelper: Codeunit "CRM Synch. Helper";
                    begin
                        CRMSynchHelper.ShowPage("Destination Record ID");
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Delete7days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Enabled = HasRecords;
                Image = ClearLog;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Delete error log information for job queue entries that are older than seven days.';

                trigger OnAction()
                begin
                    DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Suite;
                Caption = 'Delete All Entries';
                Enabled = HasRecords;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Delete all error log information for job queue entries.';

                trigger OnAction()
                begin
                    DeleteEntries(0);
                end;
            }
            group(ActionGroupDataIntegration)
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationActions;
                action(DataIntegrationSynchronizeNow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Enabled = HasRecords;
                    Image = Refresh;
                    ToolTip = 'Send or get updated data from integrated products or services.';
                    Visible = ShowDataIntegrationActions;

                    trigger OnAction()
                    var
                        LocalRecordID: RecordID;
                        SynchronizeHandled: Boolean;
                    begin
                        if IsEmpty then
                            exit;

                        GetRecordID(LocalRecordID);
                        ForceSynchronizeDataIntegration(LocalRecordID, SynchronizeHandled);
                    end;
                }
                action(DataIntegrationExceptionDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Error Call Stack';
                    Enabled = HasRecords;
                    Image = StepInto;
                    ToolTip = 'Shows the call stack for the error.';
                    Visible = ShowDataIntegrationActions;

                    trigger OnAction()
                    var
                        TypeHelper: Codeunit "Type Helper";
                        CallStackInStream: InStream;
                    begin
                        if IsEmpty() then
                            exit;

                        CalcFields("Exception Detail");
                        "Exception Detail".CreateInStream(CallStackInStream, TEXTENCODING::Windows);
                        Message(TypeHelper.ReadAsTextWithSeparator(CallStackInStream, TypeHelper.LFSeparator()));
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    Visible = ShowD365SIntegrationActions;

                    action(ManageCRMCoupling)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Enabled = HasRecords;
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse entity.';
                        Visible = ShowD365SIntegrationActions;

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            LocalRecordID: RecordID;
                        begin
                            if IsEmpty then
                                exit;

                            GetRecordID(LocalRecordID);
                            CRMIntegrationManagement.DefineCoupling(LocalRecordID);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = HasRecords;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse entity.';
                        Visible = ShowD365SIntegrationActions;

                        trigger OnAction()
                        var
                            IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                        begin
                            CurrPage.SetSelectionFilter(IntegrationSynchJobErrors);
                            IntegrationSynchJobErrors.DeleteCouplings();
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RecID: RecordID;
    begin
        RecID := "Source Record ID";
        OpenSourcePageTxt := GetPageLink(RecID);

        RecID := "Destination Record ID";
        OpenDestinationPageTxt := GetPageLink(RecID);

        ErrorMessage := GetErrorMessage();

        if GetHelpLink() <> '' then
            HelpLink := PermissionsHelpTitleTxt
        else
            helpLink := '';

        HasRecords := true;
    end;

    trigger OnOpenPage()
    begin
        SetDataIntegrationUIElementsVisible(ShowDataIntegrationActions);
        if CRMConnectionSetup.IsEnabled then
            CRMConnectionSetup.RegisterUserConnection();
        ShowD365SIntegrationActions := CRMConnectionSetup.IsEnabled;
    end;

    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        InvalidOrMissingSourceErr: Label 'The source record was not found.';
        InvalidOrMissingDestinationErr: Label 'The destination record was not found.';
        OpenSourcePageTxt: Text;
        OpenDestinationPageTxt: Text;
        OpenPageTok: Label 'View';
        ErrorMessage: Text;
        HelpLink: Text;
        PermissionsTok: Label ' prv', Locked = true;
        PermissionsHelpTitleTxt: Label 'Insufficient permissions', Locked = true;
        FixPermissionsUrlTxt: Label 'https://docs.microsoft.com/en-us/power-platform/admin/troubleshooting-user-needs-read-write-access-organization#user-doesnt-have-sufficient-permissions', Locked = true;
        HasRecords: Boolean;
        ShowDataIntegrationActions: Boolean;
        ShowD365SIntegrationActions: Boolean;

    local procedure GetRecordID(var LocalRecordID: RecordID)
    begin
        GetRecordID(Rec, LocalRecordID)
    end;

    local procedure GetRecordID(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"; var LocalRecordID: RecordID)
    var
        TableMetadata: Record "Table Metadata";
    begin
        LocalRecordID := IntegrationSynchJobErrors."Source Record ID";
        if LocalRecordID.TableNo() = 0 then
            Error(InvalidOrMissingSourceErr);

        if not TableMetadata.Get(LocalRecordID.TableNo()) then
            Error(InvalidOrMissingSourceErr);

        if TableMetadata.TableType <> TableMetadata.TableType::CRM then
            exit;

        LocalRecordID := IntegrationSynchJobErrors."Destination Record ID";
        if LocalRecordID.TableNo() = 0 then
            Error(InvalidOrMissingDestinationErr);
    end;

    local procedure GetPageLink(var RecID: RecordID): Text
    var
        TableMetadata: Record "Table Metadata";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ReferenceRecordRef: RecordRef;
    begin
        TableMetadata.SetRange(ID, RecID.TableNo);
        if TableMetadata.FindFirst then begin
            if TableMetadata.TableType = TableMetadata.TableType::MicrosoftGraph then
                exit('');
            if (TableMetadata.TableType = TableMetadata.TableType::CRM) and not CRMConnectionSetup.IsEnabled then
                exit('');
        end;

        if not ReferenceRecordRef.Get(RecID) then
            exit('');

        exit(OpenPageTok);
    end;

    local procedure GetHelpLink(): Text
    begin
        if GetErrorMessage().Contains(PermissionsTok) then
            exit(FixPermissionsUrlTxt);
        exit('');
    end;

    local procedure GetErrorMessage(): Text
    begin
        if "Error Message" <> '' then
            exit("Error Message");
        exit(Message);
    end;
}

