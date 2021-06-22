page 195 "Acc. Sched. KPI Web Srv. Setup"
{
    AdditionalSearchTerms = 'financial report setup,business intelligence setup,bi setup,odata setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Schedule KPI Web Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Sched. KPI Web Srv. Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Period; Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the account-schedule KPI web service is based on.';
                }
                field("View By"; "View By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which time interval the account-schedule KPI is shown in.';
                }
                field("G/L Budget Name"; "G/L Budget Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the general ledger budget that provides budgeted values to the account-schedule KPI web service.';
                }
                field("Forecasted Values Start"; "Forecasted Values Start")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies at what point in time forecasted values are shown on the account-schedule KPI graphic. The forecasted values are retrieved from the selected general ledger budget.';
                }
                field("Web Service Name"; "Web Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account-schedule KPI web service. This name will be shown under the displayed account-schedule KPI.';
                }
                field(Published; Published)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the account-schedule KPI web service has been published. Published web services are listed in the Web Services window.';
                }
                field("Data Last Updated"; "Data Last Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last time data was refreshed through the web service. ';
                }
                field("Data Time To Live (hours)"; "Data Time To Live (hours)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long data is stored in Business Central before being refreshed from the service. The longer the duration is the smaller the performance impact.';
                }
                field(GetLastClosedAccDate; GetLastClosedAccDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Locked Posting Date';
                    ToolTip = 'Specifies the last date that posting was locked and actual transaction values were not supplied to the account-schedule KPI.';
                }
                field(GetLastBudgetChangedDate; GetLastBudgetChangedDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Changed Budget Date';
                    ToolTip = 'Specifies when the general ledger budget for this account-schedule KPI was last modified.';
                }
            }
            part("Account Schedules"; "Acc. Sched. KPI Web Srv. Lines")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Account Schedules';
                ShowFilter = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PublishWebService)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Publish Web Service';
                Image = Add;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Publish the account schedule as a web service. The Published field is set to Yes.';

                trigger OnAction()
                begin
                    PublishWebService;
                end;
            }
            action(DeleteWebService)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Remove Web Service';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Unpublish the account schedule web service. The Published field is set to No.';

                trigger OnAction()
                begin
                    DeleteWebService;
                end;
            }
            action(RefreshBufferData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Data';
                Ellipsis = true;
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Refresh the buffered data. All the lines will be recalculated. This may take a minute or so.';

                trigger OnAction()
                begin
                    if not Confirm(ResetQst) then
                        exit;
                    LockTable();
                    Find;
                    "Data Last Updated" := 0DT;
                    "Last G/L Entry Included" := 0;
                    Modify;
                    CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");
                end;
            }
        }
        area(navigation)
        {
            action(KPIData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Acc. Sched. KPI Web Service';
                Image = List;
                RunObject = Page "Acc. Sched. KPI Web Service";
                ToolTip = 'View the data that is published as a web service based on the account schedules that you have set up in this window.';
            }
            action(WebServices)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Web Services';
                Image = Web;
                RunObject = Page "Web Services";
                ToolTip = 'Opens the Web Services window so you can see all available web services.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;

    var
        ResetQst: Label 'Do you want to refresh the buffered data?';
}

