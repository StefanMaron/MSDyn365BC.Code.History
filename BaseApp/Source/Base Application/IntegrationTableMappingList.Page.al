page 5335 "Integration Table Mapping List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Table Mappings';
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Synchronization,Mapping,Uncoupling';
    SourceTable = "Integration Table Mapping";
    SourceTableView = WHERE("Delete After Synchronization" = CONST(false));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the integration table mapping entry.';
                }
                field(TableCaptionValue; TableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table';
                    Editable = false;
                    ToolTip = 'Specifies the name of the business data table in Business Central to map to the integration table.';
                }
                field(TableFilterValue; TableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies a filter on the business data table in Dynamics 365 to control which records can be synchronized with the corresponding records in the integration table that is specified by the Integration Table ID field.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(TableCaptionValue, "Table ID");
                        if TableFilter <> '' then
                            FilterPageBuilder.SetView(TableCaptionValue, TableFilter);
                        if FilterPageBuilder.RunModal then begin
                            TableFilter := FilterPageBuilder.GetView(TableCaptionValue, false);
                            SetTableFilter(TableFilter);
                        end;
                    end;
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the synchronization direction.';
                }
                field(IntegrationTableCaptionValue; IntegrationTableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table';
                    Enabled = false;
                    ToolTip = 'Specifies the ID of the integration table to map to the business table.';
                }
                field(IntegrationFieldCaption; IntegrationFieldCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the field in the integration table to map to the business table.';

                    trigger OnDrillDown()
                    var
                        CRMOptionMapping: Record "CRM Option Mapping";
                        "Field": Record "Field";
                    begin
                        if "Int. Table UID Field Type" = Field.Type::Option then begin
                            CRMOptionMapping.FilterGroup(2);
                            CRMOptionMapping.SetRange("Table ID", "Table ID");
                            CRMOptionMapping.FilterGroup(0);
                            PAGE.RunModal(PAGE::"CRM Option Mapping", CRMOptionMapping);
                        end;
                    end;
                }
                field(IntegrationFieldType; IntegrationFieldTypeValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field Type';
                    Editable = false;
                    ToolTip = 'Specifies the type of the field in the integration table to map to the business table.';
                }
                field(IntegrationTableFilter; IntegrationTableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table Filter';
                    ToolTip = 'Specifies a filter on the integration table to control which records can be synchronized with the corresponding records in the business data table that is specified by the Table field.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        Codeunit.Run(Codeunit::"CRM Integration Management");
                        FilterPageBuilder.AddTable(IntegrationTableCaptionValue, "Integration Table ID");
                        if IntegrationTableFilter <> '' then
                            FilterPageBuilder.SetView(IntegrationTableCaptionValue, IntegrationTableFilter);
                        Commit();
                        if FilterPageBuilder.RunModal then begin
                            IntegrationTableFilter := FilterPageBuilder.GetView(IntegrationTableCaptionValue, false);
                            SetIntegrationTableFilter(IntegrationTableFilter);
                        end;
                    end;
                }
                field("Table Config Template Code"; "Table Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use when creating new records in the Dynamics 365 business table (specified by the Table ID field) during synchronization.';
                }
                field("Int. Tbl. Config Template Code"; "Int. Tbl. Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use for creating new records in the external database table, such as Dynamics 365 Sales.';
                }
                field("Synch. Only Coupled Records"; "Synch. Only Coupled Records")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how to handle uncoupled records in Dynamics 365 Sales entities and Dynamics 365 tables when synchronization is performed by an integration synchronization job.';
                }
                field("Int. Tbl. Caption Prefix"; "Int. Tbl. Caption Prefix")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies text that appears before the caption of the integration table wherever the caption is used.';
                    Visible = false;
                }
                field("Synch. Modified On Filter"; "Synch. Modified On Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date/time filter to delimit which modified records are synchronized by their modification date. The filter is based on the Modified On field on the involved integration table records.';
                }
                field("Deletion-Conflict Resolution"; "Deletion-Conflict Resolution")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the action to take when a coupled record is deleted in one of the connected applications.';
                }
                field("Update-Conflict Resolution"; "Update-Conflict Resolution")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the action to take when a coupled record is updated in both of the connected applications.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(FieldMapping)
            {
                ApplicationArea = Suite;
                Caption = 'Fields';
                Enabled = HasRecords;
                Image = Relationship;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Integration Field Mapping List";
                RunPageLink = "Integration Table Mapping Name" = FIELD(Name);
                RunPageMode = View;
                ToolTip = 'View fields in Dynamics 365 Sales integration tables that are mapped to fields in Business Central.';
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with Dataverse. All current mappings are deleted.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    CRMIntegrationMgt: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);

                    if IntegrationTableMapping.IsEmpty() then
                        Error(NoRecSelectedErr);

                    CRMIntegrationMgt.ResetIntTableMappingDefaultConfiguration(IntegrationTableMapping);
                    CurrPage.Update();
                end;
            }
            action("View Integration Synch. Job Log")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Synch. Job Log';
                Enabled = HasRecords;
                Image = Log;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'View the status of the individual synchronization jobs that have been run for the Dynamics 365 Sales integration. This includes synchronization jobs that have been run from the job queue and manual synchronization jobs that were performed on records from the Business Central client.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    ShowSynchronizationLog(IntegrationTableMapping);
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = HasRecords AND ("Parent Name" = '');
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if IsEmpty then
                        exit;

                    SynchronizeNow(false);
                    Message(SynchronizeModifiedScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action(SynchronizeAll)
            {
                ApplicationArea = Suite;
                Caption = 'Run Full Synchronization';
                Enabled = HasRecords AND ("Parent Name" = '');
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Dynamics 365 Sales entities, as defined in the Integration Table Mappings window.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if IsEmpty then
                        exit;

                    if not Confirm(StartFullSynchronizationQst) then
                        exit;
                    SynchronizeNow(true);
                    Message(FullSynchronizationScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action(UnconditionalSynchronizeAll)
            {
                ApplicationArea = Suite;
                Caption = 'Run Unconditional Full Synchronization';
                Enabled = HasRecords AND ("Parent Name" = '') AND (Direction <> Direction::Bidirectional);
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Start the default integration job for synchronizing this Business Central record type and Dynamics 365 Sales entity, unconditionally for all records.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if IsEmpty then
                        exit;

                    if not Confirm(StartUnconditionalFullSynchronizationQst) then
                        exit;
                    SynchronizeNow(true, true);
                    Message(FullSynchronizationScheduledMsg, IntegrationSynchJobList.Caption);
                end;
            }
            action("View Integration Uncouple Job Log")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Uncouple Job Log';
                Enabled = HasRecords;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = Log;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ToolTip = 'View the status of jobs for uncoupling records in a Dynamics 365 Sales integration. The jobs were run either from the job queue, or manually, in Business Central.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    ShowUncouplingLog(IntegrationTableMapping);
                end;
            }
            action(RemoveCoupling)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Couplings';
                Enabled = HasRecords AND ("Parent Name" = '');
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = UnLinkAccount;
                Promoted = true;
                PromotedCategory = Category6;
                ToolTip = 'Delete couplings between the selected Business Central record types and Dynamics 365 Sales entities.';

                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    FilteredIntegrationTableMapping: Record "Integration Table Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                    ForegroundCount: Integer;
                    JobCount: Integer;
                    ConfirmMsg: Text;
                    ResultMsg: Text;
                begin
                    CurrPage.SetSelectionFilter(IntegrationTableMapping);
                    if not IntegrationTableMapping.FindSet() then
                        exit;

                    CurrPage.SetSelectionFilter(FilteredIntegrationTableMapping);
                    FilteredIntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
                    if not FilteredIntegrationTableMapping.IsEmpty() then begin
                        ConfirmMsg := StartUncouplingQst;
                        ResultMsg := RemoveCouplingsScheduledMsg;
                    end else begin
                        ConfirmMsg := StartUncouplingForegroundQst;
                        ResultMsg := UncouplingCompletedMsg;
                    end;
                    if not Confirm(ConfirmMsg) then
                        exit;

                    repeat
                        CRMIntegrationManagement.RemoveCoupling(IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID");
                        if IntegrationTableMapping."Uncouple Codeunit ID" = Codeunit::"CDS Int. Table Uncouple" then
                            JobCount += 1
                        else
                            ForegroundCount += 1;
                    until IntegrationTableMapping.Next() = 0;

                    if ForegroundCount > 0 then
                        Message(ResultMsg, IntegrationSynchJobList.Caption, JobCount, StrSubstNo(RemoveCouplingsForegroundMsg, ForegroundCount))
                    else
                        Message(ResultMsg, IntegrationSynchJobList.Caption, JobCount, '');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IntegrationTableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Integration Table ID");
        TableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
        IntegrationFieldCaptionValue := GetFieldCaption;
        IntegrationFieldTypeValue := GetFieldType;

        TableFilter := GetTableFilter;
        IntegrationTableFilter := GetIntegrationTableFilter;

        HasRecords := not IsEmpty;
    end;

    trigger OnInit()
    begin
        SetCRMIntegrationEnabledState();
        SetCDSIntegrationEnabledState();
    end;

    var
        ObjectTranslation: Record "Object Translation";
        TypeHelper: Codeunit "Type Helper";
        TableCaptionValue: Text[250];
        IntegrationFieldCaptionValue: Text;
        IntegrationFieldTypeValue: Text;
        IntegrationTableCaptionValue: Text[250];
        TableFilter: Text;
        IntegrationTableFilter: Text;
        StartFullSynchronizationQst: Label 'You are about to synchronize all data within the mapping.\The synchronization will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartUnconditionalFullSynchronizationQst: Label 'You are about to synchronize all data within the mapping, regardless of whether they were modified since last synchronization or not.\The synchronization will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartUncouplingQst: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\The uncoupling will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        StartUncouplingForegroundQst: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\\Do you want to continue?';
        UncouplingCompletedMsg: Label 'Uncoupling completed.';
        SynchronizeModifiedScheduledMsg: Label 'Synchronization is scheduled for Modified Records.\Details are available on the %1 page.', Comment = '%1 caption from page Integration Synch. Job List';
        FullSynchronizationScheduledMsg: Label 'Full Synchronization is scheduled.\Details are available on the %1 page.', Comment = '%1 caption from page Integration Synch. Job List';
        RemoveCouplingsScheduledMsg: Label 'Uncoupling is scheduled for %2 mappings. %3\Details are available on the %1 page.', Comment = '%1 - caption from page 5344, %2 - scheduled job count, %3 - additional foreground job message';
        RemoveCouplingsForegroundMsg: Label '%1 mappings are uncoupled.', Comment = '%1 - foreground uncoupling count';
        NoRecSelectedErr: Label 'You must choose at least one integration table mapping.';
        HasRecords: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;

    local procedure GetFieldCaption(): Text
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField("Integration Table ID", "Integration Table UID Fld. No.", Field) then
            exit(Field."Field Caption");
    end;

    local procedure GetFieldType(): Text
    var
        "Field": Record "Field";
    begin
        Field.Type := "Int. Table UID Field Type";
        exit(Format(Field.Type))
    end;

    local procedure SetCRMIntegrationEnabledState()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    local procedure SetCDSIntegrationEnabledState()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;
}

