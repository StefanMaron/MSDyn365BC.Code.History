﻿#if not CLEAN24
namespace System.Environment.Configuration;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;

codeunit 5891 "Feature-GLCurrencyRevaluation" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = TableData "Feature Data Update Status" = rm;
    ObsoleteReason = 'Feature G/L Currency Revaluation will be enabled by default in version 27.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    // The Data upgrade codeunit for G/L Currency Revaluation
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        GLAccountRevaluationTxt: Label 'G/L Currency Revaluation';
        DescriptionTxt: Label '(CH Only) If you enable this feature, data from local Currency Code and Amount fields will be transferred to new Source Currency and Amount fields.';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        // Data upgrade is not required if following tables do not have source currency data:
        // table 15 G/L Account
        // table 17 G/L Entry
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty());
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");  // Data is not per company
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        MigrateCurrencyData();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, GLAccountRevaluationTxt, StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords(): Integer
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        GLAccount.SetFilter("Currency Code", '<>%1', '');
        GLEntry.SetFilter("Amount (FCY)", '<>%1', 0);
        if GLAccount.IsEmpty() and GLEntry.IsEmpty() then
            exit(0);

        InsertDocumentEntry(Database::"G/L Account", GLAccount.TableCaption(), GLAccount.CountApprox());
        InsertDocumentEntry(Database::"G/L Entry", GLEntry.TableCaption(), GLEntry.CountApprox());
    end;

    local procedure MigrateCurrencyData()
    var
        GLAccount: Record "G/L Account";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
        GLEntry: Record "G/L Entry";
        CurrencyCounter: Integer;
    begin
        GLAccount.Reset();
        if GLAccount.FindSet(true) then
            repeat
                GLAccountSourceCurrency.SetRange("G/L Account No.", GLAccount."No.");
                GLAccountSourceCurrency.BuildCurrencyList();
                CurrencyCounter := GLAccountSourceCurrency.Count();
                if CurrencyCounter = 1 then begin
                    GLAccountSourceCurrency.FindFirst();
                    GLAccount."Source Currency Posting" := GLAccount."Source Currency Posting"::"Same Currency";
                    GLAccount."Source Currency Code" := GLAccountSourceCurrency."Currency Code";
                end else
                    if CurrencyCounter > 1 then
                        GLAccount."Source Currency Posting" := GLAccount."Source Currency Posting"::"Multiple Currencies";
                if CurrencyCounter > 0 then
                    GLAccount.Modify();
            until GLAccount.Next() = 0;

        GLEntry.SetFilter("Amount (FCY)", '<>%1', 0);
        if GLEntry.FindSet() then
            repeat
                GLAccount.Get(GLEntry."G/L Account No.");
                GLEntry."Source Currency Code" := GLAccount."Source Currency Code";
                GLEntry."Source Currency Amount" := GLEntry."Amount (FCY)";
                GLEntry.Modify();
            until GLEntry.Next() = 0;
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}
#endif