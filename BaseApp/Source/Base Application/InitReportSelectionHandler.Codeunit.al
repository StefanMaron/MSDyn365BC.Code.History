#if not CLEAN19
codeunit 11774 "Init Report Selection Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Core Localization Pack for Czech & Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnBeforeInitReportSelectionSales', '', false, false)]
    local procedure InitReportSelectionSalesOnAfterInitReportSelectionSales()
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            InitReportUsage(Usage::"S.Quote");
            InitReportUsage(Usage::"S.Order");
            InitReportUsage(Usage::"S.Invoice");
            InitReportUsage(Usage::"S.Return");
            InitReportUsage(Usage::"S.Cr.Memo");
            InitReportUsage(Usage::"S.Shipment");
            InitReportUsage(Usage::"S.Ret.Rcpt.");
            InitReportUsage(Usage::"S.Adv.Let");
            InitReportUsage(Usage::"S.Adv.Inv");
            InitReportUsage(Usage::"S.Adv.CrM");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnBeforeInitReportSelectionPurch', '', false, false)]
    local procedure InitReportSelectionPurchOnAfterInitReportSelectionPurch()
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            InitReportUsage(Usage::"P.Quote");
            InitReportUsage(Usage::"P.Order");
            InitReportUsage(Usage::"P.Adv.Let");
            InitReportUsage(Usage::"P.Adv.Inv");
            InitReportUsage(Usage::"P.Adv.CrM");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnBeforeInitReportSelectionServ', '', false, false)]
    local procedure InitReportSelectionServOnAfterInitReportSelectionServ()
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            InitReportUsage(Usage::"SM.Quote");
            InitReportUsage(Usage::"SM.Order");
            InitReportUsage(Usage::"SM.Invoice");
            InitReportUsage(Usage::"SM.Credit Memo");
            InitReportUsage(Usage::"SM.Shipment");
            InitReportUsage(Usage::"SM.Contract Quote");
            InitReportUsage(Usage::"SM.Contract");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnBeforeInitReportSelectionCust', '', false, false)]
    local procedure InitReportSelectionCustOnAfterInitReportSelectionCust()
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            InitReportUsage(Usage::Reminder);
            InitReportUsage(Usage::"Fin.Charge");
        end;
    end;

    local procedure InitReportUsage(ReportUsage: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do
            case ReportUsage of
#if not CLEAN19
                Usage::"S.Adv.Let":
                    InsertRepSelection(Usage::"S.Adv.Let", '1', Report::"Sales - Advance Letter CZ");
                Usage::"S.Adv.Inv":
                    InsertRepSelection(Usage::"S.Adv.Inv", '1', Report::"Sales - Advance Invoice CZ");
                Usage::"S.Adv.CrM":
                    InsertRepSelection(Usage::"S.Adv.CrM", '1', Report::"Sales - Advance Credit Memo CZ");
                Usage::"P.Adv.Let":
                    InsertRepSelection(Usage::"P.Adv.Let", '1', Report::"Purchase - Advance Letter CZ");
                Usage::"P.Adv.Inv":
                    InsertRepSelection(Usage::"P.Adv.Inv", '1', Report::"Purchase - Advance Invoice CZ");
                Usage::"P.Adv.CrM":
                    InsertRepSelection(Usage::"P.Adv.CrM", '1', Report::"Purchase - Advance Cr. Memo CZ");
#endif
            end;
    end;

    local procedure InsertRepSelection(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;
    end;
}
#endif