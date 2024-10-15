#if not CLEAN23
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using System.Telemetry;

codeunit 446 "IC Mapping Dimensions"
{
    Access = Internal;

    trigger OnRun()
    begin
    end;

    procedure MapICDimensions(var ICDimensions: Record "IC Dimension")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIT', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensions.IsEmpty() then
            exit;

        ICDimensions.FindSet();
        repeat
            MapIncomingICDimensions(ICDimensions);
        until ICDimensions.Next() = 0;
    end;

    procedure MapCompanyDimensions(var Dimensions: Record Dimension)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIU', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if Dimensions.IsEmpty() then
            exit;

        Dimensions.FindSet();
        repeat
            MapOutgoingICDimensions(Dimensions);
        until Dimensions.Next() = 0;
    end;

    procedure RemoveICMapping(var ICDimension: Record "IC Dimension")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVW', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimension.IsEmpty() then
            exit;

        ICDimension.FindSet();
        repeat
            RemoveMapDimensions(ICDimension);
        until ICDimension.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var Dimensions: Record Dimension)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVX', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if Dimensions.IsEmpty() then
            exit;

        Dimensions.FindSet();
        repeat
            RemoveMapDimensions(Dimensions);
        until Dimensions.Next() = 0;
    end;

    procedure MapICDimensionValues(var ICDimensionValues: Record "IC Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J35', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensionValues.IsEmpty() then
            exit;

        ICDimensionValues.FindSet();
        repeat
            MapIncomingICDimensionValues(ICDimensionValues);
        until ICDimensionValues.Next() = 0;
    end;

    procedure MapCompanyDimensionValues(var DimensionValues: Record "Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J36', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if DimensionValues.IsEmpty() then
            exit;

        DimensionValues.FindSet();
        repeat
            MapOutgoingICDimensionValues(DimensionValues);
        until DimensionValues.Next() = 0;
    end;

    procedure RemoveICMapping(var ICDimensionValue: Record "IC Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J37', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensionValue.IsEmpty() then
            exit;

        ICDimensionValue.FindSet();
        repeat
            RemoveMapDimensionValues(ICDimensionValue);
            ICDimensionValue.Modify();
        until ICDimensionValue.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var DimensionValues: Record "Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J38', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if DimensionValues.IsEmpty() then
            exit;

        DimensionValues.FindSet();
        repeat
            RemoveMapDimensionValues(DimensionValues);
            DimensionValues.Modify();
        until DimensionValues.Next() = 0;
    end;

    procedure MapIncomingICDimensions(ICDimension: Record "IC Dimension")
    var
        Dimension: Record Dimension;
        ICDimensionValue: Record "IC Dimension Value";
    begin

        if Dimension.Get(ICDimension.Code) then begin
            ICDimension."Map-to Dimension Code" := Dimension.Code;
            ICDimension.Modify();
            ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
            if not ICDimensionValue.IsEmpty() then begin
                ICDimensionValue.ModifyAll("Map-to Dimension Code", ICDimension."Map-to Dimension Code");
                ICDimensionValue.FindSet();
                repeat
                    MapIncomingICDimensionValues(ICDimensionValue);
                until ICDimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure MapOutgoingICDimensions(Dimension: Record Dimension)
    var
        ICDimension: Record "IC Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        if ICDimension.Get(Dimension.Code) then begin
            Dimension."Map-to IC Dimension Code" := ICDimension.Code;
            Dimension.Modify();
            DimensionValue.SetRange("Dimension Code", Dimension.Code);
            if not DimensionValue.IsEmpty() then begin
                DimensionValue.ModifyAll("Map-to IC Dimension Code", Dimension."Map-to IC Dimension Code");
                DimensionValue.FindSet();
                repeat
                    MapOutgoingICDimensionValues(DimensionValue);
                until DimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure MapIncomingICDimensionValues(var ICDimensionValue: Record "IC Dimension Value")
    var
        DimensionValue: Record "Dimension Value";
    begin
        if not DimensionValue.Get(ICDimensionValue."Dimension Code", ICDimensionValue.Code) then
            exit;

        if DimensionValue."Dimension Code" <> ICDimensionValue."Map-to Dimension Code" then
            exit;

        if DimensionValue."Dimension Value Type" = ICDimensionValue."Dimension Value Type" then begin
            ICDimensionValue.Validate("Map-to Dimension Value Code", DimensionValue.Code);
            ICDimensionValue.Modify();
        end;
    end;

    procedure MapOutgoingICDimensionValues(var DimensionValue: Record "Dimension Value")
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        if not ICDimensionValue.Get(DimensionValue."Dimension Code", DimensionValue.Code) then
            exit;

        if ICDimensionValue."Dimension Code" <> DimensionValue."Map-to IC Dimension Code" then
            exit;

        if ICDimensionValue."Dimension Value Type" = DimensionValue."Dimension Value Type" then begin
            DimensionValue.Validate("Map-to IC Dimension Value Code", ICDimensionValue.Code);
            DimensionValue.Modify();
        end;
    end;

    procedure RemoveMapDimensions(ICDimensions: Record "IC Dimension")
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        if ICDimensions."Map-to Dimension Code" <> '' then begin
            Clear(ICDimensions."Map-to Dimension Code");
            ICDimensions.Modify();
        end;

        ICDimensionValue.SetRange("Dimension Code", ICDimensions.Code);
        if not ICDimensionValue.IsEmpty() then begin
            ICDimensionValue.FindSet();
            repeat
                ICDimensionValue."Map-to Dimension Code" := '';
                RemoveMapDimensionValues(ICDimensionValue);
                ICDimensionValue.Modify();
            until ICDimensionValue.Next() = 0;
        end;
    end;

    procedure RemoveMapDimensions(CompanyDimension: Record Dimension)
    var
        DimensionValue: Record "Dimension Value";
    begin
        if CompanyDimension."Map-to IC Dimension Code" <> '' then begin
            Clear(CompanyDimension."Map-to IC Dimension Code");
            CompanyDimension.Modify();
        end;

        DimensionValue.SetRange("Dimension Code", CompanyDimension.Code);
        if not DimensionValue.IsEmpty() then begin
            DimensionValue.FindSet();
            repeat
                DimensionValue."Map-to IC Dimension Code" := '';
                RemoveMapDimensionValues(DimensionValue);
                DimensionValue.Modify();
            until DimensionValue.Next() = 0;
        end;
    end;

    procedure RemoveMapDimensionValues(var ICDimensionValues: Record "IC Dimension Value")
    begin
        if ICDimensionValues."Map-to Dimension Value Code" = '' then
            exit;
        Clear(ICDimensionValues."Map-to Dimension Value Code");
    end;

    procedure RemoveMapDimensionValues(var CompanyDimensionValue: Record "Dimension Value")
    begin
        if CompanyDimensionValue."Map-to IC Dimension Value Code" = '' then
            exit;
        Clear(CompanyDimensionValue."Map-to IC Dimension Value Code");
    end;

    procedure SynchronizeDimensions(DeleteExistingEntries: Boolean; PartnerCode: Code[20])
    var
        PartnersICDimensions: Record "IC Dimension";
        PartnersICDimensionValues: Record "IC Dimension Value";
        ICDimensions: Record "IC Dimension";
        ICDimensionValues: Record "IC Dimension Value";
        TempICDimension: Record "IC Dimension" temporary;
        TempICDimensionValue: Record "IC Dimension Value" temporary;
        ICPartner: Record "IC Partner";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(InboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        // Delete existing IC Dimensions if the syncronization points to a company with no IC Dimensions 
        // and remove the dimensions and dimensions values mapping.
        if not PartnersICDimensions.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnersICDimensions.TableName, ICPartner.Name);
        if not PartnersICDimensionValues.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnersICDimensionValues.TableName, ICPartner.Name);
        if not PartnersICDimensions.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnersICDimensions.TableName, ICPartner.Name);
        if not PartnersICDimensionValues.ReadPermission() then
            Error(MissingPermissionToReadTableErr, PartnersICDimensionValues.TableName, ICPartner.Name);
        if PartnersICDimensions.IsEmpty() then begin
            if not ICDimensions.IsEmpty() then begin
                ICDimensions.DeleteAll();
                Dimension.SetFilter("Map-to IC Dimension Code", '<> ''''');
                if not Dimension.IsEmpty() then
                    Dimension.ModifyAll("Map-to IC Dimension Code", '');
            end;
            if not ICDimensionValues.IsEmpty() then begin
                ICDimensionValues.DeleteAll();
                DimensionValue.SetFilter("Map-to IC Dimension Value Code", '<> ''''');
                if not DimensionValue.IsEmpty() then begin
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", '');
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
            exit;
        end;

        if DeleteExistingEntries then begin
            if not ICDimensions.IsEmpty() then
                ICDimensions.DeleteAll();
            if not ICDimensionValues.IsEmpty() then
                ICDimensionValues.DeleteAll();
        end;

        PartnersICDimensions.FindSet();
        repeat
            TransferICDimensionWithMappingToTemporalRecord(PartnersICDimensions, ICDimensions, TempICDimension);
            ICDimensionValues.Reset();
            PartnersICDimensionValues.SetRange("Dimension Code", PartnersICDimensions.Code);
            if not PartnersICDimensionValues.IsEmpty() then begin
                PartnersICDimensionValues.FindSet();
                repeat
                    TransferICDimensionValueWithMappingToTemporalRecord(PartnersICDimensionValues, ICDimensionValues, TempICDimensionValue);
                until PartnersICDimensionValues.Next() = 0;
            end;
        until PartnersICDimensions.Next() = 0;

        TransferICMappingsAndDeletedICDimensions(ICDimensions, TempICDimension);
        TempICDimension.Reset();
        TempICDimension.FindSet();
        ICDimensions.LockTable();
        repeat
            ICDimensions.TransferFields(TempICDimension);
            ICDimensions.Insert();
        until TempICDimension.Next() = 0;

        TransferICMappingsAndDeletedICDimensionValues(ICDimensionValues, TempICDimensionValue);
        TempICDimensionValue.Reset();
        TempICDimensionValue.FindSet();
        ICDimensionValues.LockTable();
        repeat
            ICDimensionValues.TransferFields(TempICDimensionValue);
            ICDimensionValues.Insert();
        until TempICDimensionValue.Next() = 0;

        TempICDimension.DeleteAll();
        TempICDimensionValue.DeleteAll();
    end;

    local procedure TransferICDimensionWithMappingToTemporalRecord(var PartnersICDimensions: Record "IC Dimension"; var ICDimensions: Record "IC Dimension"; var TempICDimension: Record "IC Dimension" temporary)
    begin
        if ICDimensions.Get(PartnersICDimensions.Code) then begin
            TempICDimension.TransferFields(ICDimensions);
            TempICDimension.Insert();
        end
        else begin
            TempICDimension.Init();
            TempICDimension.Code := PartnersICDimensions.Code;
            TempICDimension.Name := PartnersICDimensions.Name;
            TempICDimension.Blocked := PartnersICDimensions.Blocked;
            TempICDimension.Insert();
        end;
    end;

    local procedure TransferICDimensionValueWithMappingToTemporalRecord(var PartnersICDimensionValues: Record "IC Dimension Value"; var ICDimensionValues: Record "IC Dimension Value"; var TempICDimensionValue: Record "IC Dimension Value" temporary)
    begin
        if ICDimensionValues.Get(PartnersICDimensionValues."Dimension Code", PartnersICDimensionValues.Code) then begin
            TempICDimensionValue.TransferFields(ICDimensionValues);
            TempICDimensionValue.Insert();
        end
        else begin
            TempICDimensionValue.Init();
            TempICDimensionValue."Dimension Code" := PartnersICDimensionValues."Dimension Code";
            TempICDimensionValue.Code := PartnersICDimensionValues.Code;
            TempICDimensionValue.Name := PartnersICDimensionValues.Name;
            TempICDimensionValue."Dimension Value Type" := PartnersICDimensionValues."Dimension Value Type";
            TempICDimensionValue.Blocked := PartnersICDimensionValues.Blocked;
            TempICDimensionValue.Insert();
        end;
    end;

    local procedure TransferICMappingsAndDeletedICDimensions(var ICDimensions: Record "IC Dimension"; var TempICDimension: Record "IC Dimension" temporary)
    var
        Dimension: Record Dimension;
    begin
        ICDimensions.Reset();
        TempICDimension.Reset();
        if ICDimensions.IsEmpty() then
            exit;

        ICDimensions.FindSet();
        repeat
            if TempICDimension.Get(ICDimensions.Code) then begin
                Dimension.SetRange("Map-to IC Dimension Code", ICDimensions.Code);
                if not Dimension.IsEmpty() then
                    Dimension.ModifyAll("Map-to IC Dimension Code", '');
            end;
        until ICDimensions.Next() = 0;

        ICDimensions.Reset();
        if not ICDimensions.IsEmpty() then
            ICDimensions.DeleteAll();
    end;

    local procedure TransferICMappingsAndDeletedICDimensionValues(var ICDimensionValues: Record "IC Dimension Value"; var TempICDimensionValue: Record "IC Dimension Value" temporary)
    var
        DimensionValue: Record "Dimension Value";
    begin
        ICDimensionValues.Reset();
        TempICDimensionValue.Reset();
        if ICDimensionValues.IsEmpty() then
            exit;

        ICDimensionValues.FindSet();
        repeat
            if TempICDimensionValue.Get(ICDimensionValues."Dimension Code", ICDimensionValues.Code) then begin
                DimensionValue.SetRange("Map-to IC Dimension Value Code", ICDimensionValues.Code);
                if not DimensionValue.IsEmpty() then begin
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", '');
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
        until ICDimensionValues.Next() = 0;

        ICDimensionValues.Reset();
        if not ICDimensionValues.IsEmpty() then
            ICDimensionValues.DeleteAll();
    end;

    var
        FailedToFindPartnerErr: Label 'There is no partner with code %1 in the list of your intercompany partners.', Comment = '%1 = Partner code';
        InboxTypeNotDatabaseErr: Label 'Syncronization is only available for partners using database as their intercompany inbox type. Partner %1 inbox type is %2', Comment = '%1 = Partner code, %2 = Partner inbox type';
        FailedToChangeCompanyErr: Label 'It was not possible to find table %1 in partner %2.', Comment = '%1 = Table caption, %2 = Partner Code';
        MissingPermissionToReadTableErr: Label 'You do not have the necessary permissions to access table %1 of partner %2.', Comment = '%1 = Table name, %2 = Partner Code';
}
#endif