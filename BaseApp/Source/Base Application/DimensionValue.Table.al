table 349 "Dimension Value"
{
    Caption = 'Dimension Value';
    LookupPageID = "Dimension Value List";

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateMapToICDimensionCode;
            end;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                if UpperCase(Code) = Text002 then
                    Error(Text003,
                      FieldCaption(Code));
            end;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Dimension Value Type"; Option)
        {
            Caption = 'Dimension Value Type';
            OptionCaption = 'Standard,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Standard,Heading,Total,"Begin-Total","End-Total";

            trigger OnValidate()
            begin
                if ("Dimension Value Type" <> "Dimension Value Type"::Standard) and
                   (xRec."Dimension Value Type" = xRec."Dimension Value Type"::Standard)
                then
                    if CheckIfDimValueUsed then
                        Error(Text004, GetCheckDimErr);
                Totaling := '';
            end;
        }
        field(5; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = IF ("Dimension Value Type" = CONST(Total)) "Dimension Value"."Dimension Code" WHERE("Dimension Code" = FIELD("Dimension Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if not ("Dimension Value Type" in
                        ["Dimension Value Type"::Total, "Dimension Value Type"::"End-Total"]) and (Totaling <> '')
                then
                    FieldError("Dimension Value Type");
            end;
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; "Consolidation Code"; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consolidation Code';
        }
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(9; "Global Dimension No."; Integer)
        {
            Caption = 'Global Dimension No.';
        }
        field(10; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';

            trigger OnValidate()
            begin
                if "Map-to IC Dimension Code" <> xRec."Map-to IC Dimension Code" then
                    Validate("Map-to IC Dimension Value Code", '');
            end;
        }
        field(11; "Map-to IC Dimension Value Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Value Code';
            TableRelation = "IC Dimension Value".Code WHERE("Dimension Code" = FIELD("Map-to IC Dimension Code"));
        }
        field(12; "Dimension Value ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Dimension Value ID';
            Editable = false;

            trigger OnValidate()
            begin
                Error(Text006, FieldCaption("Dimension Value ID"));
            end;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(8001; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
        }
    }

    keys
    {
        key(Key1; "Dimension Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Code", "Global Dimension No.")
        {
        }
        key(Key3; Name)
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
        if CheckIfDimValueUsed then
            Error(Text000, GetCheckDimErr);

        DimValueComb.SetRange("Dimension 1 Code", "Dimension Code");
        DimValueComb.SetRange("Dimension 1 Value Code", Code);
        DimValueComb.DeleteAll(true);

        DimValueComb.Reset();
        DimValueComb.SetRange("Dimension 2 Code", "Dimension Code");
        DimValueComb.SetRange("Dimension 2 Value Code", Code);
        DimValueComb.DeleteAll(true);

        DefaultDim.SetRange("Dimension Code", "Dimension Code");
        DefaultDim.SetRange("Dimension Value Code", Code);
        DefaultDim.DeleteAll(true);

        SelectedDim.SetRange("Dimension Code", "Dimension Code");
        SelectedDim.SetRange("New Dimension Value Code", Code);
        SelectedDim.DeleteAll(true);

        AnalysisSelectedDim.SetRange("Dimension Code", "Dimension Code");
        AnalysisSelectedDim.SetRange("New Dimension Value Code", Code);
        AnalysisSelectedDim.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestField("Dimension Code");
        TestField(Code);
        "Global Dimension No." := GetGlobalDimensionNo;

        if CostAccSetup.Get then begin
            CostAccMgt.UpdateCostCenterFromDim(Rec, Rec, 0);
            CostAccMgt.UpdateCostObjectFromDim(Rec, Rec, 0);
        end;

        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        if "Dimension Code" <> xRec."Dimension Code" then
            "Global Dimension No." := GetGlobalDimensionNo;
        if CostAccSetup.Get then begin
            CostAccMgt.UpdateCostCenterFromDim(Rec, xRec, 1);
            CostAccMgt.UpdateCostObjectFromDim(Rec, xRec, 1);
        end;

        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    begin
        RenameBudgEntryDim;
        RenameAnalysisViewEntryDim;
        RenameItemBudgEntryDim;
        RenameItemAnalysisViewEntryDim;

        if CostAccSetup.Get then begin
            CostAccMgt.UpdateCostCenterFromDim(Rec, xRec, 3);
            CostAccMgt.UpdateCostObjectFromDim(Rec, xRec, 3);
        end;

        SetLastModifiedDateTime;
    end;

    var
        Text000: Label '%1\You cannot delete it.';
        Text002: Label '(CONFLICT)';
        Text003: Label '%1 can not be (CONFLICT). This name is used internally by the system.';
        Text004: Label '%1\You cannot change the type.';
        Text005: Label 'This dimension value has been used in posted or budget entries.';
        DimSetEntry: Record "Dimension Set Entry";
        DimValueComb: Record "Dimension Value Combination";
        DefaultDim: Record "Default Dimension";
        SelectedDim: Record "Selected Dimension";
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccMgt: Codeunit "Cost Account Mgt";
        Text006: Label 'You cannot change the value of %1.';

    procedure CheckIfDimValueUsed(): Boolean
    begin
        DimSetEntry.SetCurrentKey("Dimension Value ID");
        DimSetEntry.SetRange("Dimension Value ID", "Dimension Value ID");
        exit(not DimSetEntry.IsEmpty);
    end;

    local procedure GetCheckDimErr(): Text[250]
    begin
        exit(Text005);
    end;

    local procedure RenameBudgEntryDim()
    var
        GLBudget: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetEntry2: Record "G/L Budget Entry";
        BudgDimNo: Integer;
    begin
        GLBudget.LockTable();
        if GLBudget.Find('-') then
            repeat
            until GLBudget.Next = 0;
        for BudgDimNo := 1 to 4 do begin
            case true of
                BudgDimNo = 1:
                    GLBudget.SetRange("Budget Dimension 1 Code", "Dimension Code");
                BudgDimNo = 2:
                    GLBudget.SetRange("Budget Dimension 2 Code", "Dimension Code");
                BudgDimNo = 3:
                    GLBudget.SetRange("Budget Dimension 3 Code", "Dimension Code");
                BudgDimNo = 4:
                    GLBudget.SetRange("Budget Dimension 4 Code", "Dimension Code");
            end;
            if GLBudget.Find('-') then begin
                GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code");
                repeat
                    GLBudgetEntry.SetRange("Budget Name", GLBudget.Name);
                    case true of
                        BudgDimNo = 1:
                            GLBudgetEntry.SetRange("Budget Dimension 1 Code", xRec.Code);
                        BudgDimNo = 2:
                            GLBudgetEntry.SetRange("Budget Dimension 2 Code", xRec.Code);
                        BudgDimNo = 3:
                            GLBudgetEntry.SetRange("Budget Dimension 3 Code", xRec.Code);
                        BudgDimNo = 4:
                            GLBudgetEntry.SetRange("Budget Dimension 4 Code", xRec.Code);
                    end;
                    if GLBudgetEntry.Find('-') then
                        repeat
                            GLBudgetEntry2 := GLBudgetEntry;
                            case true of
                                BudgDimNo = 1:
                                    GLBudgetEntry2."Budget Dimension 1 Code" := Code;
                                BudgDimNo = 2:
                                    GLBudgetEntry2."Budget Dimension 2 Code" := Code;
                                BudgDimNo = 3:
                                    GLBudgetEntry2."Budget Dimension 3 Code" := Code;
                                BudgDimNo = 4:
                                    GLBudgetEntry2."Budget Dimension 4 Code" := Code;
                            end;
                            GLBudgetEntry2.Modify();
                        until GLBudgetEntry.Next = 0;
                    GLBudgetEntry.Reset();
                until GLBudget.Next = 0;
            end;
            GLBudget.Reset();
        end;
    end;

    local procedure RenameAnalysisViewEntryDim()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewEntry2: Record "Analysis View Entry";
        AnalysisViewBudgEntry: Record "Analysis View Budget Entry";
        AnalysisViewBudgEntry2: Record "Analysis View Budget Entry";
        DimensionNo: Integer;
    begin
        AnalysisView.LockTable();
        if AnalysisView.Find('-') then
            repeat
            until AnalysisView.Next = 0;

        for DimensionNo := 1 to 4 do begin
            case true of
                DimensionNo = 1:
                    AnalysisView.SetRange("Dimension 1 Code", "Dimension Code");
                DimensionNo = 2:
                    AnalysisView.SetRange("Dimension 2 Code", "Dimension Code");
                DimensionNo = 3:
                    AnalysisView.SetRange("Dimension 3 Code", "Dimension Code");
                DimensionNo = 4:
                    AnalysisView.SetRange("Dimension 4 Code", "Dimension Code");
            end;
            if AnalysisView.Find('-') then
                repeat
                    AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewBudgEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    case true of
                        DimensionNo = 1:
                            begin
                                AnalysisViewEntry.SetRange("Dimension 1 Value Code", xRec.Code);
                                AnalysisViewBudgEntry.SetRange("Dimension 1 Value Code", xRec.Code);
                            end;
                        DimensionNo = 2:
                            begin
                                AnalysisViewEntry.SetRange("Dimension 2 Value Code", xRec.Code);
                                AnalysisViewBudgEntry.SetRange("Dimension 2 Value Code", xRec.Code);
                            end;
                        DimensionNo = 3:
                            begin
                                AnalysisViewEntry.SetRange("Dimension 3 Value Code", xRec.Code);
                                AnalysisViewBudgEntry.SetRange("Dimension 3 Value Code", xRec.Code);
                            end;
                        DimensionNo = 4:
                            begin
                                AnalysisViewEntry.SetRange("Dimension 4 Value Code", xRec.Code);
                                AnalysisViewBudgEntry.SetRange("Dimension 4 Value Code", xRec.Code);
                            end;
                    end;
                    if AnalysisViewEntry.Find('-') then
                        repeat
                            AnalysisViewEntry2 := AnalysisViewEntry;
                            case true of
                                DimensionNo = 1:
                                    AnalysisViewEntry2."Dimension 1 Value Code" := Code;
                                DimensionNo = 2:
                                    AnalysisViewEntry2."Dimension 2 Value Code" := Code;
                                DimensionNo = 3:
                                    AnalysisViewEntry2."Dimension 3 Value Code" := Code;
                                DimensionNo = 4:
                                    AnalysisViewEntry2."Dimension 4 Value Code" := Code;
                            end;
                            AnalysisViewEntry.Delete();
                            AnalysisViewEntry2.Insert();
                        until AnalysisViewEntry.Next = 0;
                    AnalysisViewEntry.Reset();
                    if AnalysisViewBudgEntry.Find('-') then
                        repeat
                            AnalysisViewBudgEntry2 := AnalysisViewBudgEntry;
                            case true of
                                DimensionNo = 1:
                                    AnalysisViewBudgEntry2."Dimension 1 Value Code" := Code;
                                DimensionNo = 2:
                                    AnalysisViewBudgEntry2."Dimension 2 Value Code" := Code;
                                DimensionNo = 3:
                                    AnalysisViewBudgEntry2."Dimension 3 Value Code" := Code;
                                DimensionNo = 4:
                                    AnalysisViewBudgEntry2."Dimension 4 Value Code" := Code;
                            end;
                            AnalysisViewBudgEntry.Delete();
                            AnalysisViewBudgEntry2.Insert();
                        until AnalysisViewBudgEntry.Next = 0;
                    AnalysisViewBudgEntry.Reset();
                until AnalysisView.Next = 0;
            AnalysisView.Reset();
        end;
    end;

    local procedure RenameItemBudgEntryDim()
    var
        ItemBudget: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemBudgetEntry2: Record "Item Budget Entry";
        BudgDimNo: Integer;
    begin
        ItemBudget.LockTable();
        if ItemBudget.Find('-') then
            repeat
            until ItemBudget.Next = 0;

        for BudgDimNo := 1 to 3 do begin
            case true of
                BudgDimNo = 1:
                    ItemBudget.SetRange("Budget Dimension 1 Code", "Dimension Code");
                BudgDimNo = 2:
                    ItemBudget.SetRange("Budget Dimension 2 Code", "Dimension Code");
                BudgDimNo = 3:
                    ItemBudget.SetRange("Budget Dimension 3 Code", "Dimension Code");
            end;
            if ItemBudget.Find('-') then begin
                ItemBudgetEntry.SetCurrentKey(
                  "Analysis Area", "Budget Name", "Item No.", "Source Type", "Source No.", Date, "Location Code", "Global Dimension 1 Code");
                repeat
                    ItemBudgetEntry.SetRange("Analysis Area", ItemBudget."Analysis Area");
                    ItemBudgetEntry.SetRange("Budget Name", ItemBudget.Name);
                    case true of
                        BudgDimNo = 1:
                            ItemBudgetEntry.SetRange("Budget Dimension 1 Code", xRec.Code);
                        BudgDimNo = 2:
                            ItemBudgetEntry.SetRange("Budget Dimension 2 Code", xRec.Code);
                        BudgDimNo = 3:
                            ItemBudgetEntry.SetRange("Budget Dimension 3 Code", xRec.Code);
                    end;
                    if ItemBudgetEntry.Find('-') then
                        repeat
                            ItemBudgetEntry2 := ItemBudgetEntry;
                            case true of
                                BudgDimNo = 1:
                                    ItemBudgetEntry2."Budget Dimension 1 Code" := Code;
                                BudgDimNo = 2:
                                    ItemBudgetEntry2."Budget Dimension 2 Code" := Code;
                                BudgDimNo = 3:
                                    ItemBudgetEntry2."Budget Dimension 3 Code" := Code;
                            end;
                            ItemBudgetEntry2.Modify();
                        until ItemBudgetEntry.Next = 0;
                    ItemBudgetEntry.Reset();
                until ItemBudget.Next = 0;
            end;
            ItemBudget.Reset();
        end;
    end;

    local procedure RenameItemAnalysisViewEntryDim()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewEntry2: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemAnalysisViewBudgEntry2: Record "Item Analysis View Budg. Entry";
        DimensionNo: Integer;
    begin
        ItemAnalysisView.LockTable();
        if ItemAnalysisView.Find('-') then
            repeat
            until ItemAnalysisView.Next = 0;

        for DimensionNo := 1 to 3 do begin
            case true of
                DimensionNo = 1:
                    ItemAnalysisView.SetRange("Dimension 1 Code", "Dimension Code");
                DimensionNo = 2:
                    ItemAnalysisView.SetRange("Dimension 2 Code", "Dimension Code");
                DimensionNo = 3:
                    ItemAnalysisView.SetRange("Dimension 3 Code", "Dimension Code");
            end;
            if ItemAnalysisView.Find('-') then
                repeat
                    ItemAnalysisViewEntry.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
                    ItemAnalysisViewEntry.SetRange("Analysis View Code", ItemAnalysisView.Code);
                    ItemAnalysisViewBudgEntry.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
                    ItemAnalysisViewBudgEntry.SetRange("Analysis View Code", ItemAnalysisView.Code);
                    case true of
                        DimensionNo = 1:
                            begin
                                ItemAnalysisViewEntry.SetRange("Dimension 1 Value Code", xRec.Code);
                                ItemAnalysisViewBudgEntry.SetRange("Dimension 1 Value Code", xRec.Code);
                            end;
                        DimensionNo = 2:
                            begin
                                ItemAnalysisViewEntry.SetRange("Dimension 2 Value Code", xRec.Code);
                                ItemAnalysisViewBudgEntry.SetRange("Dimension 2 Value Code", xRec.Code);
                            end;
                        DimensionNo = 3:
                            begin
                                ItemAnalysisViewEntry.SetRange("Dimension 3 Value Code", xRec.Code);
                                ItemAnalysisViewBudgEntry.SetRange("Dimension 3 Value Code", xRec.Code);
                            end;
                    end;
                    if ItemAnalysisViewEntry.Find('-') then
                        repeat
                            ItemAnalysisViewEntry2 := ItemAnalysisViewEntry;
                            case true of
                                DimensionNo = 1:
                                    ItemAnalysisViewEntry2."Dimension 1 Value Code" := Code;
                                DimensionNo = 2:
                                    ItemAnalysisViewEntry2."Dimension 2 Value Code" := Code;
                                DimensionNo = 3:
                                    ItemAnalysisViewEntry2."Dimension 3 Value Code" := Code;
                            end;
                            ItemAnalysisViewEntry.Delete();
                            ItemAnalysisViewEntry2.Insert();
                        until ItemAnalysisViewEntry.Next = 0;
                    ItemAnalysisViewEntry.Reset();
                    if ItemAnalysisViewBudgEntry.Find('-') then
                        repeat
                            ItemAnalysisViewBudgEntry2 := ItemAnalysisViewBudgEntry;
                            case true of
                                DimensionNo = 1:
                                    ItemAnalysisViewBudgEntry2."Dimension 1 Value Code" := Code;
                                DimensionNo = 2:
                                    ItemAnalysisViewBudgEntry2."Dimension 2 Value Code" := Code;
                                DimensionNo = 3:
                                    ItemAnalysisViewBudgEntry2."Dimension 3 Value Code" := Code;
                            end;
                            ItemAnalysisViewBudgEntry.Delete();
                            ItemAnalysisViewBudgEntry2.Insert();
                        until ItemAnalysisViewBudgEntry.Next = 0;
                    ItemAnalysisViewBudgEntry.Reset();
                until ItemAnalysisView.Next = 0;
            ItemAnalysisView.Reset();
        end;
    end;

    procedure LookUpDimFilter(Dim: Code[20]; var Text: Text): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal = ACTION::LookupOK then begin
            Text := DimValList.GetSelectionFilter;
            exit(true);
        end;
        exit(false)
    end;

    procedure LookupDimValue(DimCode: Code[20]; var DimValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
        DimValuesList: Page "Dimension Values";
    begin
        DimValue.SetRange("Dimension Code", DimCode);
        DimValuesList.LookupMode := true;
        DimValuesList.SetTableView(DimValue);
        if DimValue.Get(DimCode, DimValueCode) then
            DimValuesList.SetRecord(DimValue);
        if DimValuesList.RunModal = ACTION::LookupOK then begin
            DimValuesList.GetRecord(DimValue);
            DimValueCode := DimValue.Code;
        end;
    end;

    local procedure GetGlobalDimensionNo(): Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        case "Dimension Code" of
            GeneralLedgerSetup."Global Dimension 1 Code":
                exit(1);
            GeneralLedgerSetup."Global Dimension 2 Code":
                exit(2);
            GeneralLedgerSetup."Shortcut Dimension 3 Code":
                exit(3);
            GeneralLedgerSetup."Shortcut Dimension 4 Code":
                exit(4);
            GeneralLedgerSetup."Shortcut Dimension 5 Code":
                exit(5);
            GeneralLedgerSetup."Shortcut Dimension 6 Code":
                exit(6);
            GeneralLedgerSetup."Shortcut Dimension 7 Code":
                exit(7);
            GeneralLedgerSetup."Shortcut Dimension 8 Code":
                exit(8);
            else
                exit(0);
        end;
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure UpdateMapToICDimensionCode()
    var
        Dimension: Record Dimension;
    begin
        Dimension.Get("Dimension Code");
        Validate("Map-to IC Dimension Code", Dimension."Map-to IC Dimension Code");
    end;
}

