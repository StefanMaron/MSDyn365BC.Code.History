table 480 "Dimension Set Entry"
{
    Caption = 'Dimension Set Entry';
    DrillDownPageID = "Dimension Set Entries";
    LookupPageID = "Dimension Set Entries";
    Permissions = TableData "Dimension Set Entry" = ri,
                  TableData "Dimension Set Tree Node" = rim;

    fields
    {
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr);
                if "Dimension Code" <> xRec."Dimension Code" then begin
                    "Dimension Value Code" := '';
                    "Dimension Value ID" := 0;
                end;
            end;
        }
        field(3; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr);

                DimVal.Get("Dimension Code", "Dimension Value Code");
                "Dimension Value ID" := DimVal."Dimension Value ID";
            end;
        }
        field(4; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
        }
        field(5; "Dimension Name"; Text[30])
        {
            CalcFormula = Lookup (Dimension.Name WHERE(Code = FIELD("Dimension Code")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = Lookup ("Dimension Value".Name WHERE("Dimension Code" = FIELD("Dimension Code"),
                                                               Code = FIELD("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Dimension Set ID", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Value ID")
        {
        }
        key(Key3; "Dimension Code", "Dimension Value Code", "Dimension Set ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;
    end;

    trigger OnModify()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;
    end;

    var
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;

    procedure GetDimensionSetID(var DimSetEntry: Record "Dimension Set Entry"): Integer
    var
        DimSetEntry2: Record "Dimension Set Entry";
        DimSetTreeNode: Record "Dimension Set Tree Node";
        Found: Boolean;
    begin
        OnBeforeGetDimensionSetID(DimSetEntry);

        DimSetEntry2.Copy(DimSetEntry);
        if DimSetEntry."Dimension Set ID" > 0 then
            DimSetEntry.SetRange("Dimension Set ID", DimSetEntry."Dimension Set ID");

        DimSetEntry.SetCurrentKey("Dimension Value ID");
        DimSetEntry.SetFilter("Dimension Code", '<>%1', '');
        DimSetEntry.SetFilter("Dimension Value Code", '<>%1', '');

        if not DimSetEntry.FindSet then
            exit(0);

        Found := true;
        DimSetTreeNode."Dimension Set ID" := 0;
        repeat
            DimSetEntry.TestField("Dimension Value ID");
            if Found then
                if not DimSetTreeNode.Get(DimSetTreeNode."Dimension Set ID", DimSetEntry."Dimension Value ID") then begin
                    Found := false;
                    DimSetTreeNode.LockTable();
                end;
            OnGetDimensionSetIDOnBeforeInsertTreeNode(DimSetEntry, Found);
            if not Found then begin
                DimSetTreeNode."Parent Dimension Set ID" := DimSetTreeNode."Dimension Set ID";
                DimSetTreeNode."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                DimSetTreeNode."Dimension Set ID" := 0;
                DimSetTreeNode."In Use" := false;
                if not DimSetTreeNode.Insert(true) then
                    DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
        until DimSetEntry.Next = 0;
        if not DimSetTreeNode."In Use" then begin
            if Found then begin
                DimSetTreeNode.LockTable();
                DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
            DimSetTreeNode."In Use" := true;
            DimSetTreeNode.Modify();
            InsertDimSetEntries(DimSetEntry, DimSetTreeNode."Dimension Set ID");
        end;

        DimSetEntry.Copy(DimSetEntry2);

        exit(DimSetTreeNode."Dimension Set ID");
    end;

    local procedure InsertDimSetEntries(var DimSetEntry: Record "Dimension Set Entry"; NewID: Integer)
    var
        DimSetEntry2: Record "Dimension Set Entry";
    begin
        DimSetEntry2.LockTable();
        if DimSetEntry.FindSet then
            repeat
                DimSetEntry2 := DimSetEntry;
                DimSetEntry2."Dimension Set ID" := NewID;
                DimSetEntry2.Insert();
            until DimSetEntry.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimensionSetID(var DimensionSetEntry: Record "Dimension Set Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimensionSetIDOnBeforeInsertTreeNode(var DimensionSetEntry: Record "Dimension Set Entry"; var Found: Boolean)
    begin
    end;
}

