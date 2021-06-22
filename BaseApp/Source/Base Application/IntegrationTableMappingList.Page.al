page 5335 "Integration Table Mapping List"
{
    ApplicationArea = Suite;
    Caption = 'Integration Table Mappings';
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Synchronization,Mapping';
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
                        FilterPageBuilder.AddTable(IntegrationTableCaptionValue, "Integration Table ID");
                        if IntegrationTableFilter <> '' then
                            FilterPageBuilder.SetView(IntegrationTableCaptionValue, IntegrationTableFilter);
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
                begin
                    ShowLog('');
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
                    Message(SynchronizedModifiedCompletedMsg, IntegrationSynchJobList.Caption);
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
                    Message(FullSynchronizationCompletedMsg, IntegrationSynchJobList.Caption);
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

    trigger OnOpenPage()
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
        StartFullSynchronizationQst: Label 'You are about synchronize all data within the mapping. This process may take several minutes.\\Do you want to continue?';
        SynchronizedModifiedCompletedMsg: Label 'Synchronized Modified Records completed.\See the %1 window for details.', Comment = '%1 caption from page 5338';
        FullSynchronizationCompletedMsg: Label 'Full Synchronization completed.\See the %1 window for details.', Comment = '%1 caption from page 5338';
        HasRecords: Boolean;

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
        CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    local procedure SetCDSIntegrationEnabledState()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;
}

