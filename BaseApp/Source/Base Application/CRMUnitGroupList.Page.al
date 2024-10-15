page 5362 "CRM UnitGroup List"
{
    ApplicationArea = Suite;
    Caption = 'Unit Groups - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Uomschedule";
    SourceTableView = SORTING(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(BaseUoMName; BaseUoMName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Base Unit Name';
                    ToolTip = 'Specifies the base unit of measure of the Dynamics 365 Sales record.';
                }
                field(StateCode; StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StatusCode; StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Unit Groups';
                Image = FilterLines;
                ToolTip = 'Do not show coupled unit groups.';

                trigger OnAction()
                begin
                    MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Unit Groups';
                Image = ClearFilter;
                ToolTip = 'Show coupled unit groups.';

                trigger OnAction()
                begin
                    MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecordID: RecordID;
        MappedTableId: Integer;
    begin
        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            MappedTableId := Database::"Unit Group"
        else
            MappedTableId := Database::"Unit of Measure";

        if CRMIntegrationRecord.FindRecordIDFromID(UoMScheduleId, MappedTableId, RecordID) then
            if CurrentlyCoupledCRMUomschedule.UoMScheduleId = UoMScheduleId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Uomschedule"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMUomschedule: Record "CRM Uomschedule";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMUomschedule(CRMUomschedule: Record "CRM Uomschedule")
    begin
        CurrentlyCoupledCRMUomschedule := CRMUomschedule;
    end;
}

