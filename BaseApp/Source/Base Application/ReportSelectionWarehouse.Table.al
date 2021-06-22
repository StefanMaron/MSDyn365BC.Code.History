table 7355 "Report Selection Warehouse"
{
    Caption = 'Report Selection Warehouse';

    fields
    {
        field(1; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Put-away,Pick,Movement,Invt. Put-away,Invt. Pick,Invt. Movement,Receipt,Shipment,Posted Receipt,Posted Shipment';
            OptionMembers = "Put-away",Pick,Movement,"Invt. Put-away","Invt. Pick","Invt. Movement",Receipt,Shipment,"Posted Receipt","Posted Shipment";
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure NewRecord()
    var
        ReportSelectionWhse2: Record "Report Selection Warehouse";
    begin
        ReportSelectionWhse2.SetRange(Usage, Usage);
        if ReportSelectionWhse2.FindLast and (ReportSelectionWhse2.Sequence <> '') then
            Sequence := IncStr(ReportSelectionWhse2.Sequence)
        else
            Sequence := '1';
    end;

    procedure PrintWhseActivHeader(var WhseActivHeader: Record "Warehouse Activity Header"; ReportUsage: Integer; HideDialog: Boolean)
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        SetRange(Usage, ReportUsage);
        if IsEmpty then
            ReportSelectionMgt.InitReportUsageWhse(ReportUsage);
        if FindSet then
            repeat
                REPORT.Run("Report ID", not HideDialog, false, WhseActivHeader);
            until Next = 0;
    end;

    procedure PrintWhseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; HideDialog: Boolean)
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        SetRange(Usage, Usage::Receipt);
        if IsEmpty then
            ReportSelectionMgt.InitReportUsageWhse(Usage);
        if FindSet then
            repeat
                REPORT.Run("Report ID", not HideDialog, false, WarehouseReceiptHeader);
            until Next = 0;
    end;

    procedure PrintPostedWhseReceiptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; HideDialog: Boolean)
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        SetRange(Usage, Usage::"Posted Receipt");
        if IsEmpty then
            ReportSelectionMgt.InitReportUsageWhse(Usage);
        if FindSet then
            repeat
                REPORT.Run("Report ID", not HideDialog, false, PostedWhseReceiptHeader);
            until Next = 0;
    end;

    procedure PrintWhseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideDialog: Boolean)
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        SetRange(Usage, Usage::Shipment);
        if IsEmpty then
            ReportSelectionMgt.InitReportUsageWhse(Usage);
        if FindSet then
            repeat
                REPORT.Run("Report ID", not HideDialog, false, WarehouseShipmentHeader);
            until Next = 0;
    end;

    procedure PrintPostedWhseShipmentHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; HideDialog: Boolean)
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        SetRange(Usage, Usage::"Posted Shipment");
        if IsEmpty then
            ReportSelectionMgt.InitReportUsageWhse(Usage);
        if FindSet then
            repeat
                REPORT.Run("Report ID", not HideDialog, false, PostedWhseShipmentHeader);
            until Next = 0;
    end;
}

