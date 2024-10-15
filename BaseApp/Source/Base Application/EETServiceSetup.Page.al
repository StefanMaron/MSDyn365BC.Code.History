page 31120 "EET Service Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EET Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "EET Service Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Service URL"; "Service URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the source address of the service.';
                }
                field("Sales Regime"; "Sales Regime")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the settings for the simplified scheme sales.';
                }
                field("Limit Response Time"; "Limit Response Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    Importance = Additional;
                    ToolTip = 'Specifies the response time limit, after which goes into offline mode.';
                }
                field("Appointing VAT Reg. No."; "Appointing VAT Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    Importance = Additional;
                    ToolTip = 'Specifies the responsible person who collects revenues.';
                }
                field("Certificate Code"; "Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the certificate needed to register sales.';
                }
            }
            group(Status)
            {
                Caption = 'Status';
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled.';

                    trigger OnValidate()
                    begin
                        UpdateBasedOnEnable;
                        CurrPage.Update
                    end;
                }
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Editable = false;
                    ToolTip = 'Specifies the display of a warning message.';

                    trigger OnDrillDown()
                    begin
                        DrilldownCode;
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("EET Business Premises")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'EET Business Premises';
                Image = ElectronicPayment;
                RunObject = Page "EET Business Premises";
                ToolTip = 'Displays a list of your premises.';
            }
            action("Certificates Codes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Certificates Codes';
                Image = Certificate;
                RunObject = Page "Certificates CZ Codes";
                ToolTip = 'Displays a list of available certificates.';
            }
        }
        area(processing)
        {
            action(SetURLToDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set URL to Default';
                Enabled = NOT Enabled;
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Change the Service URL to its default value. You cannot cancel this action to revert back to the current value.';

                trigger OnAction()
                begin
                    SetURLToDefault(true);
                end;
            }
            action(JobQueueEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry';
                Enabled = Enabled;
                Image = JobListSetup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or edit the jobs that automatically process the incoming and outgoing electronic documents.';

                trigger OnAction()
                begin
                    ShowJobQueueEntry;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBasedOnEnable;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert(true);
        end;
        UpdateBasedOnEnable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Enabled then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption), true) then
                exit(false);
    end;

    var
        ShowEnableWarning: Text;
        EditableByNotEnabled: Boolean;
        EnabledWarningTok: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable the EET service?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = pagecaption (EET Service Setup)';

    local procedure UpdateBasedOnEnable()
    begin
        EditableByNotEnabled := not Enabled;
        ShowEnableWarning := '';
        if CurrPage.Editable and Enabled then
            ShowEnableWarning := EnabledWarningTok;
    end;

    local procedure DrilldownCode()
    begin
        if Confirm(DisableEnableQst, true) then begin
            Enabled := false;
            UpdateBasedOnEnable;
            CurrPage.Update;
        end;
    end;
}

