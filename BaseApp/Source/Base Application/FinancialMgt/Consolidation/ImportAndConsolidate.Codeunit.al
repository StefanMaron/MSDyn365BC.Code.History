namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using System.Telemetry;
using System.Threading;

codeunit 107 "Import and Consolidate"
{
    Permissions = tabledata "General Ledger Setup" = R,
                    tabledata "Gen. Journal Batch" = R;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ConsolidationProcess: Record "Consolidation Process";
    begin
        ConsolidationProcess.Get(Rec."Record ID to Process");
        ImportAndConsolidate(ConsolidationProcess);
    end;

    internal procedure ImportAndConsolidate(var ConsolidationProcess: Record "Consolidation Process")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
        BusinessUnit: Record "Business Unit";
        ImportConsolidationFromDB: Report "Import Consolidation from DB";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation From API";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if ConsolidationProcess.Status <> ConsolidationProcess.Status::NotStarted then
            exit;
        Session.LogMessage('0000KTT', 'Imported consolidation data:' + UserId(), Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::All, '', '');
        GeneralLedgerSetup.Get();
        BusUnitInConsProcess.SetRange("Consolidation Process Id", ConsolidationProcess.Id);
        BusUnitInConsProcess.SetRange("Default Data Import Method", BusUnitInConsProcess."Default Data Import Method"::API);

        ConsolidationProcess.Status := ConsolidationProcess.Status::InProgress;
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GenJournalBatch.Get(ConsolidationProcess."Journal Template Name", ConsolidationProcess."Journal Batch Name");
            GenJournalBatch.TestField("No. Series");
            ConsolidationProcess."Document No." := NoSeriesManagement.GetNextNo(GenJournalBatch."No. Series", WorkDate(), true);
        end;
        ConsolidationProcess.Modify();
        Commit();
        if BusUnitInConsProcess.FindSet() then begin
            FeatureTelemetry.LogUptake('0000KOJ', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
            FeatureTelemetry.LogUptake('0000KOG', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
            repeat
                BusinessUnit.Get(BusUnitInConsProcess."Business Unit Code");
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::ImportingData;
                BusUnitInConsProcess.Modify();
                Commit();
                Clear(ImportConsolidationFromAPI);
                ImportConsolidationFromAPI.ImportConsolidationForBusinessUnit(ConsolidationProcess, BusinessUnit);
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::Finished;
                BusUnitInConsProcess.Modify();
                Commit();
            until BusUnitInConsProcess.Next() = 0;
            FeatureTelemetry.LogUsage('0000KOH', ImportConsolidationFromAPI.GetFeatureTelemetryName(), 'Completed consolidation imported from API');
        end;
        BusUnitInConsProcess.SetRange("Default Data Import Method", BusUnitInConsProcess."Default Data Import Method"::Database);
        if BusUnitInConsProcess.FindSet() then
            repeat
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::ImportingData;
                BusUnitInConsProcess.Modify();
                Commit();
                Clear(ImportConsolidationFromDB);
                ImportConsolidationFromDB.SetConsolidationProcessParameters(ConsolidationProcess, BusUnitInConsProcess);
                ImportConsolidationFromDB.Execute('');
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::Finished;
                BusUnitInConsProcess.Modify();
                Commit();
            until BusUnitInConsProcess.Next() = 0;
        ConsolidationProcess.Status := ConsolidationProcess.Status::Completed;
        ConsolidationProcess.Modify();
    end;

}
