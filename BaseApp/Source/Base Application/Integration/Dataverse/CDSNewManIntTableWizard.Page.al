
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.SyncEngine;

using System.Reflection;
using System.Utilities;
using System.Environment;
using System.IO;
using Microsoft.Integration.Dataverse;
page 5384 "CDS New Man. Int. Table Wizard"
{
    ApplicationArea = All;
    Caption = 'Create new integration mappings';
    PageType = NavigatePage;
    SourceTable = "Man. Integration Table Mapping";
    layout
    {
        area(content)
        {
            group(StandardBanner)
            {
                ShowCaption = false;
                Editable = false;
                Visible = TopBannerVisible and not FinishActionEnabled;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FinishedBanner)
            {
                ShowCaption = false;
                Editable = false;
                Visible = TopBannerVisible and FinishActionEnabled;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Step1)
            {
                Visible = Step1Visible;
                group(Control0)
                {
                    InstructionalText = 'Choose the tables and fields to set up a new integration mapping.';
                    Visible = Step1Visible;
                    ShowCaption = false;
                }
                group(ChooseName)
                {
                    Caption = 'Enter the name of the new integration table mapping.';
                    field(Name; IntegrationMappingName)
                    {
                        Caption = 'Integration Table Mapping Name';
                        ToolTip = 'Specifies the name of the new integration table mapping.';
                        ShowMandatory = true;
                        trigger OnValidate()
                        var
                            IntegrationTableMapping: Record "Integration Table Mapping";
                            IntegrationMappingNameExistErr: Label 'Integration table name %1 already exists. Please specify a different name';
                        begin
                            IntegrationTableMapping.SetRange(Name, IntegrationMappingName);
                            If not IntegrationTableMapping.IsEmpty then
                                Error(IntegrationMappingNameExistErr, IntegrationMappingName);
                        end;
                    }
                }
                group(whatisnext)
                {
                    ShowCaption = false;
                    InstructionalText = 'To specify details for the new integration table mapping, choose Next.';
                }
            }

            group(Step2)
            {
                Caption = 'Choose the table and integation table for the mapping.';
                Visible = Step2Visible;

                field(TableId; IntegrationMappingTableIdValue)
                {
                    AssistEdit = true;
                    Caption = 'Table';
                    Editable = false;
                    ToolTip = 'Specifies the name of the Business Central table to map to the integration table.';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        TableMetadata: Record "Table Metadata";
                        IntegrationTableMapping: Record "Integration Table Mapping";
                        TableFilterTxt: Text;
                    begin
                        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                        if IntegrationTableMapping.FindSet() then
                            repeat
                                if TableFilterTxt = '' then
                                    TableFilterTxt := '<>' + Format(IntegrationTableMapping."Table ID")
                                else
                                    TableFilterTxt += '&<>' + Format(IntegrationTableMapping."Table ID");
                            until IntegrationTableMapping.Next() = 0;

                        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
                        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No);
                        TableMetadata.SetFilter(TableMetadata.ID, TableFilterTxt);
                        if PAGE.RunModal(PAGE::"Available Table Selection List", TableMetadata) = ACTION::LookupOK then begin
                            IntegrationMappingTableId := TableMetadata.ID;
                            IntegrationMappingTableIdValue := TableMetadata.Caption;
                        end;
                    end;

                }
                field(IntegrationTableID; IntegrationMappingIntTableIdValue)
                {
                    AssistEdit = true;
                    Caption = 'Integration Table';
                    Editable = false;
                    ToolTip = 'Specifies the name of the integration table to map to the Business Central table.';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        TableMetadata: Record "Table Metadata";
                        IntegrationTableMapping: Record "Integration Table Mapping";
                        TableFilterTxt: Text;
                    begin
                        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                        if IntegrationTableMapping.FindSet() then
                            repeat
                                if TableFilterTxt = '' then
                                    TableFilterTxt := '<>' + Format(IntegrationTableMapping."Integration Table ID")
                                else
                                    TableFilterTxt += '&<>' + Format(IntegrationTableMapping."Integration Table ID");
                            until IntegrationTableMapping.Next() = 0;

                        TableMetadata.SetRange(TableType, TableMetadata.TableType::CRM);
                        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No);
                        TableMetadata.SetFilter(TableMetadata.ID, TableFilterTxt);
                        if PAGE.RunModal(PAGE::"Available Table Selection List", TableMetadata) = ACTION::LookupOK then begin
                            IntegrationMappingIntTableId := TableMetadata.ID;
                            IntegrationMappingIntTableIdValue := TableMetadata.Caption;
                        end;
                    end;
                }
                field(IntegrationTableUID; IntegrationTableUIDValue)
                {
                    AssistEdit = true;
                    Caption = 'Integration Table Unique Identifier Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the unique identifier field in the integration table.';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        "Field": Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, IntegrationMappingIntTableId);
                        Field.SetRange(Type, Field.Type::GUID);
                        if FieldSelection.Open(Field) then begin
                            IntegrationTableUID := Field."No.";
                            IntegrationTableUIDValue := Field."Field Caption";
                        end;
                    end;
                }
                field(IntTblModifiedOnId; IntTblModifiedOnIdValue)
                {
                    AssistEdit = true;
                    Caption = 'Integration Table Modified On Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field that shows when the integration table was last modified.';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        Field: Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, IntegrationMappingIntTableId);
                        Field.SetRange(Type, Field.Type::DateTime);
                        if FieldSelection.Open(Field) then begin
                            IntTblModifiedOnId := Field."No.";
                            IntTblModifiedOnIdValue := Field."Field Caption"
                        end;
                    end;
                }
                field(SyncOnlyCoupledRecords; SyncOnlyCoupledRecords)
                {
                    Caption = 'Sync Only Coupled Records';
                    ToolTip = 'Specifies if the synchronization engine will process only currently coupled records or couple the newly created records as well.';
                }
                field(Direction; Direction)
                {
                    Caption = 'Direction';
                    ToolTip = 'Specifies the synchronization direction.';
                    OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
                }
                group(advanced)
                {
                    Caption = 'Advanced';
                    Visible = AdvancedVisible;

                    field(TableFilterValue; TableFilter)
                    {
                        Caption = 'Table Filter';
                        Editable = false;
                        ToolTip = 'Specifies the synchronization inclusion filter on the Business Central table. Records that fall outside this filter are not synchronized.';

                        trigger OnAssistEdit()
                        var
                            FilterPageBuilder: FilterPageBuilder;
                        begin
                            FilterPageBuilder.AddTable(IntegrationMappingTableIdValue, IntegrationMappingTableId);
                            if TableFilter <> '' then
                                FilterPageBuilder.SetView(IntegrationMappingTableIdValue, TableFilter);
                            if FilterPageBuilder.RunModal() then begin
                                TableFilter := FilterPageBuilder.GetView(IntegrationMappingTableIdValue, false);
                            end;
                        end;
                    }
                    field(IntegrationTableFilterValue; IntegrationTableFilter)
                    {
                        Caption = 'Integration Table Filter';
                        Editable = false;
                        ToolTip = 'Specifies the synchronization inclusion filter on the table in the system you are integrating with. Records that fall outside this filter are not synchronized.';

                        trigger OnAssistEdit()
                        var
                            FilterPageBuilder: FilterPageBuilder;
                            IntegrationTableMapping: Record "Integration Table Mapping";
                        begin
                            Codeunit.Run(Codeunit::"CRM Integration Management");
                            FilterPageBuilder.AddTable(IntegrationMappingIntTableIdValue, IntegrationMappingIntTableId);
                            if IntegrationTableFilter <> '' then
                                FilterPageBuilder.SetView(IntegrationMappingIntTableIdValue, IntegrationTableFilter);
                            Commit();
                            if FilterPageBuilder.RunModal() then begin
                                IntegrationTableFilter := FilterPageBuilder.GetView(IntegrationMappingIntTableIdValue, false);
                                IntegrationTableMapping.SuggestToIncludeEntitiesWithNullCompany(IntegrationTableFilter);
                            end;
                        end;
                    }
                    field(TableConfigTemplateCode; TableConfigTemplateCode)
                    {
                        Caption = 'Table Config. Template Code';
                        ToolTip = 'Specifies a configuration template to use when creating new records in the Business Central table (specified by the Table ID field) during synchronization.';
                        Lookup = true;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ConfigTemplateHeader: Record "Config. Template Header";
                        begin
                            ConfigTemplateHeader.SetRange("Table ID", IntegrationMappingTableId);
                            if PAGE.RunModal(PAGE::"Config. Template List", ConfigTemplateHeader) = ACTION::LookupOK then begin
                                TableConfigTemplateCode := ConfigTemplateHeader.Code;
                            end;
                        end;
                    }
                    field(IntTableConfigTemplateCode; IntTableConfigTemplateCode)
                    {
                        Caption = 'Int. Tbl. Config Template Code';
                        ToolTip = 'Specifies a configuration template to use for creating new records in the integration table.';
                        Lookup = true;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ConfigTemplateHeader: Record "Config. Template Header";
                        begin
                            ConfigTemplateHeader.SetRange("Table ID", IntegrationMappingIntTableId);
                            if PAGE.RunModal(PAGE::"Config. Template List", ConfigTemplateHeader) = ACTION::LookupOK then begin
                                TableConfigTemplateCode := ConfigTemplateHeader.Code;
                            end;
                        end;
                    }
                }
                group(whatisnextField)
                {
                    ShowCaption = false;
                    InstructionalText = 'To specify details for the new integration field mappings, choose Next.';
                }
            }

            group(Step3)
            {
                Visible = Step3Visible;
                group(Group23)
                {
                    ShowCaption = false;
                    InstructionalText = 'Choose the fields for the new integration table mapping.';
                    part(ManIntFieldMappingList; "Man. Int. Field Mapping Wizard")
                    {

                    }
                }
            }
            group(Step4)
            {
                Visible = Step4Visible;
                group(Group24)
                {
                    Caption = 'You''re almost done.';
                    InstructionalText = 'Choose Finish to do the following:';
                }
                group(Group25)
                {
                    ShowCaption = false;
                    InstructionalText = '- Create new integration table and field mappings.';
                }
                group(Group26)
                {
                    ShowCaption = false;
                    InstructionalText = '- Insert new integration fields mappings with the status Disabled.';
                }
                group(Group27)
                {
                    ShowCaption = false;
                    Visible = not SetupExistingIntegrationMapping;
                    InstructionalText = '- Create a Synchronization Job Queue Entry with the status On hold.';
                }
                group(Group28)
                {
                    ShowCaption = false;
                    Visible = SetupExistingIntegrationMapping;
                    InstructionalText = 'NOTE: To update existing data, choose Run Unconditional Full Synchronization on the Integration Table Mappings page. The action will synchronize data from the new field mappings you just added.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ActionAdvanced)
            {
                ApplicationArea = All;
                Caption = 'Advanced';
                Enabled = Step2Visible;
                Image = ExpandAll;
                InFooterBar = true;
                trigger OnAction();
                begin
                    if AdvancedVisible then
                        AdvancedVisible := false
                    else
                        AdvancedVisible := true;
                    CurrPage.Update();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit();
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage();
    begin
        if not SetupExistingIntegrationMapping then
            Step := Step::Start
        else
            Step := Step::Step3;

        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Step <> Step::Closed then
            if not Confirm(CloseWizardLbl, false) then
                exit(false);
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        Step: Option Start,Step2,Step3,Finish,Closed;
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step4Visible: Boolean;
        TopBannerVisible: Boolean;
        SyncOnlyCoupledRecords: Boolean;
        SetupExistingIntegrationMapping: Boolean;
        AdvancedVisible: Boolean;
        IntegrationMappingName: Code[20];
        TableConfigTemplateCode: Code[20];
        IntTableConfigTemplateCode: Code[20];
        IntegrationMappingTableId: Integer;
        IntegrationMappingIntTableId: Integer;
        IntegrationTableUID: Integer;
        IntTblModifiedOnId: Integer;
        IntegrationMappingTableIdValue: Text[80];
        IntegrationMappingIntTableIdValue: Text[80];
        IntegrationTableUIDValue: Text[80];
        IntTblModifiedOnIdValue: Text[80];
        TableFilter: Text;
        IntegrationTableFilter: Text;
        Direction: Option;
        FillinMandatoryFieldsLbl: Label 'Please fill in all the mandatory fields.';
        CloseWizardLbl: Label 'Do you really want to close? Data is not saved.';

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Step3:
                ShowStep3();
            Step::Finish:
                ShowStep4();
        end;
    end;

    local procedure StoreRecordVar()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
        ManIntFieldMappingTemp: Record "Man. Int. Field Mapping" temporary;
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        if not SetupExistingIntegrationMapping then
            Rec.InsertIntegrationTableMapping(
                    IntegrationTableMapping, IntegrationMappingName,
                    IntegrationMappingTableId, IntegrationMappingIntTableId,
                    IntegrationTableUID, IntTblModifiedOnId,
                    TableConfigTemplateCode, IntTableConfigTemplateCode, SyncOnlyCoupledRecords,
                    Direction);

        if not ManIntegrationTableMapping.Get(IntegrationMappingName) then
            Rec.CreateRecord(IntegrationMappingName,
                    IntegrationMappingTableId, IntegrationMappingIntTableId,
                    IntegrationTableUID, IntTblModifiedOnId,
                    SyncOnlyCoupledRecords, Direction, TableFilter, IntegrationTableFilter,
                    TableConfigTemplateCode, IntTableConfigTemplateCode);

        //fields
        CurrPage.ManIntFieldMappingList.Page.GetValues(ManIntFieldMappingTemp);
        ManIntFieldMappingTemp.Reset();
        ManIntFieldMappingTemp.SetRange(Name, '');
        if ManIntFieldMappingTemp.FindSet() then
            repeat
                Rec.InsertIntegrationFieldMapping(
                    IntegrationMappingName,
                    ManIntFieldMappingTemp."Table Field No.",
                    ManIntFieldMappingTemp."Integration Table Field No.",
                    ManIntFieldMappingTemp.Direction,
                    ManIntFieldMappingTemp."Const Value",
                    ManIntFieldMappingTemp."Validate Field",
                    ManIntFieldMappingTemp."Validate Integr. Table Field",
                    not SetupExistingIntegrationMapping,
                    ManIntFieldMappingTemp."Transformation Rule");

                ManIntFieldMapping.CreateRecord(
                    IntegrationMappingName,
                    ManIntFieldMappingTemp."Table Field No.",
                    ManIntFieldMappingTemp."Integration Table Field No.",
                    ManIntFieldMappingTemp.Direction,
                    ManIntFieldMappingTemp."Const Value",
                    ManIntFieldMappingTemp."Validate Field",
                    ManIntFieldMappingTemp."Validate Integr. Table Field",
                    ManIntFieldMappingTemp."Transformation Rule");

            until ManIntFieldMappingTemp.Next() = 0;

        if not SetupExistingIntegrationMapping then begin
            IntegrationTableMapping.SetTableFilter(TableFilter);
            IntegrationTableMapping.SetIntegrationTableFilter(IntegrationTableFilter);
            IntegrationTableMapping."User Defined" := true;
            IntegrationTableMapping.Modify(true);
        end;

        Commit();

        CDSSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping);
    end;


    local procedure FinishAction()
    begin
        StoreRecordVar();
        Step := Step::Closed;
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if not (SetupExistingIntegrationMapping) and (not Backwards) then begin
            if Step = Step::Start then begin
                if IntegrationMappingName = '' then
                    Error(FillinMandatoryFieldsLbl);
            end;

            if Step = Step::Step2 then begin
                if (IntegrationMappingTableId = 0) OR
                    (IntegrationMappingIntTableId = 0) OR
                    (IntegrationTableUID = 0) OR
                    (IntTblModifiedOnId = 0)
                then
                    Error(FillinMandatoryFieldsLbl);
            end;
        end;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStep1()
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowStep2()
    begin
        Step2Visible := true;
    end;

    local procedure ShowStep3()
    begin
        CurrPage.ManIntFieldMappingList.Page.SetValues(IntegrationMappingTableId, IntegrationMappingIntTableId, IntegrationMappingName);

        Step3Visible := true;
        NextActionEnabled := true;
    end;

    local procedure ShowStep4()
    begin
        Step4Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        if not SetupExistingIntegrationMapping then begin
            BackActionEnabled := true;
            NextActionEnabled := true;
        end;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
        Step4Visible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
            MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
        then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    internal procedure SetValues(lIntegrationMappingName: Code[20]; lIntegrationMappingTableId: Integer; lIntegrationMappingIntTableId: Integer)
    begin
        IntegrationMappingName := lIntegrationMappingName;
        IntegrationMappingTableId := lIntegrationMappingTableId;
        IntegrationMappingIntTableId := lIntegrationMappingIntTableId;
        SetupExistingIntegrationMapping := true;
    end;
}