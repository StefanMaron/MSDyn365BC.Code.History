page 5364 "CRM Unit List"
{
    ApplicationArea = Suite;
    Caption = 'Units - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Uom";
    SourceTableView = SORTING(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
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
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity of the record.';
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

        if CRMIntegrationRecord.FindRecordIDFromID(UoMId, Database::"Item Unit of Measure", RecordID) then
            if CurrentlyCoupledCRMUom.UoMId = UoMScheduleId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Mark(false);
            end
        else
            if CRMIntegrationRecord.FindRecordIDFromID(UoMId, Database::"Resource Unit of Measure", RecordID) then
                if CurrentlyCoupledCRMUom.UoMId = UoMScheduleId then begin
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
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"CRM Uom"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMUom: Record "CRM Uom";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMUnit(CRMUom: Record "CRM Uom")
    begin
        CurrentlyCoupledCRMUom := CRMUom;
    end;
}

