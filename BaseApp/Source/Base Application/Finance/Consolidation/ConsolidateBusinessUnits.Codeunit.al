namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

codeunit 110 "Consolidate Business Units"
{
    var
        EmptyDateRangeErr: Label 'You must specify the starting date and the ending date for the consolidation.';
        ClosingDateErr: Label 'The starting date or the ending date is a closing date, and they are not the same.';
        YouMustCreateFiscalYearErr: Label 'You must create a new fiscal year for the consolidation company.';
        ConsolidationPeriodOutsideFiscalYearErr: Label 'The consolidation period %1 .. %2 is outside the fiscal year %3 .. %4 in the consolidation company. Do you want to continue?', Comment = '%1 - Starting date, %2 - Ending date, %3 - Starting date, %4 - Ending date';
        PleaseSpecifyErr: Label '"%1" is mandatory in General Ledger Setup, but it is not specified.', Comment = '%1 - Field name';
        PleaseSpecifyNoSeriesErr: Label 'Specify a No. Series in the General Journal Batch %1.', Comment = '%1 - The code of the general journal batch';
        BusinessUnitStartingDateLaterErr: Label 'The ending date is earlier than the starting date for the business unit %1.', Comment = '%1 - The code of the business unit';
        PleaseSpecifyDocNoErr: Label 'Please specify a document number for the consolidation journal.';
        ConfirmConsolidationDatesForBusinessUnitMsg: Label 'The business unit %1 has the date range %2 .. %3 configured. Do you want to consolidate the period %4 .. %5?', Comment = '%1 - Code of the business unit, %2 - starting date, %3 - ending date, %4 - starting date, %5 - ending date';
        SelectOneBusinessUnitErr: Label 'Select at least one business unit to consolidate.';
        MaxNumberOfDaysInConsolidationErr: Label 'Maximum number of days in consolidation is %1.', Comment = '%1 - The maximum number of days in consolidation';
        FollowingCompaniesHaveNoAccessErr: Label 'The business units %1 have not been granted access. Select them and use the action "Grant Access" to authenticate into these companies.', Comment = '%1 comma separated names of the business units'' codes';

    internal procedure StartConsolidation(var ConsolidationProcess: Record "Consolidation Process" temporary; var BusinessUnit: Record "Business Unit" temporary)
    var
        ConsolidationSetup: Record "Consolidation Setup";
    begin
        ConsolidationSetup.GetOrCreateWithDefaults();
        ValidateConsolidationParameters(ConsolidationProcess, BusinessUnit, false);
        ScheduleConsolidation(ConsolidationProcess, BusinessUnit);
    end;

    internal procedure ValidateDatesForConsolidation(StartingDate: Date; EndingDate: Date; AskConfirmation: Boolean)
    var
        Consolidate: Codeunit Consolidate;
    begin
        if (StartingDate = 0D) or (EndingDate = 0D) then
            Error(EmptyDateRangeErr);
        if (StartingDate = ClosingDate(StartingDate)) or (EndingDate = ClosingDate(EndingDate)) then
            if StartingDate <> EndingDate then
                Error(ClosingDateErr);
        if not Consolidate.ValidateMaxNumberOfDaysInConsolidation(StartingDate, EndingDate) then
            Error(MaxNumberOfDaysInConsolidationErr, Consolidate.MaxNumberOfDaysInConsolidation());
        ValidateDatesToBeInSameFiscalYear(StartingDate, EndingDate, AskConfirmation);
    end;

    internal procedure ValidateConsolidationParameters(var ConsolidationProcess: Record "Consolidation Process" temporary; var BusinessUnit: Record "Business Unit" temporary; AskConfirmation: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ValidateDatesForConsolidation(ConsolidationProcess."Starting Date", ConsolidationProcess."Ending Date", AskConfirmation);
        ValidateJournalForConsolidation(GeneralLedgerSetup."Journal Templ. Name Mandatory", ConsolidationProcess."Journal Template Name", ConsolidationProcess."Journal Batch Name", ConsolidationProcess."Document No.");
        ValidateBusinessUnitsToConsolidate(BusinessUnit);
        ValidateDatesForBusinessUnits(BusinessUnit, ConsolidationProcess."Starting Date", ConsolidationProcess."Ending Date", AskConfirmation);
    end;

    internal procedure GetLastConsolidationEndingDate(BusinessUnit: Record "Business Unit"): Date
    var
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
    begin
        BusUnitInConsProcess.SetRange(Status, BusUnitInConsProcess.Status::Finished);
        BusUnitInConsProcess.SetRange("Business Unit Code", BusinessUnit.Code);
        BusUnitInConsProcess.SetCurrentKey(SystemCreatedAt);
        BusUnitInConsProcess.SetAscending(SystemCreatedAt, false);
        if not BusUnitInConsProcess.FindFirst() then
            exit(0D);
        exit(BusUnitInConsProcess."Ending Date");
    end;

    internal procedure BusinessUnitConsolidationProcessesInDateRange(BusinessUnit: Record "Business Unit"; StartingDate: Date; EndingDate: Date): Boolean
    var
        BusUnitConsProcess: Record "Bus. Unit In Cons. Process";
    begin
        BusUnitConsProcess.SetAutoCalcFields("Starting Date", "Ending Date");
        BusUnitConsProcess.SetRange("Business Unit Code", BusinessUnit.Code);
        BusUnitConsProcess.SetRange(Status, BusUnitConsProcess.Status::Finished);
        BusUnitConsProcess.SetRange("Ending Date", StartingDate, EndingDate);
        if not BusUnitConsProcess.IsEmpty() then
            exit(true);
        BusUnitConsProcess.SetRange("Ending Date");
        BusUnitConsProcess.SetRange("Starting Date", StartingDate, EndingDate);
        if not BusUnitConsProcess.IsEmpty() then
            exit(true);
        BusUnitConsProcess.SetRange("Starting Date", 0D, StartingDate);
        BusUnitConsProcess.SetFilter("Ending Date", '>%1', EndingDate);
        if not BusUnitConsProcess.IsEmpty() then
            exit(true);
        exit(false);
    end;

    internal procedure ValidateBusinessUnitsToConsolidate(var BusinessUnit: Record "Business Unit" temporary)
    var
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
        CompaniesWithNoAccess: Text;
    begin
        BusinessUnit.SetRange(Consolidate, true);
        if not BusinessUnit.FindSet() then
            Error(SelectOneBusinessUnitErr);
        repeat
            if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::API then
                if not ImportConsolidationFromAPI.IsStoredTokenValidForBusinessUnit(BusinessUnit) then begin
                    if CompaniesWithNoAccess <> '' then
                        CompaniesWithNoAccess += ', ';
                    CompaniesWithNoAccess += BusinessUnit.Code;
                end;
        until BusinessUnit.Next() = 0;
        if CompaniesWithNoAccess <> '' then
            Error(FollowingCompaniesHaveNoAccessErr, CompaniesWithNoAccess);
    end;

    local procedure ScheduleConsolidation(var TempConsolidationProcess: Record "Consolidation Process" temporary; var BusinessUnit: Record "Business Unit" temporary)
    var
        ConsolidationProcess: Record "Consolidation Process";
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
        ImportAndConsolidate: Codeunit "Import and Consolidate";
    begin
        BusinessUnit.SetRange(Consolidate, true);
        if not BusinessUnit.FindSet() then
            exit;
        ConsolidationProcess.TransferFields(TempConsolidationProcess);
        ConsolidationProcess.Status := ConsolidationProcess.Status::NotStarted;
        ConsolidationProcess.Insert();
        repeat
            BusUnitInConsProcess."Consolidation Process Id" := ConsolidationProcess.Id;
            BusUnitInConsProcess."Business Unit Code" := BusinessUnit.Code;
            BusUnitInConsProcess."Average Exchange Rate" := BusinessUnit."Income Currency Factor";
            BusUnitInConsProcess."Closing Exchange Rate" := BusinessUnit."Balance Currency Factor";
            BusUnitInConsProcess."Last Closing Exchange Rate" := BusinessUnit."Last Balance Currency Factor";
            BusUnitInConsProcess."Currency Exchange Rate Table" := BusinessUnit."Currency Exchange Rate Table";
            BusUnitInConsProcess."Currency Code" := BusinessUnit."Currency Code";
            BusUnitInConsProcess.Insert();
        until BusinessUnit.Next() = 0;
        ImportAndConsolidate.ImportAndConsolidate(ConsolidationProcess);
    end;

    local procedure ValidateDatesForBusinessUnits(var BusinessUnit: Record "Business Unit" temporary; StartingDate: Date; EndingDate: Date; AskConfirmation: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if (StartingDate <> NormalDate(StartingDate)) and (EndingDate <> NormalDate(EndingDate)) then
            exit;
        BusinessUnit.SetRange(Consolidate, true);
        BusinessUnit.FindSet();
        repeat
            if (BusinessUnit."Starting Date" <> 0D) or (BusinessUnit."Ending Date" <> 0D) then begin
                BusinessUnit.TestField("Starting Date");
                BusinessUnit.TestField("Ending Date");
                if BusinessUnit."Starting Date" > BusinessUnit."Ending Date" then
                    Error(BusinessUnitStartingDateLaterErr, BusinessUnit.Code);
                if AskConfirmation and ((StartingDate < BusinessUnit."Starting Date") or (EndingDate > BusinessUnit."Ending Date")) then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmConsolidationDatesForBusinessUnitMsg, BusinessUnit.Code, BusinessUnit."Starting Date", BusinessUnit."Ending Date", StartingDate, EndingDate), true) then
                        Error('');
            end
        until BusinessUnit.Next() = 0;
    end;

    local procedure ValidateDatesToBeInSameFiscalYear(StartingDate: Date; EndingDate: Date; AskConfirmation: Boolean)
    var
        AccountingPeriod: Record "Accounting Period";
        ConfirmManagement: Codeunit "Confirm Management";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
    begin
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetCurrentKey("Starting Date");
        AccountingPeriod.Ascending(true);
        if not AccountingPeriod.FindSet() then
            exit;
        FiscalYearStartDate := AccountingPeriod."Starting Date";
        if AccountingPeriod.Next() = 0 then
            Error(YouMustCreateFiscalYearErr);
        FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
        if AskConfirmation and ((StartingDate < FiscalYearStartDate) or (EndingDate > FiscalYearEndDate)) then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConsolidationPeriodOutsideFiscalYearErr, StartingDate, EndingDate, FiscalYearStartDate, FiscalYearEndDate), true) then
                Error('');
    end;

    internal procedure ValidateJournalForConsolidation(JournalTemplateNameMandatory: Boolean; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if JournalTemplateNameMandatory then begin
            if JournalTemplateName = '' then
                Error(PleaseSpecifyErr, GenJournalTemplate.TableCaption);
            if JournalBatchName = '' then
                Error(PleaseSpecifyErr, GenJournalBatch.TableCaption);
            GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
            if GenJournalBatch."No. Series" = '' then
                Error(PleaseSpecifyNoSeriesErr, JournalTemplateName + '-' + JournalBatchName);
            exit;
        end;
        if DocumentNo = '' then
            Error(PleaseSpecifyDocNoErr);
    end;

}