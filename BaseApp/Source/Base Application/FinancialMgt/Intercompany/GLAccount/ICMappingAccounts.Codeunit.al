#if not CLEAN23
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.Partner;
using System.Telemetry;

codeunit 438 "IC Mapping Accounts"
{
    Access = Internal;

    trigger OnRun()
    begin
    end;

    procedure MapICAccounts(var ICAccounts: Record "IC G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIS', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICAccounts.IsEmpty() then
            exit;

        repeat
            MapAccounts(ICAccounts);
        until ICAccounts.Next() = 0;
    end;

    procedure MapCompanyAccounts(var GLAccounts: Record "G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IV9', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if GLAccounts.IsEmpty() then
            exit;

        GLAccounts.FindSet();
        repeat
            MapAccounts(GLAccounts);
        until GLAccounts.Next() = 0;
    end;

    procedure RemoveICMapping(var ICAccounts: Record "IC G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVA', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICAccounts.IsEmpty() then
            exit;

        ICAccounts.FindSet();
        repeat
            RemoveMapAccounts(ICAccounts);
        until ICAccounts.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var GLAccounts: Record "G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVB', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if GLAccounts.IsEmpty() then
            exit;

        GLAccounts.FindSet();
        repeat
            RemoveMapAccounts(GLAccounts);
        until GLAccounts.Next() = 0;
    end;

    procedure MapAccounts(ICAccount: Record "IC G/L Account")
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(ICAccount."No.") then
            exit;

        if ICAccount."Account Type" = GLAccount."Account Type" then begin
            ICAccount."Map-to G/L Acc. No." := GLAccount."No.";
            ICAccount.Modify();
        end;
    end;

    procedure MapAccounts(GLAccount: Record "G/L Account")
    var
        ICAccount: Record "IC G/L Account";
    begin
        if not ICAccount.Get(GLAccount."No.") then
            exit;

        if GLAccount."Account Type" = ICAccount."Account Type" then begin
            GLAccount."Default IC Partner G/L Acc. No" := ICAccount."No.";
            GLAccount.Modify();
        end;
    end;

    procedure RemoveMapAccounts(ICAccount: Record "IC G/L Account")
    begin
        if ICAccount."Map-to G/L Acc. No." = '' then
            exit;
        Clear(ICAccount."Map-to G/L Acc. No.");
        ICAccount.Modify();
    end;

    procedure RemoveMapAccounts(GLAccount: Record "G/L Account")
    begin
        if GLAccount."Default IC Partner G/L Acc. No" = '' then
            exit;
        Clear(GLAccount."Default IC Partner G/L Acc. No");
        GLAccount.Modify();
    end;

    procedure SynchronizeAccounts(DeleteExistingEntries: Boolean; PartnerCode: Code[20])
    var
        PartnersICAccounts: Record "IC G/L Account";
        ICAccounts: Record "IC G/L Account";
        TempICAccount: Record "IC G/L Account" temporary;
        ICPartner: Record "IC Partner";
        GLAccount: Record "G/L Account";
        PrevIndentation: Integer;
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(InboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        // Delete existing IC Accounts if the syncronization points to a company with no IC Accounts and remove the G/L account mapping.
        if not PartnersICAccounts.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnersICAccounts.TableName, ICPartner.Name);
        if not PartnersICAccounts.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartner.Name);
        if PartnersICAccounts.IsEmpty() then begin
            if not ICAccounts.IsEmpty() then begin
                ICAccounts.DeleteAll();
                GLAccount.SetFilter("Default IC Partner G/L Acc. No", '<> ''''');
                if not GLAccount.IsEmpty() then
                    GLAccount.ModifyAll("Default IC Partner G/L Acc. No", '');
            end;
            exit;
        end;

        if DeleteExistingEntries then
            if not ICAccounts.IsEmpty() then
                ICAccounts.DeleteAll();

        PartnersICAccounts.FindSet();
        repeat
            TransferICAccountWithMappingToTemporalRecord(PartnersICAccounts, ICAccounts, TempICAccount, PrevIndentation);
        until PartnersICAccounts.Next() = 0;

        TransferICMappingsAndDeletedICAccounts(ICAccounts, TempICAccount);
        TempICAccount.Reset();
        TempICAccount.FindSet();
        ICAccounts.LockTable();
        repeat
            ICAccounts.TransferFields(TempICAccount);
            ICAccounts.Indentation := 0;
            ICAccounts.Insert();
        until TempICAccount.Next() = 0;
        TempICAccount.DeleteAll();
    end;

    local procedure TransferICAccountWithMappingToTemporalRecord(var PartnersICAccounts: Record "IC G/L Account"; var ICAccounts: Record "IC G/L Account"; var TempICAccount: Record "IC G/L Account" temporary; var PrevIndentation: Integer)
    begin
        if PartnersICAccounts."Account Type" = PartnersICAccounts."Account Type"::"End-Total" then
            PrevIndentation := PrevIndentation - 1;

        if (ICAccounts.Get(PartnersICAccounts."No.")) and (ICAccounts."Account Type" = PartnersICAccounts."Account Type") then begin
            TempICAccount.TransferFields(PartnersICAccounts);
            TempICAccount."Map-to G/L Acc. No." := ICAccounts."Map-to G/L Acc. No.";
            TempICAccount.Insert();
        end
        else begin
            TempICAccount.Init();
            TempICAccount."No." := PartnersICAccounts."No.";
            TempICAccount.Name := PartnersICAccounts.Name;
            TempICAccount.Blocked := PartnersICAccounts.Blocked;
            TempICAccount."Income/Balance" := PartnersICAccounts."Income/Balance";
            TempICAccount."Account Type" := PartnersICAccounts."Account Type";
            TempICAccount.Validate(Indentation, PrevIndentation);
            TempICAccount.Insert();
        end;

        PrevIndentation := PartnersICAccounts.Indentation;
        if PartnersICAccounts."Account Type" = PartnersICAccounts."Account Type"::"Begin-Total" then
            PrevIndentation := PrevIndentation + 1;
    end;

    local procedure TransferICMappingsAndDeletedICAccounts(var ICAccounts: Record "IC G/L Account"; var TempICAccount: Record "IC G/L Account" temporary)
    var
        GLAccount: Record "G/L Account";
    begin
        ICAccounts.Reset();
        TempICAccount.Reset();
        if ICAccounts.IsEmpty() then
            exit;

        ICAccounts.FindSet();
        repeat
            TempICAccount.SetRange("No.", ICAccounts."No.");
            TempICAccount.SetRange("Account Type", ICAccounts."Account Type");
            if TempICAccount.IsEmpty() then begin
                GLAccount.SetRange("Default IC Partner G/L Acc. No", ICAccounts."No.");
                if not GLAccount.IsEmpty() then
                    GLAccount.ModifyAll("Default IC Partner G/L Acc. No", '');
            end;
        until ICAccounts.Next() = 0;

        ICAccounts.Reset();
        if not ICAccounts.IsEmpty() then
            ICAccounts.DeleteAll();
    end;

    var
        FailedToFindPartnerErr: Label 'There is no partner with code %1 in the list of your intercompany partners.', Comment = '%1 = Partner code';
        InboxTypeNotDatabaseErr: Label 'Syncronization is only available for partners using database as their intercompany inbox type. Partner %1 inbox type is %2', Comment = '%1 = Partner code, %2 = Partner inbox type';
        FailedToChangeCompanyErr: Label 'It was not possible to find table %1 in partner %2.', Comment = '%1 = Table caption, %2 = Partner Code';
        MissingPermissionToReadTableErr: Label 'You do not have the necessary permissions to access the intercompany chart of accounts of partner %1.', Comment = '%1 = Partner Code';
}
#endif