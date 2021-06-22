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
            ReportSelectionUsage::"P.Invoice":
                exit(EmailScenario::"Purchase Invoice");
            ReportSelectionUsage::"P.Cr.Memo":
                exit(EmailScenario::"Purchase Credit Memo");
            ReportSelectionUsage::"P.Receipt":
                exit(EmailScenario::"Purchase Receipt");
            ReportSelectionUsage::"P.Ret.Shpt.":
                exit(EmailScenario::"Purchase Return Shipment");
            ReportSelectionUsage::"B.Stmt":
                exit(EmailScenario::"Bank Account Statement");
            ReportSelectionUsage::"B.Check":
                exit(EmailScenario::"Bank Check");
            ReportSelectionUsage::"Reminder":
                exit(EmailScenario::"Reminder");
            ReportSelectionUsage::"Fin.Charge":
                exit(EmailScenario::"Finance Charge");
            ReportSelectionUsage::"Prod.Order":
                exit(EmailScenario::"Production Order");
            ReportSelectionUsage::"S.Blanket":
                exit(EmailScenario::"Blanket Sales Order");
            ReportSelectionUsage::"P.Blanket":
                exit(EmailScenario::"Blanket Purchase Order");
            ReportSelectionUsage::"SM.Quote":
                exit(EmailScenario::"Service Quote");
            ReportSelectionUsage::"SM.Order":
                exit(EmailScenario::"Service Order");
            ReportSelectionUsage::"SM.Invoice":
                exit(EmailScenario::"Service Invoice");
            ReportSelectionUsage::"SM.Credit Memo":
                exit(EmailScenario::"Service Credit Memo");
            ReportSelectionUsage::"SM.Contract Quote":
                exit(EmailScenario::"Service Contract Quote");
            ReportSelectionUsage::"SM.Contract":
                exit(EmailScenario::"Service Contract");
            ReportSelectionUsage::"S.Return":
                exit(EmailScenario::"Sales Return Order");
            ReportSelectionUsage::"P.Return":
                exit(EmailScenario::"Purchase Return Order");
            ReportSelectionUsage::"S.Shipment":
                exit(EmailScenario::"Sales Shipment");
            ReportSelectionUsage::"S.Ret.Rcpt.":
                exit(EmailScenario::"Sales Return Receipt");
            ReportSelectionUsage::"S.Work Order":
                exit(EmailScenario::"Sales Work Order");
            ReportSelectionUsage::"SM.Shipment":
                exit(EmailScenario::"Service Shipment");
            ReportSelectionUsage::"S.Arch.Quote":
                exit(EmailScenario::"Sales Quote Archive");
            ReportSelectionUsage::"S.Arch.Order":
                exit(EmailScenario::"Sales Order Archive");
            ReportSelectionUsage::"P.Arch.Quote":
                exit(EmailScenario::"Purchase Quote Archive");
            ReportSelectionUsage::"P.Arch.Order":
                exit(EmailScenario::"Purchase Order Archive");
            ReportSelectionUsage::"S.Arch.Return":
                exit(EmailScenario::"Sales Return Order Archive");
            ReportSelectionUsage::"P.Arch.Return":
                exit(EmailScenario::"Purchase Return Order Archive");
            ReportSelectionUsage::"Asm.Order":
                exit(EmailScenario::"Assembly Order");
            ReportSelectionUsage::"P.Asm.Order":
                exit(EmailScenario::"Posted Assembly Order");
            ReportSelectionUsage::"S.Order Pick Instruction":
                exit(EmailScenario::"Sales Order Pick Instruction");
            ReportSelectionUsage::"P.V.Remit.":
                exit(EmailScenario::"Posted Vendor Remittance");
            ReportSelectionUsage::"C.Statement":
                exit(EmailScenario::"Customer Statement");
            ReportSelectionUsage::"V.Remittance":
                exit(EmailScenario::"Vendor Remittance");
            ReportSelectionUsage::"S.Invoice Draft":
                exit(EmailScenario::"Sales Invoice Draft");
            ReportSelectionUsage::"Pro Forma S. Invoice":
                exit(EmailScenario::"Pro Forma Sales Invoice");
            ReportSelectionUsage::"S.Arch.Blanket":
                exit(EmailScenario::"Blanket Sales Order Archive");
            ReportSelectionUsage::"P.Arch.Blanket":
                exit(EmailScenario::"Blanket Purchase Order Archive");
            ReportSelectionUsage::"Phys.Invt.Order":
                exit(EmailScenario::"Physical Inventory Order");
            ReportSelectionUsage::"P.Phys.Invt.Order":
                exit(EmailScenario::"Posted Physical Inventory Order");
            ReportSelectionUsage::"Phys.Invt.Rec.":
                exit(EmailScenario::"Physical Inventory Recording");
            ReportSelectionUsage::"P.Phys.Invt.Rec.":
                exit(EmailScenario::"Posted Physical Inventory Recording");
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