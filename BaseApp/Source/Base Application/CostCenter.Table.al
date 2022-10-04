table 1112 "Cost Center"
{
    Caption = 'Cost Center';
    LookupPageID = "Chart of Cost Centers";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnLookup()
            var
                CostAccMgt: Codeunit "Cost Account Mgt";
            begin
                CostAccMgt.LookupCostCenterFromDimValue(Code);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Cost Subtype"; Option)
        {
            Caption = 'Cost Subtype';
            OptionCaption = ' ,Service Cost Center,Aux. Cost Center,Main Cost Center';
            OptionMembers = " ","Service Cost Center","Aux. Cost Center","Main Cost Center";
        }
        field(4; "Cost Type Filter"; Code[20])
        {
            Caption = 'Cost Type Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Type";
        }
        field(5; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Net Change"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Cost Entry".Amount WHERE("Cost Center Code" = FIELD(Code),
                                                         "Cost Center Code" = FIELD(FILTER(Totaling)),
                                                         "Cost Type No." = FIELD("Cost Type Filter"),
                                                         "Posting Date" = FIELD("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Balance at Date"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Cost Entry".Amount WHERE("Cost Center Code" = FIELD(Code),
                                                         "Cost Center Code" = FIELD(FILTER(Totaling)),
                                                         "Cost Type No." = FIELD("Cost Type Filter"),
                                                         "Posting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Balance to Allocate"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Cost Entry".Amount WHERE("Cost Center Code" = FIELD(Code),
                                                         "Cost Center Code" = FIELD(FILTER(Totaling)),
                                                         "Cost Type No." = FIELD("Cost Type Filter"),
                                                         "Posting Date" = FIELD("Date Filter"),
                                                         Allocated = CONST(false)));
            Caption = 'Balance to Allocate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Responsible Person"; Code[50])
        {
            Caption = 'Responsible Person';
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Responsible Person");
            end;
        }
        field(10; "Sorting Order"; Code[10])
        {
            Caption = 'Sorting Order';
        }
        field(11; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(12; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Cost Center,Heading,Total,Begin-Total,End-Total';
            OptionMembers = "Cost Center",Heading,Total,"Begin-Total","End-Total";

            trigger OnValidate()
            begin
                // Change to other type than cost type. Entries exist?
                if (("Line Type" <> "Line Type"::"Cost Center") and
                    (xRec."Line Type" = xRec."Line Type"::"Cost Center")) or
                   (("Line Type" <> "Line Type"::"Begin-Total") and
                    (xRec."Line Type" = xRec."Line Type"::"Begin-Total"))
                then
                    ConfirmModifyIfEntriesExist(Rec);

                if "Line Type" <> "Line Type"::"Cost Center" then begin
                    Blocked := true;
                    "Cost Subtype" := 0;
                end else
                    Totaling := '';
            end;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(15; "Blank Line"; Boolean)
        {
            Caption = 'Blank Line';
            MinValue = false;
        }
        field(16; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            MinValue = 0;
        }
        field(17; Totaling; Text[250])
        {
            Caption = 'Totaling';

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupCostCenterFilter(SelectionFilter) then
                    Validate(Totaling, CopyStr(SelectionFilter, 1, MaxStrLen(Totaling)));
            end;

            trigger OnValidate()
            begin
                if not ("Line Type" in ["Line Type"::Total, "Line Type"::"End-Total"]) then
                    FieldError("Line Type");

                CalcFields("Net Change");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Cost Subtype")
        {
        }
        key(Key3; "Sorting Order")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        SetRecFilter();
        ConfirmDeleteIfEntriesExist(Rec, true);
        SetRange(Code);
        SetCurrentKey("Sorting Order");
    end;

    trigger OnInsert()
    begin
        TestField(Code);
    end;

    var
        Text001: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost center. Are you sure that you want to delete the cost center?';
        Text002: Label 'There are general ledger entries, cost entries, or cost budget entries that are posted to the selected cost center. Are you sure that you want to modify the cost center?';

    local procedure EntriesExist(var CostCenter: Record "Cost Center") EntriesFound: Boolean
    var
        CostAccSetup: Record "Cost Accounting Setup";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimFilter: Text;
    begin
        CostAccSetup.Get();
        if CostCenter.FindSet() then
            repeat
                DimensionMgt.GetDimSetIDsForFilter(CostAccSetup."Cost Center Dimension", CostCenter.Code);
                DimFilter := DimensionMgt.GetDimSetFilter();
                if DimFilter <> '' then begin
                    GLEntry.SetFilter("Dimension Set ID", DimFilter);
                    if GLEntry.FindFirst() then
                        EntriesFound := true;
                end;

                if not EntriesFound then begin
                    CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Center Code");
                    CostBudgetEntry.SetRange("Cost Center Code", CostCenter.Code);
                    EntriesFound := not CostBudgetEntry.IsEmpty();
                end;

                if not EntriesFound then begin
                    CostEntry.SetCurrentKey("Cost Center Code");
                    CostEntry.SetRange("Cost Center Code", CostCenter.Code);
                    EntriesFound := not CostEntry.IsEmpty();
                end;
            until (CostCenter.Next() = 0) or EntriesFound;
    end;

    procedure ConfirmDeleteIfEntriesExist(var CostCenter: Record "Cost Center"; CalledFromOnInsert: Boolean)
    begin
        if EntriesExist(CostCenter) then
            if not Confirm(Text001, true) then
                Error('');
        if not CalledFromOnInsert then
            CostCenter.DeleteAll();
    end;

    local procedure ConfirmModifyIfEntriesExist(var CostCenter: Record "Cost Center")
    var
        CostCenter2: Record "Cost Center";
    begin
        CostCenter2 := CostCenter;
        CostCenter2.SetRecFilter();
        if EntriesExist(CostCenter2) then
            if not Confirm(Text002, true) then
                Error('');
    end;

    procedure LookupCostCenterFilter(var Text: Text): Boolean
    var
        ChartOfCostCenters: Page "Chart of Cost Centers";
    begin
        ChartOfCostCenters.LookupMode(true);
        if ChartOfCostCenters.RunModal() = ACTION::LookupOK then begin
            Text := ChartOfCostCenters.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;
}

