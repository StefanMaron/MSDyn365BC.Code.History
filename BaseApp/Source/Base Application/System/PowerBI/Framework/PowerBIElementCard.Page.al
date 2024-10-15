namespace System.Integration.PowerBI;
using System.Telemetry;

page 6323 "Power BI Element Card"
{
    Caption = 'Power BI';
    DataCaptionExpression = PowerBIDisplayedElement.ElementName;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = false;
    PageType = Card;

    layout
    {
        area(content)
        {
            group(ReportGroup)
            {
                ShowCaption = false;
                Visible = not HasError;

                usercontrol(PowerBIManagement; PowerBIManagement)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady()
                    begin
                        InitializeAddIn();
                    end;

                    trigger ReportLoaded(ReportFilters: Text; ActivePageName: Text; activePageFilters: Text; CorrelationId: Text)
                    begin
                        LogCorrelationIdForEmbedType(CorrelationId, Enum::"Power BI Element Type"::Report);
                    end;

                    trigger DashboardLoaded(CorrelationId: Text)
                    begin
                        LogCorrelationIdForEmbedType(CorrelationId, Enum::"Power BI Element Type"::Dashboard);
                    end;

                    trigger DashboardTileLoaded(CorrelationId: Text)
                    begin
                        LogCorrelationIdForEmbedType(CorrelationId, Enum::"Power BI Element Type"::"Dashboard Tile");
                    end;

                    trigger ReportVisualLoaded(CorrelationId: Text)
                    begin
                        LogCorrelationIdForEmbedType(CorrelationId, Enum::"Power BI Element Type"::"Report Visual");
                    end;

                    trigger ErrorOccurred(Operation: Text; ErrorText: Text)
                    begin
                        LogEmbedError(Operation);
                        ShowError(ErrorText);
                    end;

                    trigger ReportPageChanged(newPage: Text; newPageFilters: Text)
                    begin
                        if PowerBIDisplayedElement.IsTemporary() then
                            exit;

                        PowerBIDisplayedElement.ReportPage := CopyStr(newPage, 1, MaxStrLen(PowerBIDisplayedElement.ReportPage));
                        if not PowerBIDisplayedElement.Modify(true) then
                            Session.LogMessage('0000LK8', FailedToUpdatePageTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                    end;
                }
            }
            group(ErrorGroup)
            {
                ShowCaption = false;
                Visible = HasError;

                field(ErrorMessageText; ErrorMessageText)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the error message from Power BI.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(FullScreen)
            {
                ApplicationArea = All;
                Caption = 'Fullscreen';
                ToolTip = 'Shows the Power BI element as full screen.';
                Image = View;

                trigger OnAction()
                begin
                    CurrPage.PowerBIManagement.FullScreen();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(FullScreen_Promoted; FullScreen)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not PowerBIServiceMgt.IsUserReadyForPowerBI() then
            ShowError(UnauthorizedErr);
    end;

    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        HasError: Boolean;
        ErrorMessageText: Text;
        UnsupportedElementTypeErr: Label 'Displaying Power BI elements of type %1 is currently not supported.', Comment = '%1 = an element type, such as Report or Workspace';
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        FailedToUpdatePageTelemetryMsg: Label 'Failed to update the page for the Power BI report.', Locked = true;
        EmbedCorrelationTelemetryTxt: Label 'Embed element started with type: %1, and correlation: %2', Locked = true;
        EmbedErrorOccurredTelemetryTxt: Label 'Embed error occurred with category: %1', Locked = true;

    procedure SetDisplayedElement(InputPowerBIDisplayedElement: Record "Power BI Displayed Element")
    begin
        PowerBIDisplayedElement := InputPowerBIDisplayedElement;
    end;

    local procedure ShowError(NewErrorMessageText: Text)
    begin
        HasError := true;
        ErrorMessageText := NewErrorMessageText;
    end;

    [NonDebuggable]
    local procedure InitializeAddIn()
    var
        AccessToken: Text;
        DashboardId: Guid;
        ReportId: Guid;
        TileId: Guid;
        PageName: Text[200];
        VisualName: Text[200];
    begin
        AccessToken := PowerBiServiceMgt.GetEmbedAccessToken();

        if AccessToken = '' then begin
            ShowError(GetLastErrorText());
            exit;
        end;

        CurrPage.PowerBIManagement.InitializeFrame(true, '');

        if PowerBIDisplayedElement.ElementEmbedUrl <> '' then
            case PowerBIDisplayedElement.ElementType of
                "Power BI Element Type"::"Report":
                    begin
                        PowerBIDisplayedElement.ParseReportKey(ReportId);
                        CurrPage.PowerBIManagement.EmbedReportWithOptions(PowerBIDisplayedElement.ElementEmbedUrl, ReportId,
                                AccessToken, PowerBIDisplayedElement.ReportPage, PowerBIDisplayedElement.ShowPanesInExpandedMode);
                    end;
                "Power BI Element Type"::"Report Visual":
                    begin
                        PowerBIDisplayedElement.ParseReportVisualKey(ReportId, PageName, VisualName);
                        CurrPage.PowerBIManagement.EmbedReportVisual(PowerBIDisplayedElement.ElementEmbedUrl, ReportId, PageName, VisualName, AccessToken);
                    end;
                "Power BI Element Type"::Dashboard:
                    begin
                        PowerBIDisplayedElement.ParseDashboardKey(DashboardId);
                        CurrPage.PowerBIManagement.EmbedDashboard(PowerBIDisplayedElement.ElementEmbedUrl, DashboardId, AccessToken);
                    end;
                "Power BI Element Type"::"Dashboard Tile":
                    begin
                        PowerBIDisplayedElement.ParseDashboardTileKey(DashboardId, TileId);
                        CurrPage.PowerBIManagement.EmbedDashboardTile(PowerBIDisplayedElement.ElementEmbedUrl, DashboardId, TileId, AccessToken);
                    end;
                else
                    ShowError(StrSubstNo(UnsupportedElementTypeErr, PowerBIDisplayedElement.ElementType));
            end;

        FeatureTelemetry.LogUsage('0000LSN', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI element loaded', PowerBIDisplayedElement.GetTelemetryDimensions());

        CurrPage.Update();
    end;

    local procedure LogCorrelationIdForEmbedType(CorrelationId: Text; EmbedType: Enum "Power BI Element Type")
    begin
        Session.LogMessage('0000KAF', StrSubstNo(EmbedCorrelationTelemetryTxt, EmbedType, CorrelationId),
        Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
    end;

    local procedure LogEmbedError(ErrorCategory: Text)
    begin
        Session.LogMessage('0000KAG', StrSubstNo(EmbedErrorOccurredTelemetryTxt, ErrorCategory),
        Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
    end;
}
