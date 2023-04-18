page 6319 "Power BI Management"
{
    Caption = 'Power BI Management';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    RefreshOnActivate = false;

    layout
    {
        area(content)
        {
            group(Control14)
            {
                ShowCaption = false;
                Visible = NOT IsInvalidClient;
                usercontrol(PowerBIManagement; "Microsoft.Dynamics.Nav.Client.PowerBIManagement")
                {
                    ApplicationArea = Basic, Suite;

                    trigger AddInReady()
                    begin
                        InitializeAddIn();
                    end;
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                Visible = NOT HasSelectedReport OR IsInvalidClient;
                label(MissingSelectedErr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'The selected report is missing';
                    ToolTip = 'Specifies there is no report selected to display. Choose Select Report to see a list of reports that you can display.';
                    Visible = NOT HasSelectedReport;
                }
                label(InvalidClient)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mobile clients unsupport for this page';
                    ToolTip = 'Specifies mobile clients are not supported for this page.';
                    Visible = IsInvalidClient;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewMode)
            {
                ApplicationArea = All;
                Caption = 'View Mode';
                ToolTip = 'Changes the Power BI report to view mode.';
                Image = View;

                trigger OnAction()
                begin
                    CurrPage.PowerBIManagement.ViewMode();
                end;
            }
            action(EditMode)
            {
                ApplicationArea = All;
                Caption = 'Edit Mode';
                ToolTip = 'Changes the Power BI report to edit mode.';
                Image = Edit;

                trigger OnAction()
                begin
                    CurrPage.PowerBIManagement.EditMode();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditMode_Promoted; EditMode)
                {
                }
                actionref(ViewMode_Promoted; ViewMode)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::Phone, ClientType::Tablet] then
            IsInvalidClient := true;
    end;

    trigger OnOpenPage()
    begin
        if PowerBIServiceMgt.IsUserReadyForPowerBI() then
            HasSelectedReport := true;
    end;

    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        HasSelectedReport: Boolean;
        IsInvalidClient: Boolean;
        TargetReportId: Guid;
        TargetReportUrl: Text;

    procedure SetTargetReport(ReportId: Guid; ReportUrl: Text)
    begin
        TargetReportId := ReportId;
        TargetReportUrl := ReportUrl;
    end;

    [NonDebuggable]
    local procedure InitializeAddIn()
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        Url: Text;
    begin
        Url := PowerBIUrlMgt.GetPowerBIEmbedReportsUrl();

        if not IsNullGuid(TargetReportId) and (TargetReportUrl <> '') then begin
            CurrPage.PowerBIManagement.InitializeReport(TargetReportUrl, TargetReportId,
                AzureADMgt.GetAccessToken(PowerBIServiceMgt.GetPowerBIResourceUrl(),
                PowerBIServiceMgt.GetPowerBiResourceName(), false), Url);

            CurrPage.Update();
        end;
    end;
}

