namespace System.Email;

using Microsoft.Foundation.Reporting;

codeunit 8891 "Email Scenario Mapping"
{
    Access = Public;

    /// <summary>
    /// Gets the document sending email scenario from report selection usage.
    /// </summary>
    /// <param name="ReportSelectionUsage"></param>
    /// <returns>The email scenario corresponding to the report selection usage</returns>
    procedure FromReportSelectionUsage(ReportSelectionUsage: Enum "Report Selection Usage"): Enum "Email Scenario"
    var
        EmailScenario: Enum "Email Scenario";
    begin
        case ReportSelectionUsage of
            ReportSelectionUsage::"S.Quote":
                exit(EmailScenario::"Sales Quote");
            ReportSelectionUsage::"S.Order":
                exit(EmailScenario::"Sales Order");
            ReportSelectionUsage::"S.Invoice":
                exit(EmailScenario::"Sales Invoice");
            ReportSelectionUsage::"S.Cr.Memo":
                exit(EmailScenario::"Sales Credit Memo");
            ReportSelectionUsage::"P.Quote":
                exit(EmailScenario::"Purchase Quote");
            ReportSelectionUsage::"P.Order":
                exit(EmailScenario::"Purchase Order");
            ReportSelectionUsage::"Reminder":
                exit(EmailScenario::"Reminder");
            ReportSelectionUsage::"Fin.Charge":
                exit(EmailScenario::"Finance Charge");
            ReportSelectionUsage::"SM.Quote":
                exit(EmailScenario::"Service Quote");
            ReportSelectionUsage::"SM.Order":
                exit(EmailScenario::"Service Order");
            ReportSelectionUsage::"SM.Invoice":
                exit(EmailScenario::"Service Invoice");
            ReportSelectionUsage::"SM.Credit Memo":
                exit(EmailScenario::"Service Credit Memo");
            ReportSelectionUsage::"P.V.Remit.":
                exit(EmailScenario::"Posted Vendor Remittance");
            ReportSelectionUsage::"C.Statement":
                exit(EmailScenario::"Customer Statement");
            ReportSelectionUsage::"V.Remittance":
                exit(EmailScenario::"Vendor Remittance");
            else begin
                EmailScenario := EmailScenario::Default;
                OnAfterFromReportSelectionUsage(ReportSelectionUsage, EmailScenario);
                exit(EmailScenario);
            end;
        end;
    end;

    /// <summary>
    /// Subscribe to this event to add custom mappings from report selection usage (in case the enum was extended) to email scenarios.
    /// </summary>
    /// <param name="ReportSelectionUsage">The input report selection usage of the FromReportSelectionUsage function.</param>
    /// <param name="EmailScenario">The output email scenario of the FromReportSelectionUsage function.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFromReportSelectionUsage(ReportSelectionUsage: Enum "Report Selection Usage"; var EmailScenario: Enum "Email Scenario")
    begin
    end;
}